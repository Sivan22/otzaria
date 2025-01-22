import 'package:flutter/material.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/utils/file_sync_service.dart';

class SyncIconButton extends StatefulWidget {
  final FileSyncService fileSync;
  final VoidCallback? onCompleted;
  final double size;
  final Color? color;

  const SyncIconButton({
    Key? key,
    required this.fileSync,
    this.onCompleted,
    this.size = 24.0,
    this.color,
  }) : super(key: key);

  @override
  State<SyncIconButton> createState() => _SyncIconButtonState();
}

class _SyncIconButtonState extends State<SyncIconButton>
    with SingleTickerProviderStateMixin {
  String _status = 'לחץ לסנכרון קבצים';
  bool _hasError = false;
  bool _hasNewSync = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    if (Settings.getValue<bool>('key-auto-sync') ?? false) {
      _startSync();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _clearState() {
    setState(() {
      _hasError = false;
      _hasNewSync = false;
      _status = 'לחץ לסנכרון קבצים';
    });
  }

  // טיפול בלחיצה על הכפתור
  void _handlePress() {
    // אם כבר מסנכרן, מפסיקים את הסנכרון
    if (widget.fileSync.isSyncing) {
      widget.fileSync.stopSyncing();
      setState(() {
        _status = 'לחץ לסנכרון קבצים';
      });
      _rotationController.reset();
      return;
    }

    // אם יש שגיאה או סנכרון מוצלח, מנקים את המצב
    if (_hasError || _hasNewSync) {
      _clearState();
      return;
    }

    // אם במצב רגיל, מתחילים סנכרון
    _startSync();
  }

  void _updateStatus() {
    if (widget.fileSync.isSyncing && widget.fileSync.totalFiles > 0) {
      setState(() {
        _status =
            'מסנכרן קבצים... ${widget.fileSync.currentProgress}/${widget.fileSync.totalFiles}';
      });
    }
  }

  // פונקציה שמבצעת את הסנכרון בפועל
  Future<void> _startSync() async {
    setState(() {
      _status = 'מסנכרן קבצים...';
    });
    _rotationController.repeat();

    try {
      // Set up a timer to update the status periodically
      final statusTimer =
          Stream.periodic(const Duration(milliseconds: 100)).listen((_) {
        _updateStatus();
      });

      final results = await widget.fileSync.syncFiles();
      statusTimer.cancel();

      int successCount = results;

      setState(() {
        _hasNewSync = successCount > 0;
        _status = successCount > 0
            ? 'סונכרנו $successCount קבצים חדשים'
            : 'לחץ לסנכרון קבצים';
      });

      if (widget.onCompleted != null) {
        widget.onCompleted!();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _status = 'שגיאה בסנכרון: ${e.toString()}';
      });
    } finally {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color iconColor;
    IconData iconData;

    if (_hasError) {
      iconColor = Colors.red;
      iconData = Icons.sync_problem;
    } else if (_hasNewSync) {
      iconColor = Colors.green;
      iconData = Icons.check_circle;
    } else {
      iconColor = widget.color ?? Theme.of(context).iconTheme.color!;
      iconData = widget.fileSync.isSyncing ? Icons.sync : Icons.sync;
    }

    return Tooltip(
      message: _status,
      textAlign: TextAlign.center,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 500),
      child: IconButton(
        onPressed: _handlePress,
        icon: RotationTransition(
          turns: _rotationController,
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
  }
}
