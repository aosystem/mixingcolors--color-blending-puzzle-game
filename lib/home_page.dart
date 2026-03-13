import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mixingcolors/ad_banner_widget.dart';
import 'package:mixingcolors/ad_manager.dart';
import 'package:mixingcolors/l10n/app_localizations.dart';
import 'package:mixingcolors/parse_locale_tag.dart';
import 'package:mixingcolors/setting_page.dart';
import 'package:mixingcolors/theme_color.dart';
import 'package:mixingcolors/theme_mode_number.dart';
import 'package:mixingcolors/loading_screen.dart';
import 'package:mixingcolors/main.dart';
import 'package:mixingcolors/model.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  static const int _gameLevelStep = 6;
  static const List<Cmy> _variations = [
    Cmy(1, 0, 0),
    Cmy(0, 1, 0),
    Cmy(0, 0, 1),
    Cmy(1, 0.7, 0),
    Cmy(1, 0, 0.7),
    Cmy(1, 0.7, 0.7),
    Cmy(0.5, 1, 0),
    Cmy(0, 1, 0.7),
    Cmy(0.7, 1, 0.7),
    Cmy(0.7, 0, 1),
    Cmy(0, 0.7, 1),
    Cmy(0.7, 0.7, 1),
  ];
  final Random _random = Random();
  late List<Cmy> _paints;
  late List<Color> _paintColors;
  late List<int> _answer;
  List<int> _counts = List<int>.filled(6, 0);
  List<bool> _slotUnlocked = List<bool>.filled(6, false);
  Color _targetColor = Colors.white;
  Color _mixColor = Colors.white;
  bool _resetEnabled = false;
  bool _nextVisible = false;
  bool _resumeVisible = false;
  bool _giveUpVisible = false;
  bool _inputEnabled = true;
  bool _showAnswer = false;
  int _resetCount = 0;
  late ui.Image _stageMixMask;
  late ui.Image _paintMask;
  //
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  void _initState() async {
    _adManager = AdManager();
    _stageMixMask = await _loadMaskImage('assets/image/stage_mix.png');
    _paintMask = await _loadMaskImage('assets/image/paint_color.png');
    _newGame();
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void _newGame() {
    final stage = _buildStageData(Model.gameLevel);
    _paints = stage.paints;
    _paintColors = stage.rgb;
    _answer = stage.answer;
    _counts = List<int>.filled(6, 0);
    _slotUnlocked = stage.unlocked;
    _targetColor = stage.targetColor;
    _mixColor = _calculateMixColor(_counts, _paints);
    _resetEnabled = false;
    _nextVisible = false;
    _resumeVisible = false;
    _giveUpVisible = false;
    _inputEnabled = true;
    _showAnswer = false;
    _resetCount = 0;
  }

  Future<ui.Image> _loadMaskImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  StageData _buildStageData(int level) {
    final unlocked = List<bool>.generate(6, (index) {
      if (index < 2) {
        return true;
      }
      return (level ~/ _gameLevelStep) > (index - 2);
    });
    final order = List<int>.generate(_variations.length, (index) => index)
      ..shuffle(_random);
    final paints = List<Cmy>.generate(6, (index) => _variations[order[index]]);
    final answer = List<int>.filled(6, 0);
    final maxAmount = (level % _gameLevelStep) + 1;
    for (var i = 0; i < unlocked.length; i++) {
      if (!unlocked[i]) {
        continue;
      }
      answer[i] = _random.nextInt(maxAmount) + 1;
    }
    _slimAnswer(answer);
    final targetColor = _calculateMixColor(answer, paints);
    return StageData(
      paints: paints,
      answer: answer,
      targetColor: targetColor,
      unlocked: unlocked,
    );
  }

  void _slimAnswer(List<int> answer) {
    for (var divisor = 7; divisor >= 2; divisor--) {
      final divisible = answer.every(
        (value) => value == 0 || value % divisor == 0,
      );
      if (divisible) {
        for (var i = 0; i < answer.length; i++) {
          if (answer[i] != 0) {
            answer[i] = answer[i] ~/ divisor;
          }
        }
      }
    }
  }

  void _onPaintTap(int index) {
    if (!_inputEnabled || !_slotUnlocked[index]) {
      return;
    }
    final updatedCounts = List<int>.from(_counts);
    updatedCounts[index] += 1;
    final mixColor = _calculateMixColor(updatedCounts, _paints);
    final solved = _isSolved(updatedCounts, _answer);
    setState(() {
      _counts = updatedCounts;
      _mixColor = mixColor;
      _resetEnabled = true;
      _nextVisible = solved;
    });
  }

  void _onReset() {
    if (!_resetEnabled || !_inputEnabled) {
      return;
    }
    final cleared = List<int>.filled(6, 0);
    setState(() {
      _counts = cleared;
      _mixColor = _calculateMixColor(cleared, _paints);
      _resetEnabled = false;
      _nextVisible = false;
      _resetCount += 1;
      if (_resetCount > 2) {
        _giveUpVisible = true;
      }
    });
  }

  Future<void> _onGiveUp() async {
    if (!_giveUpVisible || !_inputEnabled) {
      return;
    }
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.giveUpDialogTitle),
        content: Text(l.giveUpDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.ok),
          ),
        ],
      ),
    ) ?? false;
    if (!confirmed) {
      setState(() => _giveUpVisible = true);
      return;
    }
    final answerCopy = List<int>.from(_answer);
    setState(() {
      _counts = answerCopy;
      _mixColor = _calculateMixColor(answerCopy, _paints);
      _showAnswer = true;
      _resetEnabled = false;
      _nextVisible = false;
      _giveUpVisible = false;
      _resumeVisible = true;
      _inputEnabled = false;
    });
  }

  void _onResume() {
    if (!_resumeVisible) {
      return;
    }
    _newGame();
    setState(() {});
  }

  void _onNext() {
    if (!_nextVisible) {
      return;
    }
    Model.setGameLevel(Model.gameLevel + 1);
    _newGame();
    setState(() {});
  }

  bool _isSolved(List<int> counts, List<int> answer) {
    if (answer[0] == 0) {
      return false;
    }
    if (counts[0] == 0 || counts[0] % answer[0] != 0) {
      return false;
    }
    final multiplier = counts[0] ~/ answer[0];
    for (var i = 1; i < counts.length; i++) {
      if (answer[i] == 0) {
        if (counts[i] != 0) {
          return false;
        }
        continue;
      }
      if (counts[i] == 0 || counts[i] % answer[i] != 0) {
        return false;
      }
      if (counts[i] ~/ answer[i] != multiplier) {
        return false;
      }
    }
    return true;
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const SettingPage()),
    );
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        body: LoadingScreen(),
      );
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context)!;
    final levelLabel = l.levelLabel(Model.gameLevel + 1);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: _themeColor.mainBackColor,
      body: Stack(children:[
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_themeColor.mainBack2Color, _themeColor.mainBackColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            image: DecorationImage(
              image: AssetImage('assets/image/tile.png'),
              repeat: ImageRepeat.repeat,
              opacity: 0.1,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Stack(
                  children: [
                    Center(
                      child: Text(levelLabel, style: t.titleMedium?.copyWith(color: _themeColor.mainForeColor)),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: _openSettings,
                          tooltip: l.setting,
                          icon: const Icon(Icons.settings),
                        ),
                      ),
                    ),
                  ],
                )
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    children: [
                      _buildStageCard(l),
                      const SizedBox(height: 24),
                      _buildPaintGrid(l),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
      ]),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildStageCard(AppLocalizations loc) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      color: _targetColor,
      elevation: 0,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (Rect bounds) {
                        final scaleX = bounds.width / _stageMixMask.width;
                        final scaleY = bounds.height / _stageMixMask.height;
                        return ImageShader(
                          _stageMixMask,
                          TileMode.clamp,
                          TileMode.clamp,
                          Matrix4.diagonal3Values(scaleX, scaleY, 1.0).storage,
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: Container(
                        color: _mixColor,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Image.asset('assets/image/stage_brush.png', fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 34,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedOpacity(
                          opacity: _giveUpVisible && _inputEnabled ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: FilledButton(
                            onPressed: _giveUpVisible && _inputEnabled
                                ? _onGiveUp
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _themeColor.mainButtonBackColor,
                              foregroundColor: _themeColor.mainButtonForeColor,
                            ),
                            child: Text(loc.giveUp),
                          ),
                        ),
                        FilledButton(
                          onPressed: _resetEnabled && _inputEnabled
                              ? _onReset
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _themeColor.mainButtonBackColor,
                            foregroundColor: _themeColor.mainButtonForeColor,
                          ),
                          child: Text(loc.reset),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _resumeVisible ? 1 : 0,
                          child: FilledButton.tonal(
                            onPressed: _resumeVisible ? _onResume : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _themeColor.mainButtonBackColor,
                              foregroundColor: _themeColor.mainButtonForeColor,
                            ),
                            child: Text(loc.resume),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _nextVisible ? 1 : 0,
                          child: FilledButton(
                            onPressed: _nextVisible ? _onNext : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: _themeColor.mainButtonBackColor,
                              foregroundColor: _themeColor.mainButtonForeColor,
                            ),
                            child: Text(loc.niceJobNext),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPaintGrid(AppLocalizations loc) {
    final textStyle = Theme.of(context).textTheme.titleLarge;
    final baseTextColor = textStyle?.color;
    final rows = <Widget>[];
    for (var row = 0; row < 2; row++) {
      final indices = List<int>.generate(3, (index) => row * 3 + index);
      rows
        ..add(
          Row(
            children: indices
              .map(
                (index) => Expanded(
                  child: AnimatedOpacity(
                    opacity: _slotUnlocked[index] ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${_counts[index]}',
                        textAlign: TextAlign.center,
                        style: textStyle?.copyWith(
                          color: _showAnswer
                            ? Theme.of(context).colorScheme.error
                            : baseTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
          ),
        )
        ..add(
          Row(
            children: indices
              .map(
                (index) => Expanded(
                  child: _PaintSlot(
                    color: _paintColors[index],
                    paintMask: _paintMask,
                    enabled: _slotUnlocked[index] && (_inputEnabled || _showAnswer),
                    onTap: () => _onPaintTap(index),
                  ),
                ),
              )
              .toList(),
          ),
        );
    }
    return Column(children: rows);
  }

  Color _calculateMixColor(List<int> counts, List<Cmy> paints) {
    double c = 0;
    double m = 0;
    double y = 0;
    for (var i = 0; i < counts.length; i++) {
      final factor = counts[i];
      c += paints[i].c * factor;
      m += paints[i].m * factor;
      y += paints[i].y * factor;
    }
    final maxValue = max(c, max(m, y));
    if (maxValue > 1) {
      c /= maxValue;
      m /= maxValue;
      y /= maxValue;
    }
    return _cmyToColor(c, m, y);
  }
}

Color _cmyToColor(double c, double m, double y) {
  final r = ((1 - c).clamp(0.0, 1.0) * 255).round();
  final g = ((1 - m).clamp(0.0, 1.0) * 255).round();
  final b = ((1 - y).clamp(0.0, 1.0) * 255).round();
  return Color.fromARGB(255, r, g, b);
}

class StageData {
  StageData({
    required this.paints,
    required this.answer,
    required this.targetColor,
    required this.unlocked,
  }) : rgb = paints.map((cmy) => _cmyToColor(cmy.c, cmy.m, cmy.y)).toList();

  final List<Cmy> paints;
  final List<int> answer;
  final Color targetColor;
  final List<bool> unlocked;
  final List<Color> rgb;
}

class Cmy {
  const Cmy(this.c, this.m, this.y);

  final double c;
  final double m;
  final double y;
}

class _PaintSlot extends StatelessWidget {
  const _PaintSlot({
    required this.color,
    required this.paintMask,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final ui.Image paintMask;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AspectRatio(
            aspectRatio: 258 / 188,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset('assets/image/paint_tray.png', fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      final scaleX = bounds.width / paintMask.width;
                      final scaleY = bounds.height / paintMask.height;
                      return ImageShader(
                        paintMask,
                        TileMode.clamp,
                        TileMode.clamp,
                        Matrix4.diagonal3Values(scaleX, scaleY, 1.0).storage,
                      );
                    },
                    blendMode: BlendMode.dstIn,
                    child: Container(
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
