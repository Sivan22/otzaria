import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/bloc/file_sync/file_sync_bloc.dart';
import 'package:otzaria/bloc/file_sync/file_sync_event.dart';
import 'package:otzaria/bloc/file_sync/file_sync_state.dart';

class SyncIconButton extends StatefulWidget {
  final double size;
  final Color? color;
  final VoidCallback? onCompleted;

  const SyncIconButton({
    Key? key,
    this.size = 24.0,
    this.color,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<SyncIconButton> createState() => _SyncIconButtonState();
}

class _SyncIconButtonState extends State<SyncIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress(BuildContext context, FileSyncState state) {
    final bloc = context.read<FileSyncBloc>();

    // If syncing, stop the sync
    if (state.status == FileSyncStatus.syncing) {
      bloc.add(const StopSync());
      return;
    }

    // If completed or error, reset the state
    if (state.status == FileSyncStatus.completed ||
        state.status == FileSyncStatus.error) {
      bloc.add(const ResetState());
      return;
    }

    // Start new sync
    bloc.add(const StartSync());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileSyncBloc, FileSyncState>(
      listener: (context, state) {
        if (state.status == FileSyncStatus.completed &&
            widget.onCompleted != null) {
          widget.onCompleted!();
        }
      },
      builder: (context, state) {
        Color iconColor;
        IconData iconData;

        switch (state.status) {
          case FileSyncStatus.error:
            _controller.stop();
            iconColor = Colors.red;
            iconData = Icons.sync_problem;
          case FileSyncStatus.completed:
            _controller.stop();
            iconColor = Colors.green;
            iconData = Icons.check_circle;
          case FileSyncStatus.syncing:
            _controller.repeat();
            iconColor = widget.color ?? Theme.of(context).iconTheme.color!;
            iconData = Icons.sync;
          case FileSyncStatus.initial:
            _controller.stop();
            iconColor = widget.color ?? Theme.of(context).iconTheme.color!;
            iconData = Icons.sync;
        }

        return Tooltip(
          message: state.message,
          textAlign: TextAlign.center,
          preferBelow: true,
          waitDuration: const Duration(milliseconds: 500),
          child: IconButton(
            onPressed: () => _handlePress(context, state),
            icon: RotationTransition(
              turns: _controller,
              child: Icon(
                iconData,
                color: iconColor,
                size: widget.size,
              ),
            ),
            splashRadius: widget.size * 0.8,
            tooltip: null,
          ),
        );
      },
    );
  }
}
