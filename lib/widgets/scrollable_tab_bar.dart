import 'package:flutter/material.dart';

/// TabBar גלילה עם חיצים לשמאל/ימין.
class ScrollableTabBarWithArrows extends StatefulWidget {
  final TabController controller;
  final List<Widget> tabs;
  final TabAlignment? tabAlignment;
  // מאפשר לדעת אם יש גלילה אופקית (יש Overflow)
  final ValueChanged<bool>? onOverflowChanged;

  const ScrollableTabBarWithArrows({
    super.key,
    required this.controller,
    required this.tabs,
    this.tabAlignment,
    this.onOverflowChanged,
  });

  @override
  State<ScrollableTabBarWithArrows> createState() =>
      _ScrollableTabBarWithArrowsState();
}

class _ScrollableTabBarWithArrowsState
    extends State<ScrollableTabBarWithArrows> {
  // נאתר את ה-ScrollPosition של ה-TabBar (isScrollable:true)
  ScrollPosition? _tabBarPosition;
  BuildContext? _scrollContext;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool? _lastOverflow;

  @override
  void dispose() {
    _detachPositionListener();
    super.dispose();
  }

  void _detachPositionListener() {
    _tabBarPosition?.removeListener(_onPositionChanged);
  }

  void _attachAndSyncPosition() {
    if (!mounted || _scrollContext == null) return;
    _adoptPositionFrom(_scrollContext!);
  }

  void _adoptPositionFrom(BuildContext ctx) {
    final state = Scrollable.of(ctx);
    final newPos = state?.position;
    if (newPos == null) return;
    // וידוא שמדובר בציר אופקי
    final isHorizontal = newPos.axisDirection == AxisDirection.left ||
        newPos.axisDirection == AxisDirection.right;
    if (!isHorizontal) return;
    if (!identical(newPos, _tabBarPosition)) {
      _detachPositionListener();
      _tabBarPosition = newPos;
      _tabBarPosition!.addListener(_onPositionChanged);
    }
    _onPositionChanged();
  }

  void _onPositionChanged() {
    final pos = _tabBarPosition;
    if (pos == null) return;
    final canLeft = pos.pixels > pos.minScrollExtent + 0.5;
    final canRight = pos.pixels < pos.maxScrollExtent - 0.5;
    if (_canScrollLeft != canLeft || _canScrollRight != canRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
      _emitOverflowIfChanged();
    }
  }

  void _handleScrollMetrics(ScrollMetrics metrics) {
    final canLeft = metrics.pixels > metrics.minScrollExtent + 0.5;
    final canRight = metrics.pixels < metrics.maxScrollExtent - 0.5;
    if (_canScrollLeft != canLeft || _canScrollRight != canRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
      _emitOverflowIfChanged();
    }
  }

  void _emitOverflowIfChanged() {
    final overflow = _canScrollLeft || _canScrollRight;
    if (_lastOverflow != overflow) {
      _lastOverflow = overflow;
      widget.onOverflowChanged?.call(overflow);
    }
  }

  void _scrollBy(double delta) {
    final pos = _tabBarPosition;
    if (pos == null) return;
    final target =
        (pos.pixels + delta).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    pos.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _scrollLeft() => _scrollBy(-150);
  void _scrollRight() => _scrollBy(150);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // חץ שמאלי – משמרים מקום קבוע כדי למנוע קפיצות ברוחב
        SizedBox(
          width: 36,
          height: 32,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _canScrollLeft ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_canScrollLeft,
              child: IconButton(
                key: const ValueKey('left-arrow'),
                onPressed: _scrollLeft,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'גלול שמאלה',
              ),
            ),
          ),
        ),
        // TabBar עם isScrollable – לוכדים נוטיפיקציות כדי לדעת אם יש Overflow
        Expanded(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (metricsNotification) {
              final metrics = metricsNotification.metrics;
              if (metrics.axis == Axis.horizontal) {
                final ctx = metricsNotification.context;
                if (ctx != null) _adoptPositionFrom(ctx);
                _handleScrollMetrics(metrics);
              }
              return false;
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.axis == Axis.horizontal) {
                  final ctx = notification.context;
                  if (ctx != null) {
                    _adoptPositionFrom(ctx);
                  }
                  _handleScrollMetrics(notification.metrics);
                }
                return false;
              },
              child: Builder(
                builder: (scrollCtx) {
                  // נשמור context כדי לאמץ את ה-ScrollPosition לאחר הבניה
                  if (!identical(_scrollContext, scrollCtx)) {
                    _scrollContext = scrollCtx;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _attachAndSyncPosition();
                    });
                  }
                  return TabBar(
                    controller: widget.controller,
                    isScrollable: true,
                    tabs: widget.tabs,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabAlignment: widget.tabAlignment,
                    padding: EdgeInsets.zero,
                    // לא רוצים קו מפריד מתחת ל-TabBar בתוך ה-AppBar
                    dividerColor: Colors.transparent,
                    // הזזת האינדיקטור מעט, כדי שייראה נקי ב-AppBar
                    indicatorPadding: const EdgeInsets.only(bottom: -0),
                  );
                },
              ),
            ),
          ),
        ),
        // חץ ימני – משמרים מקום קבוע כדי למנוע קפיצות ברוחב
        SizedBox(
          width: 36,
          height: 32,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _canScrollRight ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_canScrollRight,
              child: IconButton(
                key: const ValueKey('right-arrow'),
                onPressed: _scrollRight,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                tooltip: 'גלול ימינה',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
