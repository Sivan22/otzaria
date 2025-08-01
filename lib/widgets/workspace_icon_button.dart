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

class _WorkspaceIconButtonState extends State<WorkspaceIconButton> {
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    // טוען את workspaces כשהwidget נוצר
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkspaceBloc>().add(LoadWorkspaces());
      }
    });
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
    return BlocConsumer<WorkspaceBloc, WorkspaceState>(
      listener: (context, state) {
        // Debug: הדפסה כדי לראות מה קורה
        print('WorkspaceBloc state changed: ${state.workspaces.length} workspaces, current: ${state.currentWorkspace}');
      },
      builder: (context, workspaceState) {
        // אם אין workspaces או שהם עדיין נטענים, נטען אותם
        if (workspaceState.workspaces.isEmpty && !workspaceState.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<WorkspaceBloc>().add(LoadWorkspaces());
          });
        }
        
        final currentWorkspaceName = workspaceState.workspaces.isNotEmpty &&
                workspaceState.currentWorkspace != null
            ? workspaceState.workspaces[workspaceState.currentWorkspace!].name
            : 'ברירת מחדל';

        print('Building WorkspaceIconButton with name: $currentWorkspaceName');
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
    // מוסיף מרווח בטיחות כדי למנוע overflow
    final expandedWidth = (20 + 8 + textWidth + 24 + 8).clamp(40.0, 180.0);

    return Tooltip(
      message: 'החלף שולחן עבודה',
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovered) {
            setState(() {
              _isHovered = true;
            });
          }
        },
        onExit: (_) {
          if (_isHovered) {
            setState(() {
              _isHovered = false;
            });
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: _isHovered ? expandedWidth : 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: _isHovered 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.0),
                onTap: widget.onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_to_queue, size: 20),
                          if (_isHovered && constraints.maxWidth > 48) ...[
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: _isHovered ? 1.0 : 0.0,
                                child: Text(
                                  workspaceName,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.start,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}