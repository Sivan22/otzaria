import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  _AboutScreenState createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? appVersion;
  String? libraryVersion;

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

  Future<void> _loadVersions() async {
    // Load app version
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = packageInfo.version;

    // Load library version from file
    await _loadLibraryVersion();

    setState(() {});
  }

  Future<void> _loadLibraryVersion() async {
    final libraryPath = Settings.getValue<String>('key-library-path');
    if (libraryPath == null) {
      libraryVersion = 'לא נמצא נתיב ספרייה';
      return;
    }
    final versionFile =
        File(p.join(libraryPath, 'אודות התוכנה', 'גירסת ספריה.txt'));
    if (await versionFile.exists()) {
      libraryVersion = await versionFile.readAsString();
      libraryVersion = libraryVersion?.trim();
    } else {
      libraryVersion = 'קובץ לא נמצא בנתיב: ${versionFile.path}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Upper part with icon and title
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icon/icon.png',
                width: 128,
                height: 128,
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'אוצריא ',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'מאגר תורני חינמי',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'תוכנה זו נוצרה והוקדשה על ידי: ',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  _buildContributor('siivan22', 'https://github.com/Sivan22'),
                  const Text(', '),
                  _buildContributor('Y.PL', 'https://github.com/Y-PLONI'),
                  const Text(', '),
                  _buildContributor('YOSEFTT', 'https://github.com/YOSEFTT'),
                  const Text(', '),
                  _buildContributor('zevisvei', 'https://github.com/zevisvei'),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.grey),
              const SizedBox(height: 16),
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                child: RichText(
                  textDirection: TextDirection.rtl,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(
                          text:
                              'סכום משמעותי לפיתוח התוכנה, נתרם לעילוי נשמת:\n\n'),
                      TextSpan(
                        text: 'ר\' ',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'משה',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' בן '),
                      TextSpan(
                        text: 'יהודה',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' ז"ל'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Lower part with versions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'גרסת תוכנה: ${appVersion ?? 'לא ידוע'}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'גרסת ספריה: ${libraryVersion ?? 'לא ידוע'}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
