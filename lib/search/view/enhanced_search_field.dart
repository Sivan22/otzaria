import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/models/search_terms_model.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';

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
    // הוספת listener לשינויי טקסט כדי לעדכן את ה-opacity
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // עדכון המצב לשינוי opacity
  }

  void _onFocusChanged() {
    setState(() {});

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
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    final bool isInactive = !_focus.hasFocus && hasText;

    return AnimatedOpacity(
      opacity: isInactive ? 0.5 : 1.0, // חצי שקופה כשלא בפוקוס ויש טקסט
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 45, // הצרה משמעותית מ-65 ל-45 (מתאים ל-2 ספרות)
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focus.hasFocus
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: _focus.hasFocus ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: _focus.hasFocus ? 0.15 : 0.08),
              blurRadius: _focus.hasFocus ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
                    hintText: 'מרווח',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: 4, bottom: 4),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
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
    // הוספת listener לשינויי טקסט כדי לעדכן את ה-opacity
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // עדכון המצב לשינוי opacity
  }

  void _onFocusChanged() {
    setState(() {});

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
    final bool hasText = widget.controller.text.trim().isNotEmpty;
    final bool isInactive = !_focus.hasFocus && hasText;

    return AnimatedOpacity(
      opacity: isInactive ? 0.5 : 1.0, // חצי שקופה כשלא בפוקוס ויש טקסט
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 70, // הצרה עוד יותר - מ-120 ל-100
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _focus.hasFocus
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: _focus.hasFocus ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: _focus.hasFocus ? 0.15 : 0.08),
              blurRadius: _focus.hasFocus ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
                    // הגבלה למילה אחת - מניעת רווחים
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'מילה חילופית',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(right: 4, bottom: 4),
                  ),
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
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
  void dispose() {
    _clearAllOverlays();
    widget.widget.tab.queryController.removeListener(_onTextChanged);
    widget.widget.tab.searchFieldFocusNode
        .removeListener(_onCursorPositionChanged);
    _disposeControllers();
    // ניקוי אפשרויות החיפוש כשסוגרים את המסך
    widget.widget.tab.searchOptions.clear();
    super.dispose();
  }

  void _clearAllOverlays({bool keepSearchDrawer = false}) {
    // ניקוי אלטרנטיבות ומרווחים
    for (final entries in _alternativeOverlays.values) {
      for (final entry in entries) {
        entry.remove();
      }
    }
    _alternativeOverlays.clear();

    for (final entry in _spacingOverlays.values) {
      entry.remove();
    }
    _spacingOverlays.clear();

    // סגירת מגירת האפשרויות רק אם לא ביקשנו לשמור אותה
    if (!keepSearchDrawer) {
      _searchOptionsOverlay?.remove();
      _searchOptionsOverlay = null;
    }
  }

  void _disposeControllers() {
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
  }

  void _onTextChanged() {
    // בודקים אם המגירה הייתה פתוחה לפני השינוי
    final bool drawerWasOpen = _searchOptionsOverlay != null;

    // מנקים את כל הבועות, אבל משאירים את המגירה פתוחה אם היא הייתה פתוחה
    _clearAllOverlays(keepSearchDrawer: drawerWasOpen);

    final text = widget.widget.tab.queryController.text;

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

      for (int i = 0; i < _searchQuery.terms.length; i++) {
        for (int j = 0; j < _searchQuery.terms[i].alternatives.length; j++) {
          _showAlternativeOverlay(i, j);
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
      _hideSearchOptionsOverlay();
      _showSearchOptionsOverlay();
    }
  }

  void _updateAlternativeControllers() {
    _disposeControllers();
    for (int i = 0; i < _searchQuery.terms.length; i++) {
      final term = _searchQuery.terms[i];
      _alternativeControllers[i] = term.alternatives.map((alt) {
        final controller = TextEditingController(text: alt);
        // הוספת listener לעדכון המידע ב-tab כשהטקסט משתנה
        controller.addListener(() => _updateAlternativeWordsInTab());
        return controller;
      }).toList();
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
    if (_spacingOverlays.containsKey(key)) return;
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
            // בדיקה אם הלחיצה היא מחוץ לאזור שדה החיפוש והמגירה
            final clickPosition = event.position;

            // אזור שדה החיפוש (מורחב כדי לכלול את כל האזור כולל הכפתורים)
            final textFieldRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx - 20, // מרווח נוסף משמאל
              textFieldGlobalPosition.dy - 20, // מרווח נוסף מלמעלה
              textFieldBox.size.width + 40, // רוחב מורחב יותר
              textFieldBox.size.height + 40, // גובה מורחב יותר
            );

            // אזור המגירה (מורחב מעט)
            final drawerRect = Rect.fromLTWH(
              textFieldGlobalPosition.dx - 10,
              textFieldGlobalPosition.dy + textFieldBox.size.height - 5,
              textFieldBox.size.width + 20,
              50.0, // גובה מורחב
            );

            // אם הלחיצה מחוץ לשני האזורים, סגור את המגירה
            if (!textFieldRect.contains(clickPosition) &&
                !drawerRect.contains(clickPosition)) {
              _hideSearchOptionsOverlay();
              _notifyDropdownClosed();
            }
          },
          child: Stack(
            children: [
              // המגירה עצמה
              Positioned(
                left: textFieldGlobalPosition.dx,
                top: textFieldGlobalPosition.dy + textFieldBox.size.height,
                width: textFieldBox.size.width,
                child: Container(
                  height: 40.0,
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
                      right: BorderSide(color: Colors.grey.shade400, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                  ),
                  child: Material(
                    color: Theme.of(context).scaffoldBackgroundColor,
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

    // אם אין מילה נוכחית, נציג הודעה
    if (wordInfo == null ||
        wordInfo['word'] == null ||
        wordInfo['word'].isEmpty) {
      final text = widget.widget.tab.queryController.text;
      final message = text.trim().isEmpty
          ? 'הקלד טקסט ומקם את הסמן על מילה לבחירת אפשרויות'
          : 'מקם את הסמן על מילה לבחירת אפשרויות';

      return Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      // בדיקה שיש טקסט בשדה החיפוש ושהסמן על מילה
      final text = widget.widget.tab.queryController.text.trim();
      final wordInfo = _getCurrentWordInfo();

      if (text.isNotEmpty &&
          wordInfo != null &&
          wordInfo['word'] != null &&
          wordInfo['word'].isNotEmpty) {
        _showSearchOptionsOverlay();
      } else {
        // אם אין טקסט או הסמן לא על מילה, עדכן את המצב של הכפתור
        setState(() {
          // זה יגרום לכפתור לחזור למצב לא לחוץ
        });

        // הצגת הודעה קצרה למשתמש (אופציונלי)
        if (text.isEmpty) {
          // יכול להוסיף כאן הודעה שצריך להקליד טקסט
        } else {
          // יכול להוסיף כאן הודעה שצריך למקם את הסמן על מילה
        }
      }
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
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                    context.read<SearchBloc>().add(UpdateSearchQuery(e));
                    widget.widget.tab.isLeftPaneOpen.value = false;
                  },
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: "חפש כאן..",
                    labelText: "לחיפוש הקש אנטר או לחץ על סמל החיפוש",
                    prefixIcon: IconButton(
                      onPressed: () {
                        context.read<SearchBloc>().add(UpdateSearchQuery(
                            widget.widget.tab.queryController.text));
                      },
                      icon: const Icon(Icons.search),
                    ),
                    // החלף את כל ה-Row הקיים בזה:
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.widget.tab.isAdvancedSearchEnabled)
                          IconButton(
                            onPressed: () =>
                                _toggleSearchOptions(!_isSearchOptionsVisible),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            focusNode: FocusNode(
                              // <-- התוספת המרכזית
                              canRequestFocus: false, // מונע מהכפתור לבקש פוקוס
                              skipTraversal: true, // מדלג עליו בניווט מקלדת
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.widget.tab.queryController.clear();
                            context
                                .read<SearchBloc>()
                                .add(UpdateSearchQuery(''));
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
        if (widget.widget.tab.isAdvancedSearchEnabled)
          ..._wordPositions.asMap().entries.map((entry) {
            return _buildPlusButton(entry.key, entry.value);
          }).toList(),
        // כפתורי המרווח (רק בחיפוש מתקדם)
        if (widget.widget.tab.isAdvancedSearchEnabled)
          ..._buildSpacingButtons(),
      ],
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
    'שורש',
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

    return InkWell(
      onTap: () {
        setState(() {
          currentOptions[option] = !currentOptions[option]!;
        });
        // עדכון מיידי של התצוגה
        widget.onOptionsChanged?.call();
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
                  height: 1.0,
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
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children:
          _availableOptions.map((option) => _buildCheckbox(option)).toList(),
    );
  }
}
