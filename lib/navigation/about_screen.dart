import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import '../services/data_collection_service.dart';
import 'dart:io';
import 'package:otzaria/i18n/translations.g.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? appVersion;
  String? libraryVersion;
  int? bookCount;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Widget _buildContributor(String name, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildDevelopersList() {
    final developers = [
      {
        'name': 'sivan22',
        'url': 'https://github.com/Sivan22',
        'description': context.t.about.creator // Old: 'יוצר התוכנה'
      },
      {'name': 'Y.PL.', 'url': 'https://github.com/Y-PLONI'},
      {'name': 'YOSEFTT', 'url': 'https://github.com/YOSEFTT'},
      {'name': 'zevisvei', 'url': 'https://github.com/zevisvei'},
      {
        'name': 'NHLOCAL',
        'url': 'https://github.com/NHLOCAL/Shamor-Zachor',
        'description':
            context.t.about.developedShamorZachor // Old: 'פיתוח "זכור ושמור"'
      },
      {
        'name': 'evel-avalim',
        'url': 'https://github.com/evel-avalim',
        'description':
            context.t.about.developedGematria // Old: 'פיתוח הגימטריות'
      },
      {
        'name': 'userbot',
        'url': 'https://github.com/userbot000',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // במסכים קטנים, הצג בעמודה
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: developers
                .map((dev) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(FluentIcons.person_24_regular,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContributor(dev['name']!, dev['url']!),
                                if (dev['description'] != null)
                                  Text(
                                    '(${dev['description']})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          );
        }
        // במסכים רחבים, השתמש ב-Wrap
        return Wrap(
          spacing: 40,
          runSpacing: 12,
          children: developers
              .map((dev) => SizedBox(
                    width: 220,
                    child: Row(
                      children: [
                        const Icon(FluentIcons.person_24_regular,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContributor(dev['name']!, dev['url']!),
                              if (dev['description'] != null)
                                Text(
                                  '(${dev['description']})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTechnicalDetails() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // במסכים קטנים, הצג בעמודה
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCompactInfoItem(
                  context.t.about.appVersion,
                  appVersion ??
                      context.t.about.unknown), // Old: 'גרסת תוכנה', 'לא ידוע'
              const SizedBox(height: 8),
              _buildCompactInfoItem(
                  context.t.about.libraryVersion,
                  libraryVersion ??
                      context.t.about.unknown), // Old: 'גרסת ספרייה', 'לא ידוע'
              const SizedBox(height: 8),
              _buildCompactInfoItem(context.t.about.bookCount,
                  '${bookCount ?? context.t.about.unknown}'), // Old: 'מספר ספרים', 'לא ידוע'
            ],
          );
        }
        // במסכים רחבים, השתמש ב-Wrap
        return Wrap(
          spacing: 30,
          runSpacing: 8,
          children: [
            _buildCompactInfoItem(
                context.t.about.appVersion,
                appVersion ??
                    context.t.about.unknown), // Old: 'גרסת תוכנה', 'לא ידוע'
            _buildCompactInfoItem(
                context.t.about.libraryVersion,
                libraryVersion ??
                    context.t.about.unknown), // Old: 'גרסת ספרייה', 'לא ידוע'
            _buildCompactInfoItem(context.t.about.bookCount,
                '${bookCount ?? context.t.about.unknown}'), // Old: 'מספר ספרים', 'לא ידוע'
          ],
        );
      },
    );
  }

  Widget _buildCompactInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMemorialCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // אם הרוחב קטן מ-700, הצג בעמודה
        if (constraints.maxWidth < 700) {
          return _buildMemorialCardsColumn();
        }
        // אחרת, הצג בשורה
        return Row(
          children: [
            Expanded(
              child: _buildMemorialCard(
                context.t.about
                    .memorialCandle, // Old: 'לע"נ ר\' משה בן יהודה ראה ז"ל'
                context.t.about
                    .significantContribution, // Old: 'סכום משמעותי לפיתוח התוכנה'
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDonationMemorialCard(
                context.t.about
                    .memorialSpot, // Old: 'מקום זה יכול להיות מונצח לע"נ יקירך'
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDonationMemorialCard(
                context.t.about
                    .memorialSpot, // Old: 'מקום זה יכול להיות מונצח לע"נ יקירך'
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String description,
    required String buttonText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showGitHubIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
              icon: Icon(icon, size: 18),
              label: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialCard(String name, String description) {
    return SizedBox(
      height: 140, // גודל קבוע לכל הכארדים
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icon/memorial_candle.svg',
                    width: 20,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Colors.orange[700]!,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationMemorialCard(String name) {
    return SizedBox(
      height: 140, // גודל קבוע לכל הכארדים
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => _openLocalHtmlFile('donate.html'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icon/memorial_candle.svg',
                      width: 20,
                      height: 20,
                      colorFilter: ColorFilter.mode(
                        Colors.orange[700]!,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  context.t.about.clickHere, // Old: 'לחץ כאן'
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadVersions() async {
    // Load app version
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    // Load library version from file
    await _loadLibraryVersion();

    setState(() {});
  }

  Future<void> _loadLibraryVersion() async {
    final dataService = DataCollectionService();
    libraryVersion = await dataService.readLibraryVersion();
    if (libraryVersion == 'unknown') {
      libraryVersion = context.t.about.unknown;
    }

    // Load book count
    bookCount = await dataService.getTotalBookCount();
  }

  Future<String?> _getOtzariaSitePath() async {
    final libraryPath = Settings.getValue('key-library-path');
    if (libraryPath == null || libraryPath.isEmpty) return null;

    // התיקייה otzaria-site נמצאת באותה תיקייה שבה נמצא "גירסת ספריה.txt"
    final otzariaSitePath = Directory(
        '$libraryPath${Platform.pathSeparator}אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}otzaria-site');
    if (await otzariaSitePath.exists()) {
      return otzariaSitePath.path;
    }
    return null;
  }

  Future<void> _openLocalHtmlFile(String fileName) async {
    final sitePath = await _getOtzariaSitePath();
    if (sitePath == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.t.about
                .otzariaSiteNotFound)), // Old: 'לא נמצאה תיקיית otzaria-site'
      );
      return;
    }

    final htmlFile = File('$sitePath/$fileName');
    if (!await htmlFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.t.about.fileNotFound(
                file: fileName))), // Old: 'הקובץ $fileName לא נמצא'
      );
      return;
    }

    final uri = Uri.file(htmlFile.path);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showChangelogDialog(BuildContext context) async {
    final changelog = await rootBundle.loadString('assets/יומן שינויים.md');

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(context.t.about.changelog), // Old: 'יומן שינויים'
          content: SizedBox(
            width: 600,
            height: 400,
            child: Markdown(
              data: changelog,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.t.common.close), // Old: 'סגור'
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[600]!.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[600]!.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism_outlined,
                  color: Colors.grey[600]!, size: 24),
              const SizedBox(width: 8),
              Text(
                context.t.about.donate, // Old: 'תרום לפרויקט'
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]!,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.t.about
                .donateDesc, // Old: 'תרומתך תעזור לנו להמשיך לפתח ולשפר את אוצריא עבור כלל הציבור.'
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          // שורה עם שני כפתורים אחד לצד השני
          LayoutBuilder(
            builder: (context, constraints) {
              // במסכים קטנים מאוד, הצג בעמודה
              if (constraints.maxWidth < 300) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        const url = 'https://nedar.im/ejco';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Image.asset(
                        'assets/icon/logo_nedarim.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(FluentIcons.payment_24_regular,
                                size: 18),
                      ),
                      label: Text(context.t.about.nedarimPlus,
                          style:
                              const TextStyle(fontSize: 12)), // Old: 'נדרים+'
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _openLocalHtmlFile('donate.html'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon:
                          const Icon(FluentIcons.payment_24_regular, size: 18),
                      label: Text(context.t.about.other,
                          style: const TextStyle(fontSize: 12)), // Old: 'אחר'
                    ),
                  ],
                );
              }
              // במסכים רגילים, הצג בשורה
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        const url = 'https://nedar.im/ejco';
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: Image.asset(
                        'assets/icon/logo_nedarim.png',
                        width: 18,
                        height: 18,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(FluentIcons.payment_24_regular,
                                size: 18),
                      ),
                      label: Text(context.t.about.nedarimPlus,
                          style:
                              const TextStyle(fontSize: 12)), // Old: 'נדרים+'
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openLocalHtmlFile('donate.html'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon:
                          const Icon(FluentIcons.payment_24_regular, size: 18),
                      label: Text(context.t.about.other,
                          style: const TextStyle(fontSize: 12)), // Old: 'אחר'
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 900;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: isSmallScreen
          ? _buildSmallScreenLayout(context)
          : _buildWideScreenLayout(context),
    );
  }

  Widget _buildWideScreenLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // תוכן ראשי - מצד ימין
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // סמל וכותרת משנה
                Row(
                  children: [
                    Image.asset(
                      'assets/icon/icon.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t.about.appName,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          context.t.about.subtitle,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // תיאור התוכנה
                Text(
                  context.t.about.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // כארדים תורמים
                Text(
                  context.t.about.donors,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMemorialCardsRow(),
                const SizedBox(height: 32),

                // רשימת מפתחים
                Text(
                  context.t.about.developers,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDevelopersList(),
                const SizedBox(height: 32),

                // פרטים טכניים
                Text(
                  context.t.about.technicalDetails,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTechnicalDetails(),
                const SizedBox(height: 16),

                // כפתור יומן שינויים
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangelogDialog(context),
                    icon: const Icon(FluentIcons.history_24_regular),
                    label:
                        Text(context.t.about.changelog), // Old: 'יומן שינויים'
                  ),
                ),
              ],
            ),
          ),
        ),

        // כארד צדדי - מצד שמאל
        SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionCard(
                      title: context.t.about.joinDevelopment,
                      description: context.t.about.joinDevelopmentDesc,
                      buttonText: context.t.about.joinNow,
                      icon: FluentIcons.code_24_regular,
                      color: Colors.grey[600]!,
                      showGitHubIcon: true,
                      onTap: () =>
                          _openLocalHtmlFile('tutorial-development.html'),
                    ),
                    const SizedBox(height: 20),
                    _buildActionCard(
                      title: context.t.about.joinEditing,
                      description: context.t.about.joinEditingDesc,
                      buttonText: context.t.about.joinEditingButton,
                      icon: FluentIcons.edit_24_regular,
                      color: Colors.grey[600]!,
                      onTap: () => _openLocalHtmlFile('tutorial-dicta.html'),
                    ),
                    const SizedBox(height: 20),
                    _buildDonationCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallScreenLayout(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // סמל וכותרת
          _buildHeader(),
          const SizedBox(height: 16),

          // תיאור
          Text(
            context.t.about.description,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),

          // כארדים של פעולות (למעלה במסכים קטנים)
          _buildActionCard(
            title: context.t.about.joinDevelopment,
            description: context.t.about.joinDevelopmentDesc,
            buttonText: context.t.about.joinNow,
            icon: FluentIcons.code_24_regular,
            color: Colors.grey[600]!,
            showGitHubIcon: true,
            onTap: () => _openLocalHtmlFile('tutorial-development.html'),
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            title: context.t.about.joinEditing,
            description: context.t.about.joinEditingDesc,
            buttonText: context.t.about.joinEditingButton,
            icon: FluentIcons.edit_24_regular,
            color: Colors.grey[600]!,
            onTap: () => _openLocalHtmlFile('tutorial-dicta.html'),
          ),
          const SizedBox(height: 16),
          _buildDonationCard(),
          const SizedBox(height: 24),

          // תורמים
          Text(
            context.t.about.donors,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMemorialCardsColumn(),
          const SizedBox(height: 24),

          // מפתחים
          Text(
            context.t.about.developers,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildDevelopersList(),
          const SizedBox(height: 24),

          // פרטים טכניים
          Text(
            context.t.about.technicalDetails,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildTechnicalDetails(),
          const SizedBox(height: 16),

          // כפתור יומן שינויים
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showChangelogDialog(context),
              icon: const Icon(FluentIcons.history_24_regular),
              label: Text(context.t.about.changelog), // Old: 'יומן שינויים'
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isVerySmall = constraints.maxWidth < 400;
        return Row(
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: isVerySmall ? 50 : 60,
              height: isVerySmall ? 50 : 60,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.about.appName,
                    style: TextStyle(
                      fontSize: isVerySmall ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    context.t.about.subtitle,
                    style: TextStyle(
                      fontSize: isVerySmall ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemorialCardsColumn() {
    return Column(
      children: [
        _buildMemorialCard(
          context.t.about.memorialCandle,
          context.t.about.significantContribution,
        ),
        const SizedBox(height: 12),
        _buildDonationMemorialCard(
          context.t.about.memorialSpot,
        ),
        const SizedBox(height: 12),
        _buildDonationMemorialCard(
          context.t.about.memorialSpot,
        ),
      ],
    );
  }
}
