import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_bloc.dart';
import 'package:otzaria/workspaces/bloc/workspace_state.dart';
import 'package:otzaria/workspaces/bloc/workspace_event.dart';

class WorkspaceIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  
  const WorkspaceIconButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  State<WorkspaceIconButton> createState() => _WorkspaceIconButtonState();
}

class _WorkspaceIconButtonState extends State<WorkspaceIconButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // טוען את workspaces כשהwidget נוצר
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(LoadWorkspaces());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.rtl,
    );
    textPainter.layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceBloc, WorkspaceState>(
      builder: (context, workspaceState) {
        final currentWorkspaceName = workspaceState.workspaces.isNotEmpty &&
                workspaceState.currentWorkspace != null
            ? workspaceState.workspaces[workspaceState.currentWorkspace!].name
            : 'ברירת מחדל';

        return _buildButtonWidget(context, currentWorkspaceName);
      },
    );
  }

  Widget _buildButtonWidget(BuildContext context, String workspaceName) {
    const textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    
    // חישוב רוחב הטקסט
    final textWidth = _calculateTextWidth(workspaceName, textStyle);
    
    // חישוב הרוחב הכולל: אייקון (20) + רווח (8) + טקסט + padding (24)
    final expandedWidth = (20 + 8 + textWidth + 24 + 8).clamp(40.0, 180.0);

    return Tooltip(
      message: 'החלף שולחן עבודה',
      child: MouseRegion(
        onEnter: (_) {
          setState(() {
            _isHovered = true;
          });
          _animationController.forward();
        },
        onExit: (_) {
          setState(() {
            _isHovered = false;
          });
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            final currentWidth = 48.0 + (expandedWidth - 48.0) * _scaleAnimation.value;
            
            return Container(
              width: currentWidth,
              height: 48.0,
              decoration: BoxDecoration(
                color: _isHovered
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24.0),
                  onTap: widget.onPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_to_queue),
                        if (_isHovered && _scaleAnimation.value > 0.3)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Opacity(
                                opacity: _scaleAnimation.value,
                                child: Text(
                                  workspaceName,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}