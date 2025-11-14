import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import '../models/phone_report_data.dart';
import '../widgets/reporting_numbers_widget.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// Tab widget for phone-based error reporting
class PhoneReportTab extends StatefulWidget {
  final String visibleText;
  final double fontSize;
  final String libraryVersion;
  final int? bookId;
  final int lineNumber;
  final String? initialSelectedText;
  final Function(
          String selectedText, int errorId, String moreInfo, int lineNumber)?
      onSubmit;
  final VoidCallback? onCancel;

  const PhoneReportTab({
    super.key,
    required this.visibleText,
    required this.fontSize,
    required this.libraryVersion,
    required this.bookId,
    required this.lineNumber,
    this.initialSelectedText,
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<PhoneReportTab> createState() => _PhoneReportTabState();
}

class _PhoneReportTabState extends State<PhoneReportTab> {
  String? _selectedText;
  ErrorType? _selectedErrorType;

  late int _updatedLineNumber;
  int? _selectionStart;
  int? _selectionEnd;

  @override
  void initState() {
    super.initState();
    _selectedText = widget.initialSelectedText;
    // אתחול מספר השורה עם הערך ההתחלתי שקיבלנו
    _updatedLineNumber = widget.lineNumber;
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> _validationErrors(BuildContext context) {
    final errors = <String>[];

    if (_selectedText == null || _selectedText!.isEmpty) {
      errors.add(context.t.report.mustSelectText);
    }

    if (_selectedErrorType == null) {
      errors.add(context.t.report.mustSelectErrorType);
    }

    if (widget.bookId == null) {
      errors.add(context.t.report.cannotFindBook);
    }

    if (widget.libraryVersion == 'unknown') {
      errors.add(context.t.report.cannotReadLibraryVersion);
    }

    return errors;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInstructions(context),
          const SizedBox(height: 16),
          _buildTextSelection(context),
          const SizedBox(height: 16),
          _buildErrorTypeSelection(context),
          const SizedBox(height: 16),
          _buildReportingNumbers(context),
          const SizedBox(height: 16),
          _buildValidationErrors(context),
          const SizedBox(height: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t.report.phoneReportInstructions,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              context.t.report.phoneReportSteps,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.report.selectTextWithError,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // הוספת מסגרת
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Builder(
              builder: (context) => TextSelectionTheme(
                data: const TextSelectionThemeData(
                  selectionColor: Colors.transparent,
                ),
                child: SelectableText.rich(
                  TextSpan(
                    children: () {
                      final text = widget.visibleText;
                      final start = _selectionStart ?? -1;
                      final end = _selectionEnd ?? -1;
                      final hasSel =
                          start >= 0 && end > start && end <= text.length;
                      if (!hasSel) {
                        return [TextSpan(text: text)];
                      }
                      final highlight = Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.25);
                      return [
                        if (start > 0) TextSpan(text: text.substring(0, start)),
                        TextSpan(
                          text: text.substring(start, end),
                          style: TextStyle(backgroundColor: highlight),
                        ),
                        if (end < text.length)
                          TextSpan(text: text.substring(end)),
                      ];
                    }(),
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontFamily:
                          Settings.getValue('key-font-family') ?? 'candara',
                    ),
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  onSelectionChanged: (selection, cause) {
                    if (selection.start != selection.end) {
                      final selectedText = widget.visibleText.substring(
                        selection.start,
                        selection.end,
                      );

                      // חישוב מספר השורה על בסיס הטקסט הנבחר
                      final textBeforeSelection =
                          widget.visibleText.substring(0, selection.start);
                      final lineOffset =
                          '\n'.allMatches(textBeforeSelection).length;
                      final newLineNumber = widget.lineNumber + lineOffset;

                      if (selectedText.isNotEmpty) {
                        setState(() {
                          _selectedText = selectedText;
                          _selectionStart = selection.start;
                          _selectionEnd = selection.end;
                          _updatedLineNumber = newLineNumber;
                        });
                      }
                    }
                  },
                  contextMenuBuilder: (context, editableTextState) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
        if (_selectedText != null && _selectedText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.report.selectedText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedText!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorTypeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t.report.selectErrorType,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ErrorType>(
          initialValue: _selectedErrorType,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: context.t.report.selectErrorTypeHint,
          ),
          isExpanded: true,
          items: ErrorType.errorTypes.map((errorType) {
            return DropdownMenuItem<ErrorType>(
              value: errorType,
              child: Text(
                errorType.hebrewLabel,
                textDirection: TextDirection.rtl,
              ),
            );
          }).toList(),
          onChanged: (_selectedText != null && _selectedText!.isNotEmpty)
              ? (ErrorType? value) {
                  setState(() {
                    _selectedErrorType = value;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildReportingNumbers(BuildContext context) {
    return ReportingNumbersWidget(
      libraryVersion: widget.libraryVersion,
      bookId: widget.bookId,
      // השתמש במספר השורה המעודכן מה-state
      lineNumber: _updatedLineNumber,
      errorId: _selectedErrorType?.id,
    );
  }

  Widget _buildValidationErrors(BuildContext context) {
    final errors = _validationErrors(context);
    if (errors.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  FluentIcons.error_circle_24_regular,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.t.report.mustFixErrors,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          error,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(context.t.common.cancel),
        ),
      ],
    );
  }
}
