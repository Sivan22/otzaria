import 'package:flutter/material.dart';

class SearchOptionsDropdown extends StatefulWidget {
  final Function(bool)? onToggle;
  final bool isExpanded;

  const SearchOptionsDropdown({
    super.key,
    this.onToggle,
    this.isExpanded = false,
  });

  @override
  State<SearchOptionsDropdown> createState() => _SearchOptionsDropdownState();
}

class _SearchOptionsDropdownState extends State<SearchOptionsDropdown> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(SearchOptionsDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      setState(() {
        _isExpanded = widget.isExpanded;
      });
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggle?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
      tooltip: 'אפשרויות חיפוש',
      onPressed: _toggleExpanded,
    );
  }
}

class SearchOptionsRow extends StatefulWidget {
  final bool isVisible;
  final String? currentWord; // המילה הנוכחית
  final int? wordIndex; // אינדקס המילה
  final Map<String, Map<String, bool>>? wordOptions; // אפשרויות מהטאב
  final VoidCallback? onOptionsChanged; // קולבק לעדכון

  const SearchOptionsRow({
    super.key,
    required this.isVisible,
    this.currentWord,
    this.wordIndex,
    this.wordOptions,
    this.onOptionsChanged,
  });

  @override
  State<SearchOptionsRow> createState() => _SearchOptionsRowState();
}

class _SearchOptionsRowState extends State<SearchOptionsRow> {
  // רשימת האפשרויות הזמינות
  static const List<String> _availableOptions = [
    'קידומות',
    'סיומות',
    'קידומות דקדוקיות',
    'סיומות דקדוקיות',
    'כתיב מלא/חסר',
    'חלק ממילה',
  ];

  Map<String, bool> _getCurrentWordOptions() {
    final currentWord = widget.currentWord;
    final wordIndex = widget.wordIndex;
    final wordOptions = widget.wordOptions;

    if (currentWord == null ||
        currentWord.isEmpty ||
        wordIndex == null ||
        wordOptions == null) {
      return Map.fromIterable(_availableOptions, value: (_) => false);
    }

    final key = '${currentWord}_$wordIndex';

    // אם אין אפשרויות למילה הזו, ניצור אותן
    if (!wordOptions.containsKey(key)) {
      wordOptions[key] =
          Map.fromIterable(_availableOptions, value: (_) => false);
    }

    return wordOptions[key]!;
  }

  Widget _buildCheckbox(String option) {
    final currentOptions = _getCurrentWordOptions();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            final currentWord = widget.currentWord;
            final wordIndex = widget.wordIndex;
            final wordOptions = widget.wordOptions;

            if (currentWord != null &&
                currentWord.isNotEmpty &&
                wordIndex != null &&
                wordOptions != null) {
              final key = '${currentWord}_$wordIndex';

              // וודא שהמפתח קיים
              if (!wordOptions.containsKey(key)) {
                wordOptions[key] =
                    Map.fromIterable(_availableOptions, value: (_) => false);
              }

              // עדכן את האפשרות
              wordOptions[key]![option] = !wordOptions[key]![option]!;

              // קרא לקולבק
              widget.onOptionsChanged?.call();
            }
          });
        },
        borderRadius: BorderRadius.circular(4),
        canRequestFocus: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: currentOptions[option]!
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade600,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(3),
                  color: currentOptions[option]!
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
                child: currentOptions[option]!
                    ? Icon(
                        Icons.check,
                        size: 14,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
              ),
              const SizedBox(width: 6),
              Align(
                alignment: Alignment.center,
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.0, // מבטיח שהטקסט לא יהיה גבוה מדי
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      // הוחלף מ-AnimatedContainer
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Visibility(
        visible: widget.isVisible,
        maintainState: true, // שומר את המצב של ה-Checkboxes גם כשהמגירה סגורה
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15), // צל מעודן יותר
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border(
              left: BorderSide(color: Colors.grey.shade300),
              right: BorderSide(color: Colors.grey.shade300),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 48.0, right: 16.0, top: 8.0, bottom: 8.0),
            child: Wrap(
              spacing: 16.0, // רווח אופקי בין אלמנטים
              runSpacing: 8.0, // רווח אנכי בין שורות (זה המפתח!)
              children: _availableOptions
                  .map((option) => _buildCheckbox(option))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
