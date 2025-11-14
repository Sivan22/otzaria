import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import '../../models/books.dart';
import '../../utils/otzar_utils.dart';
import '../../core/scaffold_messenger.dart';
import 'package:otzaria/i18n/translations.g.dart';

class OtzarBookDialog extends StatelessWidget {
  final ExternalBook book;

  const OtzarBookDialog({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: FutureBuilder<(bool, bool)>(
          future: Future.wait([
            OtzarUtils.canLaunchLocally(),
            OtzarUtils.checkBookExistence(book.id)
          ]).then((results) => (results[0], results[1])),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final (canLaunchLocally, bookExists) =
                snapshot.data ?? (false, false);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogTheme.backgroundColor ??
                    Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      book.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(context, FluentIcons.document_text_24_regular,
                        'תיאור', book.heShortDesc ?? 'לא קיים'),
                    _buildInfoRow(context, FluentIcons.person_24_regular,
                        'מחבר', book.author ?? 'לא ידוע'),
                    _buildInfoRow(context, FluentIcons.location_24_regular,
                        'מקום הדפסה', book.pubPlace ?? 'לא ידוע'),
                    _buildInfoRow(context, FluentIcons.calendar_24_regular,
                        'שנת הדפסה', book.pubDate ?? 'לא ידוע'),
                    _buildInfoRow(context, FluentIcons.apps_24_regular,
                        'נושאים', book.topics),
                    const SizedBox(height: 24),
                    _buildButtons(context, canLaunchLocally, bookExists),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(
      BuildContext context, bool canLaunchLocally, bool bookExists) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        if (canLaunchLocally && bookExists)
          ElevatedButton.icon(
            icon: const Icon(FluentIcons.desktop_24_regular),
            label: Text(context.t.library.openLocally), // Old: 'פתח מקומית'
            onPressed: () {
              Navigator.of(context).pop();
              OtzarUtils.launchOtzarLocal(book.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ElevatedButton.icon(
          icon: const Icon(FluentIcons.open_24_regular),
          label: Text(context.t.library.openInWebsite), // Old: 'פתח באתר'
          onPressed: () async {
            final errorColor = Theme.of(context).colorScheme.error;
            Navigator.of(context).pop();
            if (await OtzarUtils.launchOtzarWeb(book.link)) {
              // Success
            } else {
              UiSnack.showError('לא ניתן לפתוח את הקישור בדפדפן',
                  backgroundColor: errorColor);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: Text(context.t.common.close), // Old: 'סגור'
        ),
      ],
    );
  }
}
