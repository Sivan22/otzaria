//
// Simple password dialog
//
import 'package:flutter/material.dart';
import 'package:otzaria/i18n/translations.g.dart';

Future<String?> passwordDialog(BuildContext context) async {
  final textController = TextEditingController();
  return await showDialog<String?>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: Text(context.t.password.enterPassword),
        content: TextField(
          controller: textController,
          autofocus: true,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(context.t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(context.t.common.confirm),
          ),
        ],
      );
    },
  );
}
