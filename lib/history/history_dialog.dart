import 'package:flutter/material.dart';
import 'package:otzaria/history/history_screen.dart';
import 'package:otzaria/widgets/reusable_items_dialog.dart';
import 'package:otzaria/i18n/translations.g.dart';

class HistoryDialog extends StatelessWidget {
  const HistoryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableItemsDialog(
      title: context.t.history.title,
      child: const HistoryView(),
    );
  }
}
