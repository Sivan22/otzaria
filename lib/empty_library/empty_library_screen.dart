import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/empty_library/bloc/empty_library_bloc.dart';
import 'package:otzaria/empty_library/bloc/empty_library_event.dart';
import 'package:otzaria/empty_library/bloc/empty_library_state.dart';
import 'dart:io' show Platform;

class EmptyLibraryScreen extends StatelessWidget {
  final VoidCallback onLibraryLoaded;

  const EmptyLibraryScreen({Key? key, required this.onLibraryLoaded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmptyLibraryBloc(),
      child: _EmptyLibraryView(onLibraryLoaded: onLibraryLoaded),
    );
  }
}

class _EmptyLibraryView extends StatelessWidget {
  final VoidCallback onLibraryLoaded;

  const _EmptyLibraryView({Key? key, required this.onLibraryLoaded})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<EmptyLibraryBloc, EmptyLibraryState>(
        listener: (context, state) {
          if (state is EmptyLibraryDownloaded) {
            onLibraryLoaded();
          }
          if (state is EmptyLibraryError && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(16),
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, EmptyLibraryState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'לא נמצאה ספרייה',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        if (!Platform.isAndroid && !Platform.isIOS) const SizedBox(height: 32),
        if (state.selectedPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              state.selectedPath!,
              style: const TextStyle(fontSize: 16),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ),
        if (!Platform.isAndroid && !Platform.isIOS)
          ElevatedButton(
            onPressed: state.isDownloading
                ? null
                : () => BlocProvider.of<EmptyLibraryBloc>(context)
                    .add(PickDirectoryRequested()),
            child: const Text('בחר תיקייה'),
          ),
        const SizedBox(height: 32),
        if (Platform.isAndroid)
          ElevatedButton(
            onPressed: state.isDownloading
                ? null
                : () => BlocProvider.of<EmptyLibraryBloc>(context)
                    .add(PickAndExtractZipRequested()),
            child: const Text('בחר קובץ ZIP מהמכשיר'),
          ),
        const Text(
          'או',
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 32),
        if (state.isDownloading) ...[
          _DownloadProgress(state: state),
        ] else
          ElevatedButton(
            onPressed: state.isDownloading
                ? null
                : () => BlocProvider.of<EmptyLibraryBloc>(context)
                    .add(DownloadLibraryRequested()),
            child: const Text('הורד את הספרייה מהאינטרנט (1.2GB)'),
          ),
      ],
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final EmptyLibraryState state;

  const _DownloadProgress({Key? key, required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(value: state.downloadProgress),
        const SizedBox(height: 16),
        Text(state.currentOperation),
        if (state.downloadSpeed > 0)
          Text('מהירות הורדה: ${state.downloadSpeed.toStringAsFixed(2)} MB/s'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: state.isCancelling
              ? null
              : () => BlocProvider.of<EmptyLibraryBloc>(context)
                  .add(CancelDownloadRequested()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.stop),
          label: Text(state.isCancelling ? 'מבטל...' : 'בטל'),
        ),
      ],
    );
  }
}
