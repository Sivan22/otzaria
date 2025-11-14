import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:otzaria/personal_notes/bloc/personal_notes_bloc.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_event.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_state.dart';
import 'package:otzaria/personal_notes/models/personal_note.dart';
import 'package:otzaria/personal_notes/widgets/personal_note_editor_dialog.dart';
import 'package:otzaria/widgets/confirmation_dialog.dart';
import 'package:otzaria/widgets/input_dialog.dart';
import 'package:otzaria/i18n/translations.g.dart';

class PersonalNotesSidebar extends StatefulWidget {
  final String bookId;
  final ValueChanged<int> onNavigateToLine;

  const PersonalNotesSidebar({
    super.key,
    required this.bookId,
    required this.onNavigateToLine,
  });

  @override
  State<PersonalNotesSidebar> createState() => _PersonalNotesSidebarState();
}

class _PersonalNotesSidebarState extends State<PersonalNotesSidebar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PersonalNotesBloc>().add(LoadPersonalNotes(widget.bookId));
    });
  }

  @override
  void didUpdateWidget(covariant PersonalNotesSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId) {
      context.read<PersonalNotesBloc>().add(LoadPersonalNotes(widget.bookId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonalNotesBloc, PersonalNotesState>(
      builder: (context, state) {
        if (state.isLoading && state.locatedNotes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, state),
            const Divider(height: 1),
            Expanded(
              child: _buildContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PersonalNotesState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            context.t.more.personalNotes,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            tooltip: context.t.common.refresh,
            onPressed: () {
              context
                  .read<PersonalNotesBloc>()
                  .add(LoadPersonalNotes(widget.bookId));
            },
            icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, PersonalNotesState state) {
    if (state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            state.errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (state.locatedNotes.isEmpty && state.missingNotes.isEmpty) {
      return Center(
        child: Text(context.t.notes.noNotesYet),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        if (state.locatedNotes.isNotEmpty) ...[
          _SectionHeader(
            title: context.t.notes.title,
            count: state.locatedNotes.length,
          ),
          ...state.locatedNotes.map(
            (note) => _LocatedNoteTile(
              note: note,
              onTap: () => widget.onNavigateToLine(note.lineNumber!),
              onEdit: () => _editNote(context, note),
              onDelete: () => _confirmDelete(context, note),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (state.missingNotes.isNotEmpty) ...[
          _SectionHeader(
            title: context.t.notes.missingLocationNotes,
            count: state.missingNotes.length,
          ),
          ...state.missingNotes.map(
            (note) => _MissingNoteTile(
              note: note,
              onReposition: () => _reposition(context, note),
              onEdit: () => _editNote(context, note),
              onDelete: () => _confirmDelete(context, note),
            ),
          ),
        ],
        if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _editNote(BuildContext context, PersonalNote note) async {
    final controller = TextEditingController(text: note.content);
    final bloc = context.read<PersonalNotesBloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PersonalNoteEditorDialog(
        title: context.t.notes.editNote,
        controller: controller,
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    bloc.add(
      UpdatePersonalNote(
        bookId: widget.bookId,
        noteId: note.id,
        content: result,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PersonalNote note) async {
    final bloc = context.read<PersonalNotesBloc>();
    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: context.t.notes.deleteNote,
      content: context.t.notes.deleteNoteConfirm,
      confirmText: context.t.common.delete,
      isDangerous: true,
    );

    if (shouldDelete == true) {
      if (!mounted) return;
      bloc.add(
        DeletePersonalNote(
          bookId: widget.bookId,
          noteId: note.id,
        ),
      );
    }
  }

  Future<void> _reposition(BuildContext context, PersonalNote note) async {
    final bloc = context.read<PersonalNotesBloc>();

    final result = await showInputDialog(
      context: context,
      title: context.t.notes.restoreNoteLocation,
      subtitle: note.lastKnownLineNumber != null
          ? '${context.t.notes.lastKnownLocation}: ${context.t.notes.line} ${note.lastKnownLineNumber}'
          : null,
      labelText: context.t.notes.newLine,
      hintText: context.t.notes.enterLineNumber,
      initialValue: note.lastKnownLineNumber?.toString() ?? '',
      keyboardType: TextInputType.number,
    );

    final newLine = result != null ? int.tryParse(result) : null;

    if (newLine != null) {
      if (!mounted) return;
      bloc.add(
        RepositionPersonalNote(
          bookId: widget.bookId,
          noteId: note.id,
          lineNumber: newLine,
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocatedNoteTile extends StatelessWidget {
  final PersonalNote note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LocatedNoteTile({
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onTap,
        title: Text(
          '${context.t.notes.line} ${note.lineNumber}',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.referenceWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  note.referenceWords.join(' '),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: _NoteActions(onEdit: onEdit, onDelete: onDelete),
      ),
    );
  }
}

class _MissingNoteTile extends StatelessWidget {
  final PersonalNote note;
  final VoidCallback onReposition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MissingNoteTile({
    required this.note,
    required this.onReposition,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceTint.withValues(alpha: 0.08),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: onReposition,
        title: Text(
          context.t.notes.noteWithoutLocation,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.lastKnownLineNumber != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '${context.t.notes.previousLine}: ${note.lastKnownLineNumber}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Text(
              note.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: _NoteActions(
          onEdit: onEdit,
          onDelete: onDelete,
          extraAction: IconButton(
            tooltip: context.t.notes.reposition,
            icon: const Icon(FluentIcons.location_24_regular),
            onPressed: onReposition,
          ),
        ),
      ),
    );
  }
}

class _NoteActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? extraAction;

  const _NoteActions({
    required this.onEdit,
    required this.onDelete,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        IconButton(
                  tooltip: context.t.notes.edit,
          icon: const Icon(FluentIcons.edit_24_regular),
          onPressed: onEdit,
        ),
        extraAction ?? const SizedBox.shrink(),
        IconButton(
                  tooltip: context.t.common.delete,
          icon: const Icon(FluentIcons.delete_24_regular),
          onPressed: onDelete,
        ),
      ],
    );
  }
}
