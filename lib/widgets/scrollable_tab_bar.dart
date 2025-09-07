import 'package:flutter/material.dart';

/// ווידג'ט TabBar עם חיצי ניווט כשיש יותר מדי טאבים
class ScrollableTabBarWithArrows extends StatefulWidget {
  final TabController controller;
  final List<Widget> tabs;
  final TabAlignment? tabAlignment;

  const ScrollableTabBarWithArrows({
    super.key,
    required this.controller,
    required this.tabs,
    this.tabAlignment,
  });

  @override
  State<ScrollableTabBarWithArrows> createState() =>
      _ScrollableTabBarWithArrowsState();
}

class _ScrollableTabBarWithArrowsState
    extends State<ScrollableTabBarWithArrows> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrowVisibility);
    // עדכון ראשוני אחרי שהווידג'ט נבנה
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateArrowVisibility();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrowVisibility() {
    if (!_scrollController.hasClients) {
      // אם אין עדיין ScrollController, נבדוק לפי מספר הטאבים
      final needsScrolling = widget.tabs.length > 4;
      if (mounted) {
        setState(() {
          _canScrollLeft = needsScrolling;
          _canScrollRight = needsScrolling;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _canScrollLeft = _scrollController.offset > 0;
        _canScrollRight = _scrollController.offset <
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  void _scrollLeft() {
    if (_scrollController.hasClients) {
      final newOffset = (_scrollController.offset - 150).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight() {
    if (_scrollController.hasClients) {
      final newOffset = (_scrollController.offset + 150).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        newOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // חץ שמאל
        AnimatedOpacity(
          opacity: _canScrollLeft ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            onPressed: _canScrollLeft ? _scrollLeft : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'גלול שמאלה',
          ),
        ),
        // TabBar עם ScrollController מותאם אישית
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: IntrinsicWidth(
              child: TabBar(
                controller: widget.controller,
                isScrollable: false, // כבה את הגלילה הפנימית של TabBar
                tabs: widget.tabs,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
          ),
        ),
        // חץ ימין
        AnimatedOpacity(
          opacity: _canScrollRight ? 1.0 : 0.3,
          duration: const Duration(milliseconds: 200),
          child: IconButton(
            onPressed: _canScrollRight ? _scrollRight : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            tooltip: 'גלול ימינה',
          ),
        ),
      ],
    );
  }
}
