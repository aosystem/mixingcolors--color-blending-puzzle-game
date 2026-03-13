import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:mixingcolors/ad_banner_widget.dart';
import 'package:mixingcolors/ad_manager.dart';
import 'package:mixingcolors/ad_ump_status.dart';
import 'package:mixingcolors/l10n/app_localizations.dart';
import 'package:mixingcolors/model.dart';
import 'package:mixingcolors/theme_color.dart';
import 'package:mixingcolors/loading_screen.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  late UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;
  int _themeNumber = 0;
  String _languageCode = '';
  late ThemeColor _themeColor;
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  //
  bool _resetLevel = false;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _adManager = AdManager();
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  Future<void> _onApply() async {
    FocusScope.of(context).unfocus();
    if (_resetLevel) {
      await Model.setGameLevel(0);
    }
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
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
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.setting),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _onApply,
            icon: const Icon(Icons.check),
            tooltip: l.apply,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 100),
          children: [
            _buildReset(l),
            _buildTheme(l),
            _buildLanguage(l),
            _buildReview(l),
            _buildCmp(l),
            _buildUsage(l),
          ],
        ),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager)
    );
  }

  Widget _buildReset(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: SwitchListTile.adaptive(
        title: Text(l.resetLevel, style: t.bodyMedium),
        subtitle: Text(l.resetLevelDescription, style: t.bodySmall),
        value: _resetLevel,
        onChanged: (value) => setState(() => _resetLevel = value),
      ),
    );
  }

  Widget _buildTheme(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(l.theme),
            ),
            DropdownButton<int>(
              value: _themeNumber,
              items: [
                DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
                DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
                DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _themeNumber = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(l.language),
            ),
            DropdownButton<String?>(
              value: _languageCode,
              items: [
                DropdownMenuItem(value: '', child: Text('Default')),
                ...languageNames.entries.map((entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _languageCode = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmp(AppLocalizations l) {
    String statusLabel;
    IconData statusIcon;
    final showButton = _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    statusLabel = l.cmpCheckingRegion;
    statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.cmpSettingsTitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(l.cmpConsentDescription, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 4),
                  Text('${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (showButton)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _adUmpState.isChecking ? null : _onTapPrivacyOptions,
                          icon: const Icon(Icons.settings),
                          label: Text(_adUmpState.isChecking ? l.cmpConsentStatusChecking : l.cmpOpenConsentSettings),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            side: BorderSide(
                              width: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _adUmpState.isChecking ? null : _refreshConsentInfo,
                          icon: const Icon(Icons.refresh),
                          label: Text(l.cmpRefreshStatus),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await ConsentInformation.instance.reset();
                            await _refreshConsentInfo();
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(l.cmpResetStatusDone)));
                            }
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(l.cmpResetStatus),
                        ),
                      ]
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsage(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.usage1, style: t.bodySmall),
              const SizedBox(height: 12),
              Text(l.usage2, style: t.bodySmall),
            ],
          ),
        ),
      )
    );
  }

}
