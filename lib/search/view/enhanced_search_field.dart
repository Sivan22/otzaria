import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/models/search_terms_model.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/search/view/search_options_dropdown.dart';

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
                ? primaryColor // מצב מודגש: צבע מלא
                : primaryColor.withOpacity(0.5), // מצב רגיל: חצי שקוף
            shape: BoxShape.circle,
            boxShadow: [
              if (isHighlighted) // הוספת צל רק במצב מודגש
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
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

class _AlternativeField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onRemove;

  const _AlternativeField({
    super.key,
    required this.controller,
    required this.onRemove,
  });

  @override
  State<_AlternativeField> createState() => _AlternativeFieldState();
}

class _AlternativeFieldState extends State<_AlternativeField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // הבקשה הראשונית לפוקוס כשהשדה נוצר
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focus.requestFocus();
      }
    });
    _focus.addListener(_handleFocus);
  }

  void _handleFocus() {
    // איבוד / קבלת פוקוס משפיע רק על “עמעום”
    setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_handleFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dim =
        !_focus.hasFocus && widget.controller.text.trim().isNotEmpty;

    return Material(
      elevation: _focus.hasFocus ? 8 : 2,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.hardEdge, // ☑ לא מאפשר לקו לרוץ “מאחורי” הרקע
      color: Colors.white, // ☑ רקע לבן אטום
      child: SizedBox(
        width: 160, // טיפה רחב – הסתרת קו במלואו
        height: 40,
        child: TextField(
          controller: widget.controller,
          focusNode: _focus,
          decoration: InputDecoration(
            filled: true, // ☑ שכבת מילוי פנימית
            fillColor: Colors.white,
            hintText: 'מילה חילופית',
            hintStyle: TextStyle(
              fontSize: 12,
              color: dim ? Colors.black45 : Colors.black54,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                    Theme.of(context).dividerColor.withOpacity(dim ? 0.4 : 1.0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color:
                    Theme.of(context).dividerColor.withOpacity(dim ? 0.4 : 1.0),
              ),
            ),
            suffixIcon: Material(
              // ☑ ריפל ברור סביב ה‑X
              type: MaterialType.transparency,
              shape: const CircleBorder(),
              child: InkResponse(
                splashFactory: InkRipple.splashFactory,
                onTap: widget.onRemove,
                customBorder: const CircleBorder(),
                splashColor: Theme.of(context).primaryColor.withOpacity(0.25),
                highlightColor:
                    Theme.of(context).primaryColor.withOpacity(0.12),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: dim ? Colors.black45 : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 12,
            color: dim ? Colors.black54 : Colors.black87,
          ),
          textAlign: TextAlign.right,
          onSubmitted: (_) {
            if (widget.controller.text.trim().isEmpty) {
              widget.onRemove();
            }
          },
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
  final Map<int, List<bool>> _showAlternativeFields = {};

  static const double _kInnerPadding = 12; // padding סטנדרטי של TextField
  static const double _kSuffixWidth = 100; // רוחב suffixIcon (תפריט + clear)
  static const double _kPlusYOffset = 10; // כמה פיקסלים מתחת לשדה יופיע ה +
  static const double _kPlusRadius = 10; // רדיוס העיגול (למרכז-top)

  @override
  void initState() {
    super.initState();
    widget.widget.tab.queryController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateWordPositionsSimple();
    });
  }

  @override
  void dispose() {
    widget.widget.tab.queryController.removeListener(_onTextChanged);
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controllers in _alternativeControllers.values) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    _alternativeControllers.clear();
    _showAlternativeFields.clear();
  }

  void _onTextChanged() {
    final text = widget.widget.tab.queryController.text;
    setState(() {
      _searchQuery = SearchQuery.fromString(text);
      _updateAlternativeControllers();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateWordPositionsSimple();
    });
  }

  void _updateAlternativeControllers() {
    _disposeControllers();

    for (int i = 0; i < _searchQuery.terms.length; i++) {
      _alternativeControllers[i] = [];
      _showAlternativeFields[i] = [];

      final term = _searchQuery.terms[i];
      for (int j = 0; j < term.alternatives.length; j++) {
        _alternativeControllers[i]!
            .add(TextEditingController(text: term.alternatives[j]));
        _showAlternativeFields[i]!.add(true);
      }
    }
  }

  void _calculateWordPositionsSimple() {
    if (_textFieldKey.currentContext == null) return;

    // 1. מאתרים את RenderEditable שבתוך ה‑TextField
    RenderEditable? editable;
    void _findEditable(RenderObject child) {
      if (child is RenderEditable) {
        editable = child;
      } else {
        child.visitChildren(_findEditable);
      }
    }

    _textFieldKey.currentContext!
        .findRenderObject()!
        .visitChildren(_findEditable);
    if (editable == null) return;

    // 2. קואורדינטות בסיס
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final stackGlobal = stackBox.localToGlobal(Offset.zero);

    _wordPositions.clear();

    final text = widget.widget.tab.queryController.text;
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    // 3. עבור כל מילה – מוצאים את Rect שלה בעזרת getEndpointsForSelection
    final words = text.trim().split(RegExp(r'\s+'));
    int currentIndex = 0;
    for (final word in words) {
      final wordStart = text.indexOf(word, currentIndex);
      if (wordStart == -1) continue; // הגנה
      final wordEnd = wordStart + word.length;

      final endpoints = editable!.getEndpointsForSelection(
          TextSelection(baseOffset: wordStart, extentOffset: wordEnd));
      if (endpoints.length < 2) continue;

      final left = endpoints[0].point.dx;
      final right = endpoints[1].point.dx;
      final centerLocal = Offset(
        (left + right) / 2,
        editable!.size.height + _kPlusYOffset,
      );

      // 4. המרה לקואורדינטות של ה‑Stack
      final centerGlobal = editable!.localToGlobal(centerLocal);
      final centerInStack = centerGlobal - stackGlobal;

      _wordPositions.add(centerInStack);
      currentIndex = wordEnd + 1;
    }

    setState(() {});
  }

  void _calculateWordPositions() {
    if (_textFieldKey.currentContext == null) return;

    final renderBox =
        _textFieldKey.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _wordPositions.clear();

    final text = widget.widget.tab.queryController.text;
    if (text.isEmpty) {
      setState(() {}); // נקה את הכפתורים אם אין טקסט
      return;
    }

    final words = text.trim().split(RegExp(r'\s+'));
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null) return;
    final stackOffset = stackBox.localToGlobal(Offset.zero);

    // נשתמש באותו סגנון טקסט כמו ב-TextField
    const textStyle = TextStyle(fontSize: 16); // גודל ברירת מחדל של TextField

    final tpWord = TextPainter(textDirection: TextDirection.rtl);
    final tpSpace = TextPainter(
      text: const TextSpan(text: ' ', style: textStyle),
      textDirection: TextDirection.rtl,
    )..layout();
    final spaceWidth = tpSpace.size.width;

    // התחל מהצד הימני, אחרי הכפתורים (suffixIcon)
    double cursorX = renderBox.size.width - _kSuffixWidth - _kInnerPadding;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      tpWord
        ..text = TextSpan(text: word, style: textStyle)
        ..layout();

      // מרכז המילה = תחילת המילה + חצי רוחב
      // מוסיפים חצי רווח קודם (space/2) כדי לקבל “אמצע אופטי” מדויק ב‑RTL
      final centerX = cursorX - tpWord.size.width / 2 + spaceWidth / 2;

      final globalCenter = Offset(
        renderBox.localToGlobal(Offset(centerX, 0)).dx,
        renderBox.localToGlobal(Offset.zero).dy +
            renderBox.size.height +
            _kPlusYOffset,
      );

      _wordPositions.add(globalCenter - stackOffset);

      // זזים אחורה: מילה + רווח, חוץ מהשמאלית‑ביותר (האחרונה בלולאה)
      cursorX -= tpWord.size.width;
      if (i < words.length - 1) {
        cursorX -= spaceWidth;
      }
    }

    setState(() {});
  }

  void _addAlternative(int termIndex) {
    if (termIndex >= _searchQuery.terms.length) return;

    setState(() {
      // 1️⃣ קודם כול – נקה תיבות ריקות בכל המילים
      _alternativeControllers.forEach((ti, list) {
        for (int i = list.length - 1; i >= 0; i--) {
          if (list[i].text.trim().isEmpty) {
            list[i].dispose();
            list.removeAt(i);
            _showAlternativeFields[ti]?.removeAt(i);
          }
        }
      });

      // 2️⃣ הוסף תיבה חדשה למילה הנוכחית
      _alternativeControllers.putIfAbsent(termIndex, () => []);
      _showAlternativeFields.putIfAbsent(termIndex, () => []);

      _alternativeControllers[termIndex]!.add(TextEditingController());
      _showAlternativeFields[termIndex]!.add(true);
    });
  }

  void _removeAlternative(int termIndex, int altIndex) {
    setState(() {
      if (_alternativeControllers[termIndex] != null &&
          altIndex < _alternativeControllers[termIndex]!.length) {
        // עדכון המודל לפני הסרת הקונטרולר
        final term = _searchQuery.terms[termIndex];
        final updatedTerm = term.removeAlternative(altIndex);
        _searchQuery = _searchQuery.updateTerm(termIndex, updatedTerm);

        // הסרת הקונטרולר והשדה
        _alternativeControllers[termIndex]![altIndex].dispose();
        _alternativeControllers[termIndex]!.removeAt(altIndex);
        _showAlternativeFields[termIndex]!.removeAt(altIndex);
      }
    });
  }

  Widget _buildPlusButton(int termIndex, Offset position) {
    // הכפתור "פעיל" אם יש לו לפחות שדה חלופי אחד פתוח.
    final bool isActive =
        _alternativeControllers[termIndex]?.isNotEmpty ?? false;

    return Positioned(
      left: position.dx - _kPlusRadius,
      top: position.dy - _kPlusRadius,
      // שימוש בווידג'ט החדש
      child: _PlusButton(
        active: isActive,
        onTap: () => _addAlternative(termIndex),
      ),
    );
  }

  Widget _buildAlternativeField(int termIndex, int altIndex) {
    final controller = _alternativeControllers[termIndex]?[altIndex];
    if (controller == null) return const SizedBox.shrink();

    final wordPos = _wordPositions.length > termIndex
        ? _wordPositions[termIndex]
        : Offset.zero;

    final topPosition = (wordPos.dy + 22) + (altIndex * 45.0);

    return Positioned(
      left: wordPos.dx - 75,
      top: topPosition,
      child: _AlternativeField(
        controller: controller,
        onRemove: () => _removeAlternative(termIndex, altIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _stackKey,
      clipBehavior: Clip.none,
      children: [
        // השדה הראשי - בגובה רגיל
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            key: _textFieldKey,
            focusNode: widget.widget.tab.searchFieldFocusNode,
            controller: widget.widget.tab.queryController,
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
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SearchOptionsDropdown(),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.widget.tab.queryController.clear();
                      context.read<SearchBloc>().add(UpdateSearchQuery(''));
                      setState(() {
                        _searchQuery = SearchQuery();
                        _updateAlternativeControllers();
                        _wordPositions.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // כפתורי הפלוס - צפים מעל השדה
        ..._wordPositions.asMap().entries.map((entry) {
          final index = entry.key;
          final position = entry.value;
          if (index < _searchQuery.terms.length) {
            return _buildPlusButton(index, position);
          }
          return const SizedBox.shrink();
        }).toList(),

        // שדות חילופיים - צפים מתחת לשדה
        ..._alternativeControllers.entries.expand((entry) {
          final termIndex = entry.key;
          final controllers = entry.value;

          return controllers.asMap().entries.map((controllerEntry) {
            final altIndex = controllerEntry.key;
            return _buildAlternativeField(termIndex, altIndex);
          });
        }).toList(),
      ],
    );
  }
}
