import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ProgressiveScrollWrapper extends StatefulWidget {
  final Widget child;
  final ScrollOffsetController scrollController;
  final double maxSpeed;
  final double acceleration;

  ProgressiveScrollWrapper({
    Key? key,
    required this.child,
    required this.scrollController,
    this.maxSpeed = 50.0,
    this.acceleration = 0.5,
  }) : super(key: key);

  @override
  _ProgressiveScrollWrapperState createState() =>
      _ProgressiveScrollWrapperState();
}

class _ProgressiveScrollWrapperState extends State<ProgressiveScrollWrapper> {
  double _scrollSpeed = 0;
  bool _isKeyPressed = false;
  int _scrollDirection = 0; // 1 for down, -1 for up, 0 for no scroll

  @override
  void initState() {
    super.initState();
    _startScrolling();
  }

  void _startScrolling() {
    Future.delayed(Duration(milliseconds: 16), () {
      if (_isKeyPressed) {
        _scrollSpeed = (_scrollSpeed + widget.acceleration * _scrollDirection)
            .clamp(-widget.maxSpeed, widget.maxSpeed);
        print('scroll speed: $_scrollSpeed');
      } else {
        _scrollSpeed = 0;
      }

      if (_scrollSpeed != 0) {
        widget.scrollController.animateScroll(
          offset: _scrollSpeed,
          duration: const Duration(milliseconds: 16),
        );
      }

      if (mounted) {
        _startScrolling();
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _isKeyPressed = true;
        _scrollDirection = 1;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _isKeyPressed = true;
        _scrollDirection = -1;
      }
    } else if (event is KeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _isKeyPressed = false;
        _scrollDirection = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: widget.child,
    );
  }
}
