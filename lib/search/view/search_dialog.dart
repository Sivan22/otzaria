import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/models/search_configuration.dart';
import 'package:otzaria/search/view/enhanced_search_field.dart';
import 'package:otzaria/search/view/full_text_settings_widgets.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/i18n/translations.g.dart';

/// דיאלוג חיפוש מתקדם - מכיל את כל פקדי החיפוש וההגדרות
/// כשמבצעים חיפוש, הדיאלוג נסגר ונפתחת לשונית תוצאות
class SearchDialog extends StatefulWidget {
  final SearchingTab? existingTab;

  const SearchDialog({super.key, this.existingTab});

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late SearchingTab _searchTab;
  bool _showIndexWarning = false;
  bool _showHistoryDropdown = false;
  final TextEditingController _alternativeWordController =
      TextEditingController();
  final Map<String, TextEditingController> _spacingControllers = {};
  final List<String> _currentAlternatives = [];

  @override
  void initState() {
    super.initState();

    // טעינת ההקלדה האחרונה מההגדרות (לא החיפוש בפועל)
    final lastTyping =
        Settings.getValue<String>('key-last-search-typing') ?? '';
    final lastMode =
        Settings.getValue<String>('key-last-search-mode') ?? 'advanced';

    // יצירת טאב עם ההקלדה האחרונה
    _searchTab = SearchingTab("חיפוש", lastTyping);

    // הגדרת מצב החיפוש האחרון
    final searchMode = lastMode == 'advanced'
        ? SearchMode.advanced
        : lastMode == 'fuzzy'
            ? SearchMode.fuzzy
            : SearchMode.exact;
    _searchTab.searchBloc.add(SetSearchMode(searchMode));

    // בדיקה אם האינדקס בתהליך בנייה
    final indexingState = context.read<IndexingBloc>().state;
    _showIndexWarning = indexingState is IndexingInProgress;

    // מאזין לשינויים בתיבת החיפוש כדי לעדכן את האפשרויות ולשמור את ההקלדה
    _searchTab.queryController.addListener(() {
      if (mounted) {
        // שמירת ההקלדה הנוכחית
        Settings.setValue<String>(
          'key-last-search-typing',
          _searchTab.queryController.text,
        );
        setState(() {
          // עדכון התצוגה כשהטקסט או מיקום הסמן משתנים
          // עדכון רשימת המילים החילופיות לפי המילה הנוכחית
          _updateAlternativesList();
        });
      }
    });

    // בקשת פוקוס לתיבת החיפוש
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchTab.searchFieldFocusNode.requestFocus();
      }
    });
  }

  Widget _buildIndexWarning() {
    if (!_showIndexWarning) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: Colors.yellow.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(FluentIcons.warning_24_regular, color: Colors.orange[700]),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'אינדקס החיפוש בתהליך עדכון. יתכן שחלק מהספרים לא יוצגו בתוצאות החיפוש.',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.dismiss_24_regular),
            onPressed: () {
              setState(() {
                _showIndexWarning = false;
              });
            },
          ),
        ],
      ),
    );
  }

  // שמירת חיפוש להיסטוריה (מקסימום 5)
  void _saveSearchToHistory(String query) {
    // שמירה כ-String מופרד בפסיקים
    final historyString = Settings.getValue<String>('key-search-history') ?? '';
    final history =
        historyString.isEmpty ? <String>[] : historyString.split('|||');

    // הסרת החיפוש אם הוא כבר קיים
    history.remove(query);

    // הוספה בתחילת הרשימה
    history.insert(0, query);

    // שמירת רק 5 אחרונים
    if (history.length > 5) {
      history.removeRange(5, history.length);
    }

    Settings.setValue<String>('key-search-history', history.join('|||'));
  }

  // קבלת היסטוריית חיפושים
  List<String> _getSearchHistory() {
    final historyString = Settings.getValue<String>('key-search-history') ?? '';
    if (historyString.isEmpty) return [];
    return historyString.split('|||');
  }

  // בניית מגירת ההיסטוריה
  Widget _buildHistoryDropdown() {
    final history = _getSearchHistory();
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: history.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          final query = history[index];
          return ListTile(
            dense: true,
            leading: const Icon(FluentIcons.search_24_regular, size: 18),
            title: Text(
              query,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14),
            ),
            onTap: () {
              _searchTab.queryController.text = query;
              setState(() => _showHistoryDropdown = false);
              _searchTab.searchFieldFocusNode.requestFocus();
            },
          );
        },
      ),
    );
  }

  void _updateAlternativesList() {
    final wordIndex = _getCurrentWordIndex();
    debugPrint(
      '🟣 Dialog _updateAlternativesList: wordIndex=$wordIndex, searchOptions keys=${_searchTab.searchOptions.keys.toList()}',
    );
    if (wordIndex != null) {
      // עדכון הרשימה לפי המילים החילופיות השמורות ב-tab
      final alternatives = _searchTab.alternativeWords[wordIndex] ?? [];
      // רק אם הרשימה באמת השתנתה
      if (_currentAlternatives.length != alternatives.length ||
          !_currentAlternatives.every((alt) => alternatives.contains(alt))) {
        _currentAlternatives.clear();
        _currentAlternatives.addAll(alternatives);
      }

      // עדכון המרווח - עכשיו משתמשים במפה של controllers
      final words = _searchTab.queryController.text.trim().split(
            RegExp(r'\s+'),
          );
      final totalWords = words.where((w) => w.isNotEmpty).length;
      if (wordIndex < totalWords - 1) {
        final key = '$wordIndex-${wordIndex + 1}';
        final controller = _getSpacingController(wordIndex, wordIndex + 1);
        final spacing = _searchTab.spacingValues[key] ?? '';
        if (controller.text != spacing) {
          controller.text = spacing;
        }
      }
    } else {
      // אם אין מילה נוכחית, נקה את הרשימה
      if (_currentAlternatives.isNotEmpty) {
        _currentAlternatives.clear();
      }
    }
  }

  TextEditingController _getSpacingController(int leftIndex, int rightIndex) {
    final key = '$leftIndex-$rightIndex';
    if (!_spacingControllers.containsKey(key)) {
      final controller = TextEditingController();
      // טעינת הערך השמור אם קיים
      if (_searchTab.spacingValues.containsKey(key)) {
        controller.text = _searchTab.spacingValues[key]!;
      }
      _spacingControllers[key] = controller;
    }
    return _spacingControllers[key]!;
  }

  @override
  void dispose() {
    _searchTab.queryController.removeListener(() {});
    _alternativeWordController.dispose();
    for (final controller in _spacingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _performSearch() {
    final query = _searchTab.queryController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.t.search.pleaseEnterText), // Old: 'נא להזין טקסט לחיפוש'
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // שמירת החיפוש להיסטוריה
    _saveSearchToHistory(query);

    // שמירת מצב החיפוש האחרון (לא את הטקסט - הוא כבר נשמר בזמן ההקלדה)
    final currentMode = _searchTab.searchBloc.state.configuration.searchMode;
    final modeString = currentMode == SearchMode.advanced
        ? 'advanced'
        : currentMode == SearchMode.fuzzy
            ? 'fuzzy'
            : 'exact';
    Settings.setValue<String>('key-last-search-mode', modeString);

    // יצירת טאב חדש לגמרי - ללא קשר לטאב קודם
    // שם הלשונית: "חיפוש: [מילות החיפוש]"
    final newSearchTab = SearchingTab("חיפוש: $query", query);

    // העתקת כל ההגדרות מהטאב הנוכחי לטאב החדש
    newSearchTab.searchOptions.addAll(_searchTab.searchOptions);
    newSearchTab.alternativeWords.addAll(_searchTab.alternativeWords);
    newSearchTab.spacingValues.addAll(_searchTab.spacingValues);

    // הוספה להיסטוריה
    context.read<HistoryBloc>().add(AddHistory(newSearchTab));

    // ביצוע החיפוש בטאב החדש
    newSearchTab.searchBloc.add(
      UpdateSearchQuery(
        query,
        customSpacing: newSearchTab.spacingValues,
        alternativeWords: newSearchTab.alternativeWords,
        searchOptions: newSearchTab.searchOptions,
      ),
    );

    // סגירת הדיאלוג
    Navigator.of(context).pop();

    // פתיחת טאב חדש תמיד
    final tabsBloc = context.read<TabsBloc>();
    final navigationBloc = context.read<NavigationBloc>();

    tabsBloc.add(AddTab(newSearchTab));

    // מעבר למסך העיון
    navigationBloc.add(const NavigateToScreen(Screen.search));
  }

  String? _getCurrentWord() {
    final text = _searchTab.queryController.text;
    final cursorPosition = _searchTab.queryController.selection.baseOffset;

    if (text.isEmpty || cursorPosition < 0) return null;

    final words = text.trim().split(RegExp(r'\s+'));
    int currentPos = 0;

    for (final word in words) {
      if (word.isEmpty) continue;

      final wordStart = text.indexOf(word, currentPos);
      if (wordStart == -1) continue;
      final wordEnd = wordStart + word.length;

      if (cursorPosition >= wordStart && cursorPosition <= wordEnd) {
        return word;
      }

      currentPos = wordEnd;
    }

    return null;
  }

  int? _getCurrentWordIndex() {
    final text = _searchTab.queryController.text;
    final cursorPosition = _searchTab.queryController.selection.baseOffset;

    if (text.isEmpty || cursorPosition < 0) return null;

    final words = text.trim().split(RegExp(r'\s+'));
    int currentPos = 0;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.isEmpty) continue;

      final wordStart = text.indexOf(word, currentPos);
      if (wordStart == -1) continue;
      final wordEnd = wordStart + word.length;

      if (cursorPosition >= wordStart && cursorPosition <= wordEnd) {
        return i;
      }

      currentPos = wordEnd;
    }

    return null;
  }

  Widget _buildSearchOptionsRow(
    bool isEnabled,
    String? currentWord,
    int? wordIndex,
  ) {
    const List<String> options = [
      'קידומות',
      'סיומות',
      'קידומות דקדוקיות',
      'סיומות דקדוקיות',
      'כתיב מלא/חסר',
      'חלק ממילה',
    ];

    // חישוב מספר המילים
    final words = _searchTab.queryController.text.trim().split(RegExp(r'\s+'));
    final totalWords = words.where((w) => w.isNotEmpty).length;

    Widget buildCheckbox(String option) {
      bool isChecked = false;

      if (isEnabled && currentWord != null && wordIndex != null) {
        final key = '${currentWord}_$wordIndex';
        isChecked = _searchTab.searchOptions[key]?[option] ?? false;
      }

      return Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: () {
            debugPrint(
              '🔴 Dialog: Checkbox clicked! isEnabled=$isEnabled, currentWord=$currentWord, wordIndex=$wordIndex',
            );
            if (isEnabled && currentWord != null && wordIndex != null) {
              setState(() {
                final key = '${currentWord}_$wordIndex';
                if (!_searchTab.searchOptions.containsKey(key)) {
                  _searchTab.searchOptions[key] = {};
                }
                _searchTab.searchOptions[key]![option] = !isChecked;
                debugPrint(
                  '🔵 Dialog: Set search option $key[$option] = ${!isChecked}',
                );
                debugPrint(
                  '🔵 Dialog: Total search options: ${_searchTab.searchOptions.keys.toList()}',
                );
              });
            } else {
              debugPrint('❌ Dialog: Cannot set option - conditions not met');
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEnabled && isChecked
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade600,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(3),
                    color: isEnabled && isChecked
                        ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: isEnabled && isChecked
                      ? Icon(
                          FluentIcons.checkmark_24_regular,
                          size: 14,
                          color: Theme.of(context).primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEnabled
                          ? Theme.of(context).textTheme.bodyMedium?.color
                          : Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSingleColumn = constraints.maxWidth < 600;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ניווט בין מילים - ממורכז
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(FluentIcons.chevron_left_24_regular),
                      onPressed: isEnabled && wordIndex != null && wordIndex > 0
                          ? () {
                              final text = _searchTab.queryController.text;
                              int currentPos = 0;
                              for (int i = 0; i < wordIndex - 1; i++) {
                                final wordStart = text.indexOf(
                                  words[i],
                                  currentPos,
                                );
                                currentPos = wordStart + words[i].length;
                              }
                              final targetWordStart = text.indexOf(
                                words[wordIndex - 1],
                                currentPos,
                              );
                              _searchTab.queryController.selection =
                                  TextSelection.collapsed(
                                offset: targetWordStart +
                                    words[wordIndex - 1].length ~/ 2,
                              );
                              setState(() {});
                            }
                          : null,
                      tooltip: 'מילה קודמת',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        isEnabled ? currentWord! : 'בחר מילה',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FluentIcons.chevron_right_24_regular),
                      onPressed: isEnabled &&
                              wordIndex != null &&
                              wordIndex < totalWords - 1
                          ? () {
                              final text = _searchTab.queryController.text;
                              int currentPos = 0;
                              for (int i = 0; i <= wordIndex; i++) {
                                final wordStart = text.indexOf(
                                  words[i],
                                  currentPos,
                                );
                                currentPos = wordStart + words[i].length;
                              }
                              final targetWordStart = text.indexOf(
                                words[wordIndex + 1],
                                currentPos,
                              );
                              _searchTab.queryController.selection =
                                  TextSelection.collapsed(
                                offset: targetWordStart +
                                    words[wordIndex + 1].length ~/ 2,
                              );
                              setState(() {});
                            }
                          : null,
                      tooltip: 'מילה הבאה',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // שורה עם תיבות טקסט ותיבות סימון
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // תיבות טקסט משמאל
                  if (isEnabled) ...[
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          // תיבת מרווח - מעל (תמיד גלויה)
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: isEnabled && wordIndex != null ? 1.0 : 0.5,
                            child: TextField(
                              enabled: isEnabled && wordIndex != null,
                              decoration: InputDecoration(
                                labelText: 'מרווח למילה הבאה',
                                hintText: '0-30',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    FluentIcons.dismiss_24_regular,
                                    size: 20,
                                  ),
                                  onPressed: isEnabled && wordIndex != null
                                      ? () {
                                          final key =
                                              '$wordIndex-${wordIndex + 1}';
                                          _searchTab.spacingValues.remove(key);
                                          _searchTab
                                              .spacingValuesChanged.value++;
                                          _getSpacingController(
                                            wordIndex,
                                            wordIndex + 1,
                                          ).clear();
                                        }
                                      : null,
                                  tooltip: 'מחק מרווח',
                                ),
                              ),
                              controller: wordIndex != null
                                  ? _getSpacingController(
                                      wordIndex,
                                      wordIndex + 1,
                                    )
                                  : TextEditingController(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^([0-9]|[12][0-9]|30)$'),
                                ),
                              ],
                              style: const TextStyle(fontSize: 14),
                              textAlign: TextAlign.right,
                              onChanged: (text) {
                                if (isEnabled &&
                                    wordIndex != null &&
                                    text.trim().isNotEmpty) {
                                  final key = '$wordIndex-${wordIndex + 1}';
                                  _searchTab.spacingValues[key] = text.trim();
                                  _searchTab.spacingValuesChanged.value++;
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // תיבת מילה חילופית - מתחת
                          TextField(
                            controller: _alternativeWordController,
                            decoration: InputDecoration(
                              labelText: 'מילה חילופית',
                              hintText: 'הקלד מילה...',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              prefixIcon: IconButton(
                                icon: const Icon(
                                  FluentIcons.add_24_regular,
                                  size: 20,
                                ),
                                onPressed: () {
                                  final text =
                                      _alternativeWordController.text.trim();
                                  if (text.isNotEmpty && wordIndex != null) {
                                    setState(() {
                                      if (!_currentAlternatives.contains(
                                        text,
                                      )) {
                                        _currentAlternatives.add(text);
                                      }
                                    });
                                    if (!_searchTab.alternativeWords
                                        .containsKey(wordIndex)) {
                                      _searchTab.alternativeWords[wordIndex] =
                                          [];
                                    }
                                    if (!_searchTab.alternativeWords[wordIndex]!
                                        .contains(text)) {
                                      _searchTab.alternativeWords[wordIndex]!
                                          .add(text);
                                    }
                                    _searchTab.alternativeWordsChanged.value++;
                                    _alternativeWordController.clear();
                                  }
                                },
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.right,
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty && wordIndex != null) {
                                setState(() {
                                  if (!_currentAlternatives.contains(
                                    text.trim(),
                                  )) {
                                    _currentAlternatives.add(text.trim());
                                  }
                                });
                                if (!_searchTab.alternativeWords.containsKey(
                                  wordIndex,
                                )) {
                                  _searchTab.alternativeWords[wordIndex] = [];
                                }
                                if (!_searchTab.alternativeWords[wordIndex]!
                                    .contains(text.trim())) {
                                  _searchTab.alternativeWords[wordIndex]!.add(
                                    text.trim(),
                                  );
                                }
                                _searchTab.alternativeWordsChanged.value++;
                                _alternativeWordController.clear();
                              }
                            },
                          ),

                          // רשימת מילים חילופיות
                          if (_currentAlternatives.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 100),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _currentAlternatives.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      _currentAlternatives[index],
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        FluentIcons.delete_24_regular,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        final wordToRemove =
                                            _currentAlternatives[index];
                                        setState(() {
                                          _currentAlternatives.removeAt(index);
                                        });
                                        if (wordIndex != null &&
                                            _searchTab.alternativeWords
                                                .containsKey(wordIndex)) {
                                          _searchTab
                                              .alternativeWords[wordIndex]!
                                              .remove(wordToRemove);
                                          if (_searchTab
                                              .alternativeWords[wordIndex]!
                                              .isEmpty) {
                                            _searchTab.alternativeWords.remove(
                                              wordIndex,
                                            );
                                          }
                                          _searchTab
                                              .alternativeWordsChanged.value++;
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // תיבות סימון
                  Expanded(
                    flex: 2,
                    child: useSingleColumn
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: options.map(buildCheckbox).toList(),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: options
                                      .take(3)
                                      .map(buildCheckbox)
                                      .toList(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: options
                                      .skip(3)
                                      .map(buildCheckbox)
                                      .toList(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context,
    String title,
    IconData icon,
    SearchMode mode,
    bool isSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.read<SearchBloc>().add(SetSearchMode(mode));
          _searchTab.searchFieldFocusNode.requestFocus();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onSecondaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = (screenSize.width * 0.7).clamp(500.0, 900.0);
    final dialogHeight = (screenSize.height * 0.65).clamp(450.0, 700.0);

    return BlocProvider.value(
      value: _searchTab.searchBloc,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // כותרת
              Row(
                children: [
                  const Icon(FluentIcons.search_24_filled, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'חיפוש',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'סגור',
                  ),
                ],
              ),
              const Divider(height: 24),

              // אזהרת אינדקס
              _buildIndexWarning(),

              // תוכן הדיאלוג - Row עם ניווט מימין ותוכן משמאל
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation Bar אנכי מימין
                    BlocBuilder<SearchBloc, SearchState>(
                      builder: (context, state) {
                        return Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildNavButton(
                                context,
                                'מדויק',
                                FluentIcons.text_quote_24_regular,
                                SearchMode.exact,
                                state.configuration.searchMode ==
                                    SearchMode.exact,
                              ),
                              const SizedBox(height: 4),
                              _buildNavButton(
                                context,
                                'מתקדם',
                                FluentIcons.search_info_24_regular,
                                SearchMode.advanced,
                                state.configuration.searchMode ==
                                    SearchMode.advanced,
                              ),
                              const SizedBox(height: 4),
                              _buildNavButton(
                                context,
                                'מקורב',
                                FluentIcons
                                    .arrow_bidirectional_left_right_24_regular,
                                SearchMode.fuzzy,
                                state.configuration.searchMode ==
                                    SearchMode.fuzzy,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    // תוכן ראשי
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // שדה החיפוש + מרווח בין מילים + מגירת היסטוריה
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // שורה עם תיבת החיפוש ומרווח בין מילים - באותו גובה
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // שדה החיפוש עם כפתור היסטוריה
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            // תיבת החיפוש
                                            BlocProvider.value(
                                              value: _searchTab.searchBloc,
                                              child: Focus(
                                                onKeyEvent: (node, event) {
                                                  if (event is KeyDownEvent &&
                                                      event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .enter) {
                                                    _performSearch();
                                                    return KeyEventResult
                                                        .handled;
                                                  }
                                                  return KeyEventResult.ignored;
                                                },
                                                child: EnhancedSearchField(
                                                  key: enhancedSearchFieldKey,
                                                  widget: _SearchDialogWrapper(
                                                    tab: _searchTab,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // כפתור חיפוש - מצד ימין
                                            Positioned(
                                              right: 10,
                                              top: 8,
                                              bottom: 8,
                                              child: Center(
                                                child: IconButton(
                                                  icon: const Icon(
                                                    FluentIcons
                                                        .search_24_filled,
                                                    size: 20,
                                                  ),
                                                  tooltip: 'חפש',
                                                  onPressed: _performSearch,
                                                  style: IconButton.styleFrom(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primaryContainer,
                                                    foregroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    padding:
                                                        const EdgeInsets.all(6),
                                                    minimumSize:
                                                        const Size(32, 32),
                                                    tapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // כפתור היסטוריה - ליד כפתור ה-X
                                            Positioned(
                                              left: 48,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: IconButton(
                                                  icon: Icon(
                                                    _showHistoryDropdown
                                                        ? FluentIcons
                                                            .chevron_up_24_regular
                                                        : FluentIcons
                                                            .history_24_regular,
                                                    size: 24,
                                                  ),
                                                  tooltip: 'היסטוריית חיפושים',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                  onPressed: () {
                                                    setState(() {
                                                      _showHistoryDropdown =
                                                          !_showHistoryDropdown;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // מרווח בין מילים - באותו גובה
                                      BlocBuilder<SearchBloc, SearchState>(
                                        builder: (context, state) {
                                          if (state.fuzzy) {
                                            return const SizedBox.shrink();
                                          }
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 16.0,
                                            ),
                                            child: Center(
                                              child: FuzzyDistance(
                                                tab: _searchTab,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                // מגירת היסטוריה - מתחת לשורה
                                if (_showHistoryDropdown)
                                  _buildHistoryDropdown(),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // אפשרויות חיפוש עם הטיפ
                            BlocBuilder<SearchBloc, SearchState>(
                              builder: (context, state) {
                                if (!state.isAdvancedSearchEnabled) {
                                  return const SizedBox.shrink();
                                }

                                final currentWord = _getCurrentWord();
                                final wordIndex = _getCurrentWordIndex();
                                final hasWord = currentWord != null &&
                                    currentWord.isNotEmpty &&
                                    wordIndex != null;

                                return _buildSearchOptionsRow(
                                  hasWord,
                                  currentWord,
                                  wordIndex,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrapper class to provide the TantivyFullTextSearch interface
/// without actually using the full widget
class _SearchDialogWrapper {
  final SearchingTab tab;

  _SearchDialogWrapper({required this.tab});
}
