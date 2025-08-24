import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget that displays reporting numbers with copy functionality
class ReportingNumbersWidget extends StatelessWidget {
  final String libraryVersion;
  final int? bookId;
  final int lineNumber;
  final int? errorId;
  final bool showPhoneNumber;

  const ReportingNumbersWidget({
    super.key,
    required this.libraryVersion,
    required this.bookId,
    required this.lineNumber,
    this.errorId,
    this.showPhoneNumber = true,
  });

  static const String _phoneNumber = '077-4636-198';

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'מספרי הדיווח:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 12),

            // IntrinsicHeight חיוני כדי שה-VerticalDivider יידע מה הגובה שלו
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // טור ימין
                  Expanded(
                    child: Column(
                      children: [
                        _buildNumberRow(
                          context,
                          'מספר גירסה',
                          libraryVersion,
                        ),
                        const SizedBox(height: 8),
                        _buildNumberRow(
                          context,
                          'מספר ספר',
                          bookId?.toString() ?? 'לא זמין',
                          enabled: bookId != null,
                        ),
                      ],
                    ),
                  ),

                  // קו מפריד אנכי בין הטורים
                  const VerticalDivider(
                    width: 20, // הרוחב הכולל שהמפריד תופס
                    thickness: 1, // עובי הקו
                    indent: 5, // ריפוד עליון
                    endIndent: 5, // ריפוד תחתון
                    color: Colors.grey, // צבע הקו (אופציונלי)
                  ),

                  // טור שמאל
                  Expanded(
                    child: Column(
                      children: [
                        _buildNumberRow(
                          context,
                          'מספר שורה',
                          lineNumber.toString(),
                        ),
                        const SizedBox(height: 8),
                        _buildNumberRow(
                          context,
                          'מספר שגיאה',
                          errorId?.toString() ?? 'לא נבחר',
                          enabled: errorId != null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (showPhoneNumber) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildPhoneSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(
    BuildContext context,
    String label,
    String value, {
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: enabled ? null : Theme.of(context).disabledColor,
                ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: enabled ? () => _copyToClipboard(context, value) : null,
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'העתק',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildPhoneSection(BuildContext context) {
    final isMobile = Platform.isAndroid || Platform.isIOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 1. הכותרת שתוצג בצד ימין
            Text(
              'קו אוצריא:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textDirection: TextDirection.rtl,
            ),

            // 2. Spacer שתופס את כל המקום הפנוי ודוחף את שאר הווידג'טים שמאלה
            const Spacer(),

            // 3. מספר הטלפון (כבר לא צריך להיות בתוך Expanded)
            isMobile
                ? InkWell(
                    onTap: () => _makePhoneCall(context),
                    child: Text(
                      _phoneNumber,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                      textDirection: TextDirection.ltr,
                    ),
                  )
                : SelectableText(
                    _phoneNumber,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textDirection: TextDirection.ltr,
                  ),
            const SizedBox(width: 8),

            // 4. כפתור ההעתקה
            IconButton(
              onPressed: () => _copyToClipboard(context, _phoneNumber),
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'העתק מספר טלפון',
              visualDensity: VisualDensity.compact,
            ),

            // 5. כפתור החיוג (למובייל)
            if (isMobile) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _makePhoneCall(context),
                icon: const Icon(Icons.phone, size: 18),
                tooltip: 'התקשר',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // טקסט המשנה נשאר כמו שהיה
        Text(
          'לפירוט נוסף, השאר הקלטה ברורה!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'הועתק ללוח: $text',
              textDirection: TextDirection.rtl,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'שגיאה בהעתקה ללוח',
              textDirection: TextDirection.rtl,
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context) async {
    try {
      final phoneUri = Uri(scheme: 'tel', path: _phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'לא ניתן לפתוח את אפליקציית הטלפון',
                textDirection: TextDirection.rtl,
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'שגיאה בפתיחת אפליקציית הטלפון',
              textDirection: TextDirection.rtl,
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
