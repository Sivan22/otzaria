import 'package:flutter/material.dart';

class SearchOptionsDropdown extends StatefulWidget {
  final Function(bool)? onToggle;
  
  const SearchOptionsDropdown({super.key, this.onToggle});

  @override
  State<SearchOptionsDropdown> createState() => _SearchOptionsDropdownState();
}

class _SearchOptionsDropdownState extends State<SearchOptionsDropdown> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    widget.onToggle?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
      tooltip: 'אפשרויות חיפוש',
      onPressed: _toggleExpanded,
    );
  }
}

class SearchOptionsRow extends StatefulWidget {
  final bool isVisible;
  
  const SearchOptionsRow({super.key, required this.isVisible});

  @override
  State<SearchOptionsRow> createState() => _SearchOptionsRowState();
}

class _SearchOptionsRowState extends State<SearchOptionsRow> {
  final Map<String, bool> _options = {
    'קידומות': false,
    'סיומות': false,
    'קידומות דקדוקיות': false,
    'סיומות דקדוקיות': false,
    'כתיב מלא/חסר': false,
    'שורש': false,
  };

  Widget _buildCheckbox(String option) {
    return InkWell(
      onTap: () {
        setState(() {
          _options[option] = !_options[option]!;
        });
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _options[option]!
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade600,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
                color: _options[option]!
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: _options[option]!
                  ? Icon(
                      Icons.check,
                      size: 14,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            Text(
              option,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodyMedium?.color,
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
      height: widget.isVisible ? 60.0 : 0.0,
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
                      padding: const EdgeInsets.only(left: 48.0, right: 16.0, top: 12.0, bottom: 12.0),
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 8.0,
                        children: _options.keys.map((option) => _buildCheckbox(option)).toList(),
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
