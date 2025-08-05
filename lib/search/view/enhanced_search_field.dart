import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/search/models/search_terms_model.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_state.dart';
import 'package:otzaria/search/utils/regex_patterns.dart';

// הווידג'ט החדש לניהול מצבי הכפתור
class _PlusButton extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _PlusButton({
    required this.active,
    required this.onTap,
  });

  @override
  State<_PlusButton> createState() => _PlusButtonState();
}

// כפתור המרווח שמופיע בריחוף - עגול כמו כפתור ה+
class _SpacingButton extends StatefulWidget {
  final VoidCallback onTap;

  const _SpacingButton({
    required this.onTap,
  });

  @override
  State<_SpacingButton> createState() => _SpacingButtonState();
}

class _PlusButtonState extends State<_PlusButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = widget.active || _isHovering;
    final primaryColor = Theme.of(context).primaryColor;

    // MouseRegion מזהה ריחוף עכבר
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          // אנימציה למעבר חלק
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isHighlighted
                ? primaryColor
                : primaryColor.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: [
              if (isHighlighted)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: const Icon(
            Icons.add,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SpacingButtonState extends State<_SpacingButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: _isHovering
                ? primaryColor
                : primaryColor.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              if (_isHovering)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: const Icon(
            Icons.more_horiz,
            size: 12,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// תיבה צפה למרווח בין מילים
class _SpacingField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onRemove;
  final VoidCallback? onFocusLost;

  const _SpacingField({
    required this.controller,
    required this.onRemove,
    this.onFocusLost,
  });

  @override
  State<_SpacingField> createState() => _SpacingFieldState();
}

class _SpacingFieldState extends State<_SpacingField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
    _focus.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
    if (!_focus.hasFocus && widget.controller.text.trim().isEmpty) {
      widget.onFocusLost?.call();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    final bool hasFocus = _focus.hasFocus;
    final bool isFloating = hasFocus || hasText; // התנאי להצפת התווית
    final bool isInactive = !hasFocus && hasText;

    final floatingLabelStyle = TextStyle(
      color: hasFocus ? theme.primaryColor : theme.hintColor,
      fontSize: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
    );
    final placeholderStyle = TextStyle(
      color: theme.hintColor.withOpacity(0.8),
      fontSize: 12,
    );

    return AnimatedOpacity(
      opacity: isInactive ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        clipBehavior: Clip.none, // מאפשר לתווית לצאת מגבולות ה-Stack
        children: [
          // 1. קופסת הקלט עצמה (השכבה התחתונה)
          Container(
            width: 45, // רוחב צר למספר 1-2 ספרות
            height: 40,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasFocus ? theme.primaryColor : theme.dividerColor,
                width: hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(hasFocus ? 0.15 : 0.08),
                  blurRadius: hasFocus ? 6 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: widget.onRemove,
                    splashRadius: 16,
                    padding: const EdgeInsets.only(left: 4, right: 2),
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        // הסרנו את labelText מכאן
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.only(right: 4, bottom: 4),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w200, // גופן צר לטקסט שנכתב
                      ),
                      textAlign: TextAlign.right,
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) widget.onRemove();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. התווית הצפה (השכבה העליונה)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            // מיקום דינמי: למעלה או באמצע
            top: isFloating ? -10 : 10,
            right: isFloating ? 8 : 12,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: isFloating ? floatingLabelStyle : placeholderStyle,
              child: Container(
                // קונטיינר זה יוצר את אפקט ה"חיתוך" של הגבול
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Text(
                  'מרווח',
                  style: TextStyle(
                    fontWeight: FontWeight.w100, // גופן צר במיוחד
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlternativeField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onRemove;
  final VoidCallback? onFocusLost;

  const _AlternativeField({
    required this.controller,
    required this.onRemove,
    this.onFocusLost,
  });

  @override
  State<_AlternativeField> createState() => _AlternativeFieldState();
}

class _AlternativeFieldState extends State<_AlternativeField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
    _focus.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
    if (!_focus.hasFocus && widget.controller.text.trim().isEmpty) {
      widget.onFocusLost?.call();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    final bool hasFocus = _focus.hasFocus;
    final bool isFloating = hasFocus || hasText; // התנאי להצפת התווית
    final bool isInactive = !hasFocus && hasText;

    final floatingLabelStyle = TextStyle(
      color: hasFocus ? theme.primaryColor : theme.hintColor,
      fontSize: 12,
      backgroundColor: theme.scaffoldBackgroundColor,
    );
    final placeholderStyle = TextStyle(
      color: theme.hintColor.withOpacity(0.8),
      fontSize: 12,
    );

    return AnimatedOpacity(
      opacity: isInactive ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        clipBehavior: Clip.none, // מאפשר לתווית לצאת מגבולות ה-Stack
        children: [
          // 1. קופסת הקלט עצמה (השכבה התחתונה)
          Container(
            width: 60, // רוחב צר למילה של כ-4 תווים
            height: 40,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: hasFocus ? theme.primaryColor : theme.dividerColor,
                width: hasFocus ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(hasFocus ? 0.15 : 0.08),
                  blurRadius: hasFocus ? 6 : 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: widget.onRemove,
                    splashRadius: 16,
                    padding: const EdgeInsets.only(left: 4, right: 2),
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(SearchRegexPatterns.spacesFilter),
                      ],
                      decoration: const InputDecoration(
                        // הסרנו את labelText מכאן
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.only(right: 4, bottom: 4),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w200, // גופן צר לטקסט שנכתב
                      ),
                      textAlign: TextAlign.right,
                      onSubmitted: (v) {
                        if (v.trim().isEmpty) widget.onRemove();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. התווית הצפה (השכבה העליונה)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            // מיקום דינמי
            top: isFloating ? -10 : 10,
            right: isFloating ? 8 : 15,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: isFloating ? floatingLabelStyle : placeholderStyle,
              child: Container(
                // קונטיינר זה יוצר את אפקט ה"חיתוך" של הגבול
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: const Text(
                  'מילה חילופית',
                  style: TextStyle(
                    fontWeight: FontWeight.w100, // גופן צר במיוחד
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedSearchField extends StatefulWidget {
  final TantivyFullTextSearch widget;

  const EnhancedSearchField({
    super.key,
    required this.widget,
  });

  @override
  State<EnhancedSearchField> createState() => _EnhancedSearchFieldState();
}

class _EnhancedSearchFieldState extends State<EnhancedSearchField> {
  SearchQuery _searchQuery = SearchQuery();
  final GlobalKey _textFieldKey = GlobalKey();
  final GlobalKey _stackKey = GlobalKey();
  final List<Offset> _wordPositions = [];
  final Map<int, List<TextEditingController>> _alternativeControllers = {};
  final Map<int, List<OverlayEntry>> _alternativeOverlays = {};
  OverlayEntry? _searchOptionsOverlay;
  int? _hoveredWordIndex;

  final Map<String, OverlayEntry> _spacingOverlays = {};
  final Map<String, TextEditingController> _spacingControllers = {};

  final List<double> _wordLeftEdges = [];
  final List<double> _wordRightEdges = [];

  static const double _kSearchFieldMinWidth = 300;
  static const double _kControlHeight = 48;

  static const double _kPlusYOffset = 10;
  static const double _kPlusRadius = 10;
  static const double _kSpacingYOffset = 53;

  String _spaceKey(int left, int right) => '$left-$right';

  @override
  void initState() {
    super.initState();
    widget.widget.tab.queryController.addListener(_onTextChanged);
    // מאזין לשינויי מיקום הסמן
    widget.widget.tab.searchFieldFocusNode
        .addListener(_onCursorPositionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateWordPositions();
    });
  }

  @override
  void deactivate() {
    debugPrint('⏸️ EnhancedSearchField deactivating - clearing overlays');
    _clearAllOverlays();
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint('🗑️ EnhancedSearchField disposing');
    _clearAllOverlays();
    widget.widget.tab.queryController.removeListener(_onTextChanged);
    widget.widget.tab.searchFieldFocusNode
        .removeListener(_onCursorPositionChanged);
    _disposeControllers(); // במצב dispose אנחנו רוצים למחוק הכל
    // ניקוי אפשרויות החיפוש כשסוגרים את המסך
    widget.widget.tab.searchOptions.clear();
    super.dispose();
  }

  // שמירת נתונים לפני ניקוי
  void _saveDataToTab() {
    // שמירת מילים חילופיות
    widget.widget.tab.alternativeWords.clear();
    for (int termIndex in _alternativeControllers.keys) {
      final alternatives = _alternativeControllers[termIndex]!
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (alternatives.isNotEmpty) {
        widget.widget.tab.alternativeWords[termIndex] = alternatives;
      }
    }

    // שמירת מרווחים
    widget.widget.tab.spacingValues.clear();
    for (String key in _spacingControllers.keys) {
      final spacingText = _spacingControllers[key]!.text.trim();
      if (spacingText.isNotEmpty) {
        widget.widget.tab.spacingValues[key] = spacingText;
      }
    }
  }

  // שחזור נתונים מה-tab
  void _restoreDataFromTab() {
    // ניקוי controllers קיימים לפני השחזור
    _disposeControllers();

    // עדכון ה-searchQuery מהטקסט הנוכחי
    final text = widget.widget.tab.queryController.text;
    if (text.isNotEmpty) {
      _searchQuery = SearchQuery.fromString(text);
    }

    // שחזור מילים חילופיות
    for (final entry in widget.widget.tab.alternativeWords.entries) {
      final termIndex = entry.key;
      final alternatives = entry.value;

      _alternativeControllers[termIndex] = alternatives.map((alt) {
        final controller = TextEditingController(text: alt);
        controller.addListener(() => _updateAlternativeWordsInTab());
        return controller;
      }).toList();
    }

    // שחזור מרווחים
    for (final entry in widget.widget.tab.spacingValues.entries) {
      final key = entry.key;
      final value = entry.value;

      final controller = TextEditingController(text: value);
      controller.addListener(() => _updateSpacingInTab());
      _spacingControllers[key] = controller;
    }
  }

  // הצגת בועות שחוזרו
  void _showRestoredBubbles() {
    // הצגת מילים חילופיות
    for (final entry in _alternativeControllers.entries) {
      final termIndex = entry.key;
      final controllers = entry.value;
      for (int j = 0; j < controllers.length; j++) {
        if (termIndex < _wordPositions.length) {
          _showAlternativeOverlay(termIndex, j);
        }
      }
    }

    // הצגת מרווחים
    for (final key in _spacingControllers.keys) {
      final parts = key.split('-');
      if (parts.length == 2) {
        final leftIndex = int.tryParse(parts[0]);
        final rightIndex = int.tryParse(parts[1]);
        if (leftIndex != null &&
            rightIndex != null &&
            leftIndex < _wordPositions.length &&
            rightIndex < _wordPositions.length) {
          _showSpacingOverlay(leftIndex, rightIndex);
        }
      }
    }
  }

  // ניקוי נתונים לא רלוונטיים כשהמילים משתנות
  void _cleanupIrrelevantData(Set<String> newWords) {
    // ניקוי אפשרויות חיפוש למילים שלא קיימות יותר
    final searchOptionsKeysToRemove = <String>[];
    for (final key in widget.widget.tab.searchOptions.keys) {
      final parts = key.split('_');
      if (parts.isNotEmpty) {
        final word = parts[0];
        if (!newWords.contains(word)) {
          searchOptionsKeysToRemove.add(key);
        }
      }
    }

    for (final key in searchOptionsKeysToRemove) {
      widget.widget.tab.searchOptions.remove(key);
    }
  }

  void _clearAllOverlays(
      {bool keepSearchDrawer = false, bool keepFilledBubbles = false}) {
    debugPrint(
        '🧹 CLEAR OVERLAYS: ${DateTime.now()} - keepSearchDrawer: $keepSearchDrawer, keepFilledBubbles: $keepFilledBubbles');
    // ניקוי אלטרנטיבות - רק אם לא ביקשנו לשמור בועות מלאות או אם הן ריקות
    if (!keepFilledBubbles) {
      debugPrint(
          '🧹 Clearing ${_alternativeOverlays.length} alternative overlay groups');
      for (final entries in _alternativeOverlays.values) {
        for (final entry in entries) {
          entry.remove();
        }
      }
      _alternativeOverlays.clear();
    } else {
      // שמירה רק על בועות עם טקסט
      final keysToRemove = <int>[];
      for (final termIndex in _alternativeOverlays.keys) {
        final controllers = _alternativeControllers[termIndex] ?? [];
        final overlays = _alternativeOverlays[termIndex] ?? [];

        final indicesToRemove = <int>[];
        for (int i = 0; i < controllers.length; i++) {
          if (controllers[i].text.trim().isEmpty) {
            if (i < overlays.length) {
              overlays[i].remove();
              indicesToRemove.add(i);
            }
          }
        }

        // הסרה בסדר הפוך כדי לא לפגוע באינדקסים
        for (int i = indicesToRemove.length - 1; i >= 0; i--) {
          final indexToRemove = indicesToRemove[i];
          if (indexToRemove < overlays.length) {
            overlays.removeAt(indexToRemove);
          }
          if (indexToRemove < controllers.length) {
            controllers[indexToRemove].dispose();
            controllers.removeAt(indexToRemove);
          }
        }

        if (overlays.isEmpty) {
          keysToRemove.add(termIndex);
        }
      }

      for (final key in keysToRemove) {
        _alternativeOverlays.remove(key);
        _alternativeControllers.remove(key);
      }
    }

    // ניקוי מרווחים - רק אם לא ביקשנו לשמור בועות מלאות או אם הן ריקות
    if (!keepFilledBubbles) {
      debugPrint('🧹 Clearing ${_spacingOverlays.length} spacing overlays');
      for (final entry in _spacingOverlays.values) {
        entry.remove();
      }
      _spacingOverlays.clear();
    } else {
      // שמירה רק על בועות עם טקסט
      final keysToRemove = <String>[];
      for (final key in _spacingOverlays.keys) {
        final controller = _spacingControllers[key];
        if (controller == null || controller.text.trim().isEmpty) {
          _spacingOverlays[key]?.remove();
          keysToRemove.add(key);
        }
      }

      for (final key in keysToRemove) {
        _spacingOverlays.remove(key);
        _spacingControllers[key]?.dispose();
        _spacingControllers.remove(key);
      }
    }

    // סגירת מגירת האפשרויות רק אם לא ביקשנו לשמור אותה
    if (!keepSearchDrawer) {
      _searchOptionsOverlay?.remove();
      _searchOptionsOverlay = null;
    }
  }

  void _disposeControllers({bool keepFilledControllers = false}) {
    if (!keepFilledControllers) {
      // מחיקה מלאה של כל ה-controllers
      for (final controllers in _alternativeControllers.values) {
        for (final controller in controllers) {
          controller.dispose();
        }
      }
      _alternativeControllers.clear();
      for (final controller in _spacingControllers.values) {
        controller.dispose();
      }
      _spacingControllers.clear();
    } else {
      // מחיקה רק של controllers ריקים
      final alternativeKeysToRemove = <int>[];
      for (final entry in _alternativeControllers.entries) {
        final termIndex = entry.key;
        final controllers = entry.value;
        final indicesToRemove = <int>[];

        for (int i = 0; i < controllers.length; i++) {
          if (controllers[i].text.trim().isEmpty) {
            controllers[i].dispose();
            indicesToRemove.add(i);
          }
        }

        // הסרה בסדר הפוך
        for (int i = indicesToRemove.length - 1; i >= 0; i--) {
          controllers.removeAt(indicesToRemove[i]);
        }

        if (controllers.isEmpty) {
          alternativeKeysToRemove.add(termIndex);
        }
      }

      for (final key in alternativeKeysToRemove) {
        _alternativeControllers.remove(key);
      }

      // מחיקת spacing controllers ריקים
      final spacingKeysToRemove = <String>[];
      for (final entry in _spacingControllers.entries) {
        if (entry.value.text.trim().isEmpty) {
          entry.value.dispose();
          spacingKeysToRemove.add(entry.key);
        }
      }

      for (final key in spacingKeysToRemove) {
        _spacingControllers.remove(key);
      }
    }
  }

  void _onTextChanged() {
    // בודקים אם המגירה הייתה פתוחה לפני השינוי
    final bool drawerWasOpen = _searchOptionsOverlay != null;

    final text = widget.widget.tab.queryController.text;

    // בדיקה אם המילים השתנו באופן משמעותי - אם כן, נקה נתונים ישנים
    final newWords =
        text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final oldWords = _searchQuery.terms.map((t) => t.word).toSet();

    final bool wordsChangedSignificantly =
        !newWords.containsAll(oldWords) || !oldWords.containsAll(newWords);

    if (wordsChangedSignificantly) {
      // אם המילים השתנו משמעותית, נקה נתונים ישנים שלא רלוונטיים
      _cleanupIrrelevantData(newWords);
    }

    // מנקים את כל הבועות, אבל שומרים על בועות עם טקסט ועל המגירה אם הייתה פתוחה
    _clearAllOverlays(keepSearchDrawer: drawerWasOpen, keepFilledBubbles: true);

    // אם שדה החיפוש התרוקן, נסגור את המגירה בכל זאת
    if (text.trim().isEmpty && drawerWasOpen) {
      _hideSearchOptionsOverlay();
      _notifyDropdownClosed();
      // יוצאים מהפונקציה כדי לא להמשיך
      return;
    }

    setState(() {
      _searchQuery = SearchQuery.fromString(text);
      _updateAlternativeControllers();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateWordPositions();

      // הצגת alternatives מה-SearchQuery
      for (int i = 0; i < _searchQuery.terms.length; i++) {
        for (int j = 0; j < _searchQuery.terms[i].alternatives.length; j++) {
          _showAlternativeOverlay(i, j);
        }
      }

      // הצגת alternatives קיימים שנשמרו
      for (final entry in _alternativeControllers.entries) {
        final termIndex = entry.key;
        final controllers = entry.value;
        for (int j = 0; j < controllers.length; j++) {
          if (controllers[j].text.trim().isNotEmpty) {
            // בדיקה שהבועה לא מוצגת כבר
            final existingOverlays = _alternativeOverlays[termIndex] ?? [];
            if (j >= existingOverlays.length) {
              _showAlternativeOverlay(termIndex, j);
            }
          }
        }
      }

      // הצגת spacing overlays קיימים
      for (final entry in _spacingControllers.entries) {
        final key = entry.key;
        final controller = entry.value;
        if (controller.text.trim().isNotEmpty &&
            !_spacingOverlays.containsKey(key)) {
          // פירוק המפתח לאינדקסים
          final parts = key.split('-');
          if (parts.length == 2) {
            final leftIndex = int.tryParse(parts[0]);
            final rightIndex = int.tryParse(parts[1]);
            if (leftIndex != null &&
                rightIndex != null &&
                leftIndex < _wordPositions.length &&
                rightIndex < _wordPositions.length) {
              _showSpacingOverlay(leftIndex, rightIndex);
            }
          }
        }
      }

      // אם המגירה הייתה פתוחה, מרעננים את התוכן שלה
      if (drawerWasOpen) {
        _updateSearchOptionsOverlay();
      }
    });
  }

  void _onCursorPositionChanged() {
    // עדכון המגירה כשהסמן זז (אם היא פתוחה)
    if (_searchOptionsOverlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateSearchOptionsOverlay();
      });
    }
  }

  void _updateSearchOptionsOverlay() {
    // עדכון המגירה אם היא פתוחה
    if (_searchOptionsOverlay != null) {
      // שמירת מיקום הסמן לפני העדכון
      final currentSelection = widget.widget.tab.queryController.selection;

      _hideSearchOptionsOverlay();
      _showSearchOptionsOverlay();

      // החזרת מיקום הסמן אחרי העדכון
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print(
              'DEBUG: Restoring cursor position in update: ${currentSelection.baseOffset}');
          widget.widget.tab.queryController.selection = currentSelection;
        }
      });
    }
  }

  void _updateAlternativeControllers() {
    // שמירה על controllers קיימים שיש בהם טקסט
    final Map<int, List<TextEditingController>> existingControllers = {};
    for (final entry in _alternativeControllers.entries) {
      final termIndex = entry.key;
      final controllers = entry.value;
      final controllersWithText =
          controllers.where((c) => c.text.trim().isNotEmpty).toList();
      if (controllersWithText.isNotEmpty) {
        existingControllers[termIndex] = controllersWithText;
      }
    }

    // מחיקת controllers ריקים בלבד
    for (final entry in _alternativeControllers.entries) {
      final controllers = entry.value;
      for (final controller in controllers) {
        if (controller.text.trim().isEmpty) {
          controller.dispose();
        }
      }
    }

    // איפוס המפה
    _alternativeControllers.clear();

    // החזרת controllers עם טקסט
    _alternativeControllers.addAll(existingControllers);

    // הוספת controllers חדשים מה-SearchQuery
    for (int i = 0; i < _searchQuery.terms.length; i++) {
      final term = _searchQuery.terms[i];
      _alternativeControllers.putIfAbsent(i, () => []);

      // הוספת alternatives מה-SearchQuery שלא קיימים כבר
      for (final alt in term.alternatives) {
        final existingTexts =
            _alternativeControllers[i]!.map((c) => c.text).toList();
        if (!existingTexts.contains(alt)) {
          final controller = TextEditingController(text: alt);
          controller.addListener(() => _updateAlternativeWordsInTab());
          _alternativeControllers[i]!.add(controller);
        }
      }
    }
  }

  void _calculateWordPositions() {
    if (_textFieldKey.currentContext == null) return;

    RenderEditable? editable;
    void findEditable(RenderObject child) {
      if (child is RenderEditable) {
        editable = child;
      } else {
        child.visitChildren(findEditable);
      }
    }

    _textFieldKey.currentContext!
        .findRenderObject()!
        .visitChildren(findEditable);
    if (editable == null) return;

    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final stackOrigin = stackBox.localToGlobal(Offset.zero);

    _wordPositions.clear();
    _wordLeftEdges.clear();
    _wordRightEdges.clear();

    final text = widget.widget.tab.queryController.text;
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    final words = text.trim().split(RegExp(r'\s+'));
    int idx = 0;
    for (final w in words) {
      if (w.isEmpty) continue;
      final start = text.indexOf(w, idx);
      if (start == -1) continue;
      final end = start + w.length;

      final pts = editable!.getEndpointsForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
      );
      if (pts.isEmpty) continue;

      final leftLocalX = pts.first.point.dx;
      final rightLocalX = pts.last.point.dx;

      final leftGlobal = editable!.localToGlobal(Offset(leftLocalX, 0));
      final rightGlobal = editable!.localToGlobal(Offset(rightLocalX, 0));

      _wordLeftEdges.add(leftGlobal.dx - stackOrigin.dx);
      _wordRightEdges.add(rightGlobal.dx - stackOrigin.dx);

      final centerLocalX = (leftLocalX + rightLocalX) / 2;
      final local = Offset(
        centerLocalX,
        editable!.size.height + _kPlusYOffset,
      );
      final global = editable!.localToGlobal(local);
      _wordPositions.add(global - stackOrigin);

      idx = end;
    }

    if (text.isNotEmpty && _wordPositions.isEmpty) {
// החישוב נכשל למרות שיש טקסט. ננסה שוב ב-frame הבא.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // ודא שהווידג'ט עדיין קיים
          _calculateWordPositions();
        }
      });
      return; // צא מהפונקציה כדי לא לקרוא ל-setState עם מידע שגוי
    }

    setState(() {});
  }

  void _addAlternative(int termIndex) {
    setState(() {
      _alternativeControllers.putIfAbsent(termIndex, () => []);
      if (_alternativeControllers[termIndex]!.length >= 2) {
        return;
      }
      final newIndex = _alternativeControllers[termIndex]!.length;
      final controller = TextEditingController();
      // הוספת listener לעדכון המידע ב-tab כשהטקסט משתנה
      controller.addListener(() => _updateAlternativeWordsInTab());
      _alternativeControllers[termIndex]!.add(controller);
      _showAlternativeOverlay(termIndex, newIndex);
    });
    _updateAlternativeWordsInTab();
  }

  void _removeAlternative(int termIndex, int altIndex) {
    setState(() {
      if (_alternativeOverlays.containsKey(termIndex) &&
          altIndex < _alternativeOverlays[termIndex]!.length) {
        _alternativeOverlays[termIndex]![altIndex].remove();
        _alternativeOverlays[termIndex]!.removeAt(altIndex);
      }
      if (_alternativeControllers.containsKey(termIndex) &&
          altIndex < _alternativeControllers[termIndex]!.length) {
        _alternativeControllers[termIndex]![altIndex].dispose();
        _alternativeControllers[termIndex]!.removeAt(altIndex);
      }
      _refreshAlternativeOverlays(termIndex);
    });
    // עדכון המידע ב-tab אחרי הסרת החלופה
    _updateAlternativeWordsInTab();
  }

  void _checkAndRemoveEmptyField(int termIndex, int altIndex) {
    if (_alternativeControllers.containsKey(termIndex) &&
        altIndex < _alternativeControllers[termIndex]!.length &&
        _alternativeControllers[termIndex]![altIndex].text.trim().isEmpty) {
      _removeAlternative(termIndex, altIndex);
    }
  }

  void _refreshAlternativeOverlays(int termIndex) {
    if (!_alternativeOverlays.containsKey(termIndex)) return;
    for (final overlay in _alternativeOverlays[termIndex]!) {
      overlay.remove();
    }
    _alternativeOverlays[termIndex]!.clear();
    for (int i = 0; i < _alternativeControllers[termIndex]!.length; i++) {
      _showAlternativeOverlay(termIndex, i);
    }
  }

  void _showAlternativeOverlay(int termIndex, int altIndex) {
    debugPrint(
        '🎈 Showing alternative overlay: term=$termIndex, alt=$altIndex');

    // בדיקה שהאינדקסים תקינים
    if (termIndex >= _wordPositions.length ||
        !_alternativeControllers.containsKey(termIndex) ||
        altIndex >= _alternativeControllers[termIndex]!.length) {
      debugPrint('❌ Invalid indices for alternative overlay');
      return;
    }

    // בדיקה שהבועה לא מוצגת כבר
    final existingOverlays = _alternativeOverlays[termIndex];
    if (existingOverlays != null &&
        altIndex < existingOverlays.length &&
        mounted && // ודא שה-State עדיין קיים
        Overlay.of(context).mounted && // ודא שה-Overlay קיים
        existingOverlays[altIndex].mounted) {
      // ודא שהבועה הספציפית הזו עדיין על המסך
      debugPrint('⚠️ Alternative overlay already exists and mounted');
      return; // אם הבועה כבר קיימת ומוצגת, אל תעשה כלום
    }

    final overlayState = Overlay.of(context);
    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final textFieldGlobalPosition = textFieldBox.localToGlobal(Offset.zero);
    final wordRelativePosition = _wordPositions[termIndex];
    final overlayPosition = textFieldGlobalPosition + wordRelativePosition;
    final controller = _alternativeControllers[termIndex]![altIndex];
    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: overlayPosition.dx -
              35, // מרכוז התיבה (70/2 = 35) מתחת לכפתור ה-+
          top: overlayPosition.dy + 15 + (altIndex * 45.0),
          child: _AlternativeField(
            controller: controller,
            onRemove: () => _removeAlternative(termIndex, altIndex),
            onFocusLost: () => _checkAndRemoveEmptyField(termIndex, altIndex),
          ),
        );
      },
    );
    _alternativeOverlays.putIfAbsent(termIndex, () => []).add(entry);
    overlayState.insert(entry);
  }

  Widget _buildPlusButton(int termIndex, Offset position) {
    final bool isActive =
        _alternativeControllers[termIndex]?.isNotEmpty ?? false;
    return Positioned(
      left: position.dx - _kPlusRadius,
      top: position.dy - _kPlusRadius,
      child: _PlusButton(
        active: isActive,
        onTap: () => _addAlternative(termIndex),
      ),
    );
  }

  void _showSpacingOverlay(int leftIndex, int rightIndex) {
    final key = _spaceKey(leftIndex, rightIndex);
    debugPrint('🎈 Showing spacing overlay: $key');
    if (_spacingOverlays.containsKey(key)) {
      debugPrint('⚠️ Spacing overlay already exists: $key');
      return;
    }

    // בדיקה שהאינדקסים תקינים
    if (leftIndex >= _wordRightEdges.length ||
        rightIndex >= _wordLeftEdges.length) {
      return;
    }

    final overlayState = Overlay.of(context);
    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final textFieldGlobal = textFieldBox.localToGlobal(Offset.zero);
    final midpoint = Offset(
      (_wordRightEdges[leftIndex] + _wordLeftEdges[rightIndex]) / 2,
      _wordPositions[leftIndex].dy - _kSpacingYOffset,
    );
    final overlayPos = textFieldGlobal + midpoint;
    final controller = _spacingControllers.putIfAbsent(key, () {
      final newController = TextEditingController();
      // הוספת listener לעדכון המידע ב-tab כשהטקסט משתנה
      newController.addListener(() => _updateSpacingInTab());
      return newController;
    });
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: overlayPos.dx - 22.5, // מרכוז התיבה החדשה (45/2 = 22.5)
        top: overlayPos.dy - 50,
        child: _SpacingField(
          controller: controller,
          onRemove: () => _removeSpacingOverlay(key),
          onFocusLost: () => _removeSpacingOverlayIfEmpty(key),
        ),
      ),
    );
    _spacingOverlays[key] = entry;
    overlayState.insert(entry);
  }

  void _removeSpacingOverlay(String key) {
    _spacingOverlays[key]?.remove();
    _spacingOverlays.remove(key);
    _spacingControllers[key]?.dispose();
    _spacingControllers.remove(key);
    // עדכון המידע ב-tab אחרי הסרת המרווח
    _updateSpacingInTab();
  }

  void _removeSpacingOverlayIfEmpty(String key) {
    if (_spacingControllers[key]?.text.trim().isEmpty ?? true) {
      _removeSpacingOverlay(key);
    }
  }

  List<Widget> _buildSpacingButtons() {
    if (_wordPositions.length < 2) return [];

    List<Widget> buttons = [];
    for (int i = 0; i < _wordPositions.length - 1; i++) {
      final spacingX = (_wordRightEdges[i] + _wordLeftEdges[i + 1]) / 2;
      final spacingY = _wordPositions[i].dy - _kSpacingYOffset;

      final shouldShow = _hoveredWordIndex == i || _hoveredWordIndex == i + 1;
      if (shouldShow) {
        buttons.add(
          Positioned(
            left: spacingX - 10,
            top: spacingY,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredWordIndex = i),
              onExit: (_) => setState(() => _hoveredWordIndex = null),
              child: _SpacingButton(
                onTap: () => _showSpacingOverlay(i, i + 1),
              ),
            ),
          ),
        );
      }
    }
    return buttons;
  }

  void _showSearchOptionsOverlay() {
    if (_searchOptionsOverlay != null) return;

    final currentSelection = widget.widget.tab.queryController.selection;
    final overlayState = Overlay.of(context);
    final RenderBox? textFieldBox =
        _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (textFieldBox == null) return;
    final textFieldGlobalPosition = textFieldBox.localToGlobal(Offset.zero);

    _searchOptionsOverlay = OverlayEntry(
      builder: (context) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (PointerDownEvent event) {
            final clickPosition = event.position;
            final textFieldRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx,
              textFieldGlobalPosition.dy,
              textFieldBox.size.width,
              textFieldBox.size.height,
            );

            // אזור המגירה המשוער - אנחנו לא יודעים את הגובה המדויק אז ניקח טווח סביר
            final drawerRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx,
              textFieldGlobalPosition.dy + textFieldBox.size.height,
              textFieldBox.size.width,
              120.0, // גובה משוער מקסימלי לשתי שורות
            );

            if (!textFieldRect.contains(clickPosition) &&
                !drawerRect.contains(clickPosition)) {
              _hideSearchOptionsOverlay();
              _notifyDropdownClosed();
            }
          },
          child: Stack(
            children: [
              Positioned(
                left: textFieldGlobalPosition.dx,
                top: textFieldGlobalPosition.dy + textFieldBox.size.height,
                width: textFieldBox.size.width,
                // ======== התיקון מתחיל כאן ========
                child: AnimatedSize(
                  // 1. עוטפים ב-AnimatedSize
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: Container(
                    // height: 40.0, // 2. מסירים את הגובה הקבוע
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade400, width: 1),
                        right:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                        bottom:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          left: 48.0, right: 16.0, top: 8.0, bottom: 8.0),
                      child: _buildSearchOptionsContent(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    overlayState.insert(_searchOptionsOverlay!);

    // החזרת מיקום הסמן אחרי יצירת ה-overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.widget.tab.queryController.selection = currentSelection;
      }
    });

    // וידוא שה-overlay מוכן לקבל לחיצות
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ה-overlay כעת מוכן לקבל לחיצות
    });
  }

  // המילה הנוכחית (לפי מיקום הסמן)
  Map<String, dynamic>? _getCurrentWordInfo() {
    final text = widget.widget.tab.queryController.text;
    final cursorPosition =
        widget.widget.tab.queryController.selection.baseOffset;

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
        return {
          'word': word,
          'index': i,
          'start': wordStart,
          'end': wordEnd,
        };
      }

      currentPos = wordEnd;
    }

    return null;
  }

  Widget _buildSearchOptionsContent() {
    final wordInfo = _getCurrentWordInfo();

    // אם אין מילה נוכחית, נציג הודעה המתאימה
    if (wordInfo == null ||
        wordInfo['word'] == null ||
        wordInfo['word'].isEmpty) {
      return const Center(
        child: Text(
          'הקלד או הצב את הסמן על מילה כלשהיא, כדי לבחור אפשרויות חיפוש',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return _SearchOptionsContent(
      currentWord: wordInfo['word'],
      wordIndex: wordInfo['index'],
      wordOptions: widget.widget.tab.searchOptions,
      onOptionsChanged: _onSearchOptionsChanged,
      key: ValueKey(
          '${wordInfo['word']}_${wordInfo['index']}'), // מפתח ייחודי לעדכון
    );
  }

  void _hideSearchOptionsOverlay() {
    _searchOptionsOverlay?.remove();
    _searchOptionsOverlay = null;
  }

  void _notifyDropdownClosed() {
    // עדכון מצב הכפתור כשהמגירה נסגרת מבחוץ
    setState(() {
      // זה יגרום לעדכון של הכפתור ב-build
      // המצב יתעדכן דרך _isSearchOptionsVisible
    });
  }

  void _toggleSearchOptions(bool isExpanded) {
    if (isExpanded) {
      // פתיחת המגירה תמיד, ללא תלות בטקסט או מיקום הסמן
      _showSearchOptionsOverlay();
    } else {
      _hideSearchOptionsOverlay();
    }
  }

  bool get _isSearchOptionsVisible => _searchOptionsOverlay != null;

  void _onSearchOptionsChanged() {
    // עדכון התצוגה כשמשתמש משנה אפשרויות
    setState(() {
      // זה יגרום לעדכון של התצוגה
    });

    // עדכון ה-notifier כדי שהתצוגה של מילות החיפוש תתעדכן
    widget.widget.tab.searchOptionsChanged.value++;
  }

  void _updateAlternativeWordsInTab() {
    // עדכון המילים החילופיות ב-tab
    widget.widget.tab.alternativeWords.clear();
    for (int termIndex in _alternativeControllers.keys) {
      final alternatives = _alternativeControllers[termIndex]!
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();
      if (alternatives.isNotEmpty) {
        widget.widget.tab.alternativeWords[termIndex] = alternatives;
      }
    }
    // עדכון התצוגה
    widget.widget.tab.alternativeWordsChanged.value++;
    widget.widget.tab.searchOptionsChanged.value++;
  }

  void _updateSpacingInTab() {
    // עדכון המרווחים ב-tab
    widget.widget.tab.spacingValues.clear();
    for (String key in _spacingControllers.keys) {
      final spacingText = _spacingControllers[key]!.text.trim();
      if (spacingText.isNotEmpty) {
        widget.widget.tab.spacingValues[key] = spacingText;
      }
    }
    // עדכון התצוגה
    widget.widget.tab.searchOptionsChanged.value++;
    widget.widget.tab.spacingValuesChanged.value++;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<NavigationBloc, NavigationState>(
          listener: (context, state) {
            debugPrint('🔄 Navigation changed to: ${state.currentScreen}');

            // תמיד נקה בועות כשמשנים מסך - זה יפתור את הבאג
            // שבו בועות נשארות כשעוברים ממסך אחד לשני (לא דרך החיפוש)
            _clearAllOverlays();

            // אם עוזבים את מסך החיפוש - שמור נתונים
            if (state.currentScreen != Screen.search) {
              debugPrint('📤 Leaving search screen, saving data');
              _saveDataToTab();
            }
            // אם חוזרים למסך החיפוש - שחזר נתונים והצג בועות
            else if (state.currentScreen == Screen.search) {
              debugPrint('📥 Returning to search screen, restoring data');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _restoreDataFromTab(); // 1. שחזר את תוכן הבועות מהזיכרון
                // עיכוב נוסף כדי לוודא שהטקסט מעודכן
                Future.delayed(const Duration(milliseconds: 50), () {
                  // השאר את העיכוב הקטן הזה
                  if (mounted) {
                    _calculateWordPositions(); // 2. חשב מיקומים (עכשיו זה יעבוד)
                    _showRestoredBubbles(); // 3. הצג את הבועות המשוחזרות
                  }
                });
              });
            }
          },
        ),
        // הוספת listener לשינויי tabs - למקרה שהבעיה קשורה לכך
        BlocListener<TabsBloc, TabsState>(
          listener: (context, state) {
            debugPrint(
                '📑 Tabs changed - current tab index: ${state.currentTabIndex}');
            // אם עברנו לטאב שאינו search tab, נקה בועות
            if (state.currentTabIndex < state.tabs.length) {
              final currentTab = state.tabs[state.currentTabIndex];
              if (currentTab.runtimeType.toString() != 'SearchingTab') {
                debugPrint('📤 Switched to non-search tab, clearing overlays');
                _clearAllOverlays();
              }
            }
          },
        ),
      ],
      child: Stack(
        key: _stackKey,
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: _kSearchFieldMinWidth,
                  minHeight: _kControlHeight,
                ),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (KeyEvent event) {
                    // עדכון המגירה כשמשתמשים בחצים במקלדת
                    if (event is KeyDownEvent) {
                      final isArrowKey =
                          event.logicalKey.keyLabel == 'Arrow Left' ||
                              event.logicalKey.keyLabel == 'Arrow Right' ||
                              event.logicalKey.keyLabel == 'Arrow Up' ||
                              event.logicalKey.keyLabel == 'Arrow Down';

                      if (isArrowKey) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_searchOptionsOverlay != null) {
                            _updateSearchOptionsOverlay();
                          }
                        });
                      }
                    }
                  },
                  child: TextField(
                    key: _textFieldKey,
                    focusNode: widget.widget.tab.searchFieldFocusNode,
                    controller: widget.widget.tab.queryController,
                    onTap: () {
                      // עדכון המגירה כשלוחצים בשדה הטקסט
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_searchOptionsOverlay != null) {
                          _updateSearchOptionsOverlay();
                        }
                      });
                    },
                    onChanged: (text) {
                      // עדכון המגירה כשהטקסט משתנה
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_searchOptionsOverlay != null) {
                          _updateSearchOptionsOverlay();
                        }
                      });
                    },
                    onSubmitted: (e) {
                      context
                          .read<HistoryBloc>()
                          .add(AddHistory(widget.widget.tab));
                      context.read<SearchBloc>().add(UpdateSearchQuery(e,
                          customSpacing: widget.widget.tab.spacingValues,
                          alternativeWords: widget.widget.tab.alternativeWords,
                          searchOptions: widget.widget.tab.searchOptions));
                      widget.widget.tab.isLeftPaneOpen.value = false;
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: "חפש כאן..",
                      labelText: "לחיפוש הקש אנטר או לחץ על סמל החיפוש",
                      prefixIcon: IconButton(
                        onPressed: () {
                          context
                              .read<HistoryBloc>()
                              .add(AddHistory(widget.widget.tab));
                          context.read<SearchBloc>().add(UpdateSearchQuery(
                              widget.widget.tab.queryController.text,
                              customSpacing: widget.widget.tab.spacingValues,
                              alternativeWords:
                                  widget.widget.tab.alternativeWords,
                              searchOptions: widget.widget.tab.searchOptions));
                        },
                        icon: const Icon(Icons.search),
                      ),
                      // החלף את כל ה-Row הקיים בזה:
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BlocBuilder<SearchBloc, SearchState>(
                            builder: (context, state) {
                              if (!state.isAdvancedSearchEnabled)
                                return const SizedBox.shrink();
                              return IconButton(
                                onPressed: () => _toggleSearchOptions(
                                    !_isSearchOptionsVisible),
                                icon: const Icon(Icons.keyboard_arrow_down),
                                focusNode: FocusNode(
                                  // <-- התוספת המרכזית
                                  canRequestFocus:
                                      false, // מונע מהכפתור לבקש פוקוס
                                  skipTraversal: true, // מדלג עליו בניווט מקלדת
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              // ניקוי מלא של כל הנתונים
                              widget.widget.tab.queryController.clear();
                              widget.widget.tab.searchOptions.clear();
                              widget.widget.tab.alternativeWords.clear();
                              widget.widget.tab.spacingValues.clear();
                              _clearAllOverlays();
                              _disposeControllers();
                              setState(() {
                                _searchQuery = SearchQuery();
                                _wordPositions.clear();
                                _wordLeftEdges.clear();
                                _wordRightEdges.clear();
                              });
                              context
                                  .read<SearchBloc>()
                                  .add(UpdateSearchQuery(''));
                              // ניקוי ספירות הפאסטים
                              context
                                  .read<SearchBloc>()
                                  .add(UpdateFacetCounts({}));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // אזורי ריחוף על המילים - רק בחלק העליון
          ..._wordPositions.asMap().entries.map((entry) {
            final wordIndex = entry.key;
            final position = entry.value;
            return Positioned(
              left: position.dx - 30,
              top: position.dy - 47, // יותר למעלה כדי לא לחסום את שדה החיפוש
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredWordIndex = wordIndex),
                onExit: (_) => setState(() => _hoveredWordIndex = null),
                child: IgnorePointer(
                  child: Container(
                    width: 60,
                    height: 20, // גובה קטן יותר
                    color: Colors.transparent,
                  ),
                ),
              ),
            );
          }).toList(),
          // כפתורי ה+ (רק בחיפוש מתקדם)
          ..._wordPositions.asMap().entries.map((entry) {
            return _buildPlusButton(entry.key, entry.value);
          }).toList(),
          // כפתורי המרווח (רק בחיפוש מתקדם)
          ..._buildSpacingButtons(),
        ],
      ),
    );
  }
}

