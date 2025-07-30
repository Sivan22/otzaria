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

  const SearchOptionsRow({
    super.key,
    required this.isVisible,
    this.currentWord,
  });

  @override
  State<SearchOptionsRow> createState() => _SearchOptionsRowState();
}

class _SearchOptionsRowState extends State<SearchOptionsRow> {
  // מפה שמחזיקה אפשרויות לכל מילה
  static final Map<String, Map<String, bool>> _wordOptions = {};

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
    if (currentWord == null || currentWord.isEmpty) {
      return Map.fromIterable(_availableOptions, value: (_) => false);
    }

    // אם אין אפשרויות למילה הזו, ניצור אותן
    if (!_wordOptions.containsKey(currentWord)) {
      _wordOptions[currentWord] =
          Map.fromIterable(_availableOptions, value: (_) => false);
    }

    return _wordOptions[currentWord]!;
  }

  Widget _buildCheckbox(String option) {
    final currentOptions = _getCurrentWordOptions();

    return InkWell(
      onTap: () {
        setState(() {
          final currentWord = widget.currentWord;
          if (currentWord != null && currentWord.isNotEmpty) {
            currentOptions[option] = !currentOptions[option]!;
          }
        });
      },
      borderRadius: BorderRadius.circular(4),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.isVisible ? 40.0 : 0.0,
      width: double.infinity,
      child: widget.isVisible
          ? ColoredBox(
              color: Colors.white, // רקע אטום מלא
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade400, width: 1),
                    right: BorderSide(color: Colors.grey.shade400, width: 1),
                    bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
                child: ColoredBox(
                  color: Colors.white, // עוד שכבת רקע אטום
                  child: Material(
                    color: Colors.white,
                    child: ColoredBox(
                      color: Colors.white, // שכבה נוספת
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 48.0, right: 16.0, top: 8.0, bottom: 8.0),
                        child: Wrap(
                          spacing: 16.0,
                          runSpacing: 8.0,
                          children: _availableOptions
                              .map((option) => _buildCheckbox(option))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
