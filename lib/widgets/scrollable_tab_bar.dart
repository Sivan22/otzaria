import 'package:flutter/material.dart';

/// TabBar הניתן לגלילה עם חיצים (בהשראת אקסל).
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
  // נשתמש ב־ScrollPosition הפנימי של ה-TabBar (isScrollable:true)
  ScrollPosition? _tabBarPosition;
  BuildContext? _scrollContext;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

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
    // נאמץ רק ScrollPosition אופקי, כדי לא לגלול את כל המסך בטעות
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
    }
  }

  void _scrollBy(double delta) {
    final pos = _tabBarPosition;
    if (pos == null) return;
    final target = (pos.pixels + delta)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent);
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
        // TabBar במצב isScrollable כדי לייצר גלילה רוחבית פנימית
        Expanded(
          child: NotificationListener<ScrollMetricsNotification>(
            onNotification: (metricsNotification) {
              final metrics = metricsNotification.metrics;
              // נאתחל אוטומטית מיד כשהמידות זמינות (גם בלי גלילה ידנית)
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
                  // לאמץ את ה-ScrollPosition האופקי מתוך ההודעה
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
                  // נשמור הקשר פנימי כדי לאתחל את ה-ScrollPosition אחרי הפריים
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
                  );
                },
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