class _SearchOptionsContent extends StatefulWidget {
  final String currentWord;
  final int wordIndex;
  final Map<String, Map<String, bool>> wordOptions;
  final VoidCallback? onOptionsChanged;

  const _SearchOptionsContent({
    super.key,
    required this.currentWord,
    required this.wordIndex,
    required this.wordOptions,
    this.onOptionsChanged,
  });

  @override
  State<_SearchOptionsContent> createState() => _SearchOptionsContentState();
}

class _SearchOptionsContentState extends State<_SearchOptionsContent> {
  // רשימת האפשרויות הזמינות
  static const List<String> _availableOptions = [
    'קידומות',
    'סיומות',
    'קידומות דקדוקיות',
    'סיומות דקדוקיות',
    'כתיב מלא/חסר',
    'חלק ממילה',
  ];

  String get _wordKey => '${widget.currentWord}_${widget.wordIndex}';

  Map<String, bool> _getCurrentWordOptions() {
    // אם אין אפשרויות למילה הזו, ניצור אותן
    if (!widget.wordOptions.containsKey(_wordKey)) {
      widget.wordOptions[_wordKey] =
          Map.fromIterable(_availableOptions, value: (_) => false);
    }

    return widget.wordOptions[_wordKey]!;
  }

  Widget _buildCheckbox(String option) {
    final currentOptions = _getCurrentWordOptions();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: (details) {
          setState(() {
            currentOptions[option] = !currentOptions[option]!;
          });
          // עדכון מיידי של התצוגה
          widget.onOptionsChanged?.call();
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
                    height: 1.0,
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
    // נקודות ההכרעה לתצוגות שונות
    const double singleRowThreshold = 650.0; // רוחב מינימלי לשורה אחת
    const double threeColumnsThreshold = 450.0; // רוחב מינימלי ל-3 טורים

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // 1. אם המסך רחב מספיק - נשתמש ב-Wrap (שיראה כמו שורה אחת)
        if (availableWidth >= singleRowThreshold) {
          return Wrap(
            spacing: 16.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
            children: _availableOptions
                .map((option) => _buildCheckbox(option))
                .toList(),
          );
        }
        // 2. אם יש מקום ל-3 טורים - נחלק ל-3
        else if (availableWidth >= threeColumnsThreshold) {
          // מחלקים את רשימת האפשרויות לשלושה טורים
          final int itemsPerColumn = (_availableOptions.length / 3).ceil();
          final List<String> column1Options =
              _availableOptions.take(itemsPerColumn).toList();
          final List<String> column2Options = _availableOptions
              .skip(itemsPerColumn)
              .take(itemsPerColumn)
              .toList();
          final List<String> column3Options =
              _availableOptions.skip(itemsPerColumn * 2).toList();

          // פונקציית עזר לבניית עמודה
          Widget buildColumn(List<String> options) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: options
                  .map((option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: _buildCheckbox(option),
                      ))
                  .toList(),
            );
          }

          // מחזירים שורה שמכילה את שלושת הטורים
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildColumn(column1Options),
              buildColumn(column2Options),
              buildColumn(column3Options),
            ],
          );
        }
        // 3. אם המסך צר מדי - נעבור לתצוגת 2 טורים
        else {
          // מחלקים את רשימת האפשרויות לשתי עמודות
          final int middle = (_availableOptions.length / 2).ceil();
          final List<String> column1Options =
              _availableOptions.sublist(0, middle);
          final List<String> column2Options = _availableOptions.sublist(middle);

          // פונקציית עזר לבניית עמודה
          Widget buildColumn(List<String> options) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: options
                  .map((option) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: _buildCheckbox(option),
                      ))
                  .toList(),
            );
          }

          // מחזירים שורה שמכילה את שתי העמודות
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildColumn(column1Options),
              buildColumn(column2Options),
            ],
          );
        }
      },
    );
  }
}
