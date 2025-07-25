import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_event.dart';
import 'package:otzaria/search/models/search_terms_model.dart';
import 'package:otzaria/search/view/tantivy_full_text_search.dart';
import 'package:otzaria/search/view/search_options_dropdown.dart';

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
  static const double _kPlusYOffset = 15; // כמה פיקסלים מתחת לשדה יופיע ה +
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

    final renderBox = _textFieldKey.currentContext!.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _wordPositions.clear();

    final text = widget.widget.tab.queryController.text;
    if (text.isEmpty) {
      setState(() {});
      return;
    }

    final words = text.trim().split(RegExp(r'\s+'));
    const textStyle = TextStyle(fontSize: 16);

    // גישה חדשה: נשתמש ב-getPositionForOffset כדי למצוא את המיקום המדויק של כל מילה
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.rtl,
    )..layout();

    final fieldWidth = renderBox.size.width;
    final textStartX = _kInnerPadding + 48; // אחרי prefixIcon
    final availableWidth = fieldWidth - textStartX - _kSuffixWidth - _kInnerPadding;
    
    // מיקום הטקסט בשדה (RTL)
    final textX = textStartX + (availableWidth - textPainter.size.width);

    // עכשיו נמצא את המיקום של כל מילה
    int currentIndex = 0;
    
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      
      // מצא את תחילת המילה בטקסט
      final wordStart = text.indexOf(word, currentIndex);
      final wordEnd = wordStart + word.length;
      
      // השתמש ב-getOffsetForCaret כדי למצוא את המיקום הפיזי
      final startOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: wordStart),
        Rect.zero,
      );
      final endOffset = textPainter.getOffsetForCaret(
        TextPosition(offset: wordEnd),
        Rect.zero,
      );
      
      // מרכז המילה
      final wordCenterX = textX + (startOffset.dx + endOffset.dx) / 2;
      
      _wordPositions.add(Offset(
        wordCenterX,
        renderBox.size.height + _kPlusYOffset,
      ));
      
      currentIndex = wordEnd + 1; // +1 לרווח
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
    if (termIndex < _searchQuery.terms.length) {
      setState(() {
        if (_alternativeControllers[termIndex] == null) {
          _alternativeControllers[termIndex] = [];
          _showAlternativeFields[termIndex] = [];
        }

        _alternativeControllers[termIndex]!.add(TextEditingController());
        _showAlternativeFields[termIndex]!.add(true);
      });
    }
  }

  void _removeAlternative(int termIndex, int altIndex) {
    setState(() {
      if (_alternativeControllers[termIndex] != null &&
          altIndex < _alternativeControllers[termIndex]!.length) {
        _alternativeControllers[termIndex]![altIndex].dispose();
        _alternativeControllers[termIndex]!.removeAt(altIndex);
        _showAlternativeFields[termIndex]!.removeAt(altIndex);

        // עדכן את המודל
        final term = _searchQuery.terms[termIndex];
        final updatedTerm = term.removeAlternative(altIndex);
        _searchQuery = _searchQuery.updateTerm(termIndex, updatedTerm);
      }
    });
  }

  Widget _buildPlusButton(int termIndex, Offset position) {
    return Positioned(
      left: position.dx - _kPlusRadius,
      top: position.dy - _kPlusRadius,
      child: GestureDetector(
        onTap: () => _addAlternative(termIndex),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
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

  Widget _buildAlternativeField(int termIndex, int altIndex, double topOffset) {
    final controller = _alternativeControllers[termIndex]?[altIndex];
    if (controller == null) return const SizedBox.shrink();

    // חישוב מיקום נכון עבור RTL
    final wordPosition = _wordPositions.length > termIndex
        ? _wordPositions[termIndex]
        : Offset.zero;

    return Positioned(
      right: MediaQuery.of(context).size.width -
          wordPosition.dx -
          75, // RTL positioning
      top: topOffset,
      child: Container(
        width: 150,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'מילה חילופית',
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () => _removeAlternative(termIndex, altIndex),
            ),
          ),
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.right, // RTL text alignment
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              setState(() {
                final term = _searchQuery.terms[termIndex];
                final updatedTerm = term.addAlternative(value);
                _searchQuery = _searchQuery.updateTerm(termIndex, updatedTerm);
              });
            }
          },
        ),
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

          // חשב כמה שדות פעילים יש כבר למילה הזו
          int activeFieldsCount = 0;
          for (int i = 0; i < controllers.length; i++) {
            if (controllers[i].text.isNotEmpty ||
                (_showAlternativeFields[termIndex]?[i] == true)) {
              activeFieldsCount++;
            }
          }

          return controllers.asMap().entries.where((controllerEntry) {
            final altIndex = controllerEntry.key;
            final controller = controllerEntry.value;

            // הצג שדה אם:
            // 1. יש בו תוכן
            // 2. הוא השדה הפעיל הבא (רק אחד ריק בכל פעם)
            if (controller.text.isNotEmpty) return true;
            if (_showAlternativeFields[termIndex]?[altIndex] == true &&
                altIndex == activeFieldsCount - 1) return true;

            return false;
          }).map((controllerEntry) {
            final altIndex = controllerEntry.key;
            final topOffset = 70.0 + (altIndex * 40.0); // מיקום אנכי
            return _buildAlternativeField(termIndex, altIndex, topOffset);
          });
        }).toList(),
      ],
    );
  }
}
