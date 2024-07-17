import 'package:flutter/material.dart';
import '../models/books.dart';
import '../utils/otzar_utils.dart';

class OtzarBookDialog extends StatelessWidget {
  final OtzarBook book;

  const OtzarBookDialog({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 400),
        child: FutureBuilder<(bool, bool)>(
          future: Future.wait([
            OtzarUtils.canLaunchLocally(),
            OtzarUtils.checkBookExistence(book.otzarId)
          ]).then((results) => (results[0], results[1])),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final (canLaunchLocally, bookExists) =
                snapshot.data ?? (false, false);

            return Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
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
                    SizedBox(height: 24),
                    _buildInfoRow(context, Icons.person, 'מחבר',
                        book.author ?? 'לא ידוע'),
                    _buildInfoRow(context, Icons.location_on, 'מקום הדפסה',
                        book.printPlace ?? 'לא ידוע'),
                    _buildInfoRow(context, Icons.calendar_today, 'שנת הדפסה',
                        book.printYear ?? 'לא ידוע'),
                    _buildInfoRow(context, Icons.category, 'נושאים',
                        book.topics ?? 'לא ידוע'),
                    SizedBox(height: 24),
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
          SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
            icon: Icon(Icons.computer),
            label: Text('פתח מקומית'),
            onPressed: () {
              Navigator.of(context).pop();
              OtzarUtils.launchOtzarLocal(book.otzarId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ElevatedButton.icon(
          icon: Icon(Icons.open_in_new),
          label: Text('פתח באתר'),
          onPressed: () async {
            Navigator.of(context).pop();
            if (await OtzarUtils.launchOtzarWeb(book.link)) {
              // Success
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('לא ניתן לפתוח את הקישור בדפדפן'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        TextButton(
          child: Text('סגור'),
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
