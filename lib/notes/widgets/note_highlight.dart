import 'package:flutter/material.dart';
import '../models/note.dart';
import '../config/notes_config.dart';

/// Widget for highlighting text that has notes attached
class NoteHighlight extends StatefulWidget {
  final Note note;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  const NoteHighlight({
    super.key,
    required this.note,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  State<NoteHighlight> createState() => _NoteHighlightState();
}

class _NoteHighlightState extends State<NoteHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get highlight color based on note status
  Color _getHighlightColor(BuildContext context) {
    if (!widget.enabled || !NotesConfig.highlightEnabled) {
      return Colors.transparent;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = switch (widget.note.status) {
      NoteStatus.anchored => colorScheme.primary,
      NoteStatus.shifted => _getWarningColor(context),
      NoteStatus.orphan => colorScheme.error,
    };

    final opacity = _isHovered ? 0.3 : 0.15;
    return baseColor.withValues(alpha: opacity);
  }

  /// Get warning color (orange-ish)
  Color _getWarningColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF9800)
        : const Color(0xFFFF6F00);
  }

  /// Get status indicator color
  Color _getStatusIndicatorColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (widget.note.status) {
      NoteStatus.anchored => colorScheme.primary,
      NoteStatus.shifted => _getWarningColor(context),
      NoteStatus.orphan => colorScheme.error,
    };
  }

  /// Get status icon
  IconData _getStatusIcon() {
    return switch (widget.note.status) {
      NoteStatus.anchored => Icons.check_circle,
      NoteStatus.shifted => Icons.warning,
      NoteStatus.orphan => Icons.error,
    };
  }

  /// Get status tooltip text
  String _getStatusTooltip() {
    return switch (widget.note.status) {
      NoteStatus.anchored => 'הערה מעוגנת במיקום מדויק',
      NoteStatus.shifted => 'הערה מוזזת אך אותרה',
      NoteStatus.orphan => 'הערה יתומה - נדרש אימות ידני',
    };
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _animationController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _animationController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: _getHighlightColor(context),
            borderRadius: BorderRadius.circular(2),
            border: _isHovered
                ? Border.all(
                    color: _getStatusIndicatorColor(context),
                    width: 1,
                  )
                : null,
          ),
          child: Stack(
            children: [
              widget.child,
              if (_isHovered && widget.enabled)
                Positioned(
                  top: -2,
                  right: -2,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Tooltip(
                      message: _getStatusTooltip(),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _getStatusIndicatorColor(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getStatusIcon(),
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to add warning color to ColorScheme
extension ColorSchemeExtension on ColorScheme {
  Color get warning => const Color(0xFFFF9800);
}

/// Widget for displaying a note indicator without highlighting text
class NoteIndicator extends StatelessWidget {
  final Note note;
  final double size;
  final VoidCallback? onTap;

  const NoteIndicator({
    super.key,
    required this.note,
    this.size = 16,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = switch (note.status) {
      NoteStatus.anchored => colorScheme.primary,
      NoteStatus.shifted => colorScheme.warning,
      NoteStatus.orphan => colorScheme.error,
    };

    final icon = switch (note.status) {
      NoteStatus.anchored => Icons.note,
      NoteStatus.shifted => Icons.note_outlined,
      NoteStatus.orphan => Icons.error_outline,
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: size * 0.7,
          color: Colors.white,
        ),
      ),
    );
  }
}