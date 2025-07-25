import 'package:flutter/material.dart';

class SearchOptionsDropdown extends StatefulWidget {
  const SearchOptionsDropdown({super.key});

  @override
  State<SearchOptionsDropdown> createState() => _SearchOptionsDropdownState();
}

class _SearchOptionsDropdownState extends State<SearchOptionsDropdown> {
  final Map<String, bool> _options = {
    'קידומות': false,
    'סיומות': false,
    'קידומות דקדוקיות': false,
    'סיומות דקדוקיות': false,
    'כתיב מלא/חסר': false,
    'שורש': false,
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.keyboard_arrow_down),
      tooltip: 'אפשרויות חיפוש',
      offset: const Offset(0, 40),
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 250),
      color: Theme.of(context).popupMenuTheme.color ??
          Theme.of(context).canvasColor,
      itemBuilder: (BuildContext context) {
        return [
          // כותרת התפריט
          PopupMenuItem<String>(
            enabled: false,
            height: 30,
            child: Text(
              'אפשרויות חיפוש',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
          const PopupMenuDivider(),
          // האפשרויות
          ..._options.keys.map((String option) {
            return PopupMenuItem<String>(
              value: option,
              enabled: false, // מונע סגירה של התפריט בלחיצה
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setMenuState) {
                  return InkWell(
                    onTap: () {
                      setMenuState(() {
                        _options[option] = !_options[option]!;
                      });
                      setState(() {}); // עדכון המצב הכללי
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _options[option]!
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade600,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              color: _options[option]!
                                  ? Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1)
                                  : Colors.transparent,
                            ),
                            child: _options[option]!
                                ? Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color ??
                                        Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ];
      },
      onSelected: (String value) {
        // כרגע לא נעשה כלום - כפי שביקשת
      },
    );
  }
}
