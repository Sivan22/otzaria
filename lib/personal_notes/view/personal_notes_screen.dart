import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_bloc.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_event.dart';
import 'package:otzaria/personal_notes/bloc/personal_notes_state.dart';
import 'package:otzaria/personal_notes/models/personal_note.dart';
import 'package:otzaria/personal_notes/repository/personal_notes_repository.dart';
import 'package:otzaria/personal_notes/storage/personal_notes_storage.dart';
import 'package:otzaria/personal_notes/widgets/personal_note_editor_dialog.dart';
import 'package:otzaria/widgets/confirmation_dialog.dart';
import 'package:otzaria/widgets/input_dialog.dart';
import 'package:otzaria/i18n/translations.g.dart';

class PersonalNotesManagerScreen extends StatefulWidget {
  const PersonalNotesManagerScreen({super.key});

  @override
  State<PersonalNotesManagerScreen> createState() =>
      _PersonalNotesManagerScreenState();
}

class _PersonalNotesManagerScreenState extends State<PersonalNotesManagerScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final PersonalNotesRepository _repository = PersonalNotesRepository();

  List<StoredBookNotes> _books = [];
  String? _selectedBook;
  bool _isLoadingBooks = true;
  String? _booksError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoadingBooks = true;
      _booksError = null;
    });

    try {
      final books = await _repository.listBooksWithNotes();
      if (!mounted) return;
      setState(() {
        _books = books;
        _selectedBook = books.isNotEmpty ? books.first.bookId : null;
        _isLoadingBooks = false;
      });
      if (_selectedBook != null) {
        context
            .read<PersonalNotesBloc>()
            .add(LoadPersonalNotes(_selectedBook!));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _booksError = e.toString();
        _isLoadingBooks = false;
      });
    }
  }

  Future<void> _reloadCurrentBook() async {
    final current = _selectedBook;
    if (current != null) {
      context.read<PersonalNotesBloc>().add(LoadPersonalNotes(current));
    }
  }

  void _onBookChanged(String? bookId) {
    if (bookId == null || bookId == _selectedBook) return;
    setState(() {
      _selectedBook = bookId;
    });
    context.read<PersonalNotesBloc>().add(LoadPersonalNotes(bookId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingBooks) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_booksError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'אירעה שגיאה בעת טעינת רשימת ההערות:\n${_booksError!}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadBooks,
              child: Text(context.t.notes.tryAgain), // Old: 'נסה שוב'
            ),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context
                .t.notes.noPersonalNotes), // Old: 'לא נמצאו הערות אישיות.'
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadBooks,
              child: Text(context.t.common.refresh), // Old: 'רענון'
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedBook,
                  isExpanded: true,
                  items: _books
                      .map(
                        (book) => DropdownMenuItem<String>(
                          value: book.bookId,
                          child: Text(book.bookId),
                        ),
                      )
                      .toList(),
                  onChanged: _onBookChanged,
                ),
              ),
              IconButton(
                tooltip: 'רענון',
                onPressed: _reloadCurrentBook,
                icon: const Icon(FluentIcons.arrow_clockwise_24_regular),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'הערות'),
              Tab(text: 'הערות חסרות מיקום'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<PersonalNotesBloc, PersonalNotesState>(
              builder: (context, state) {
                if (state.isLoading || state.bookId != _selectedBook) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.errorMessage != null) {
                  return Center(
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotesList(state.locatedNotes, located: true),
                    _buildNotesList(state.missingNotes, located: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList(List<PersonalNote> notes, {required bool located}) {
    if (notes.isEmpty) {
      return Center(
        child: Text(
          located ? 'אין הערות במיקום זה.' : 'אין הערות חסרות מיקום.',
        ),
      );
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            title: Row(
              children: [
                Text(
                  located ? 'שורה ${note.lineNumber}' : 'הערה ללא מיקום',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  _formatDate(note.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (located && note.referenceWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text(
                      note.referenceWords.join(' '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                Text(
                  note.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (!located && note.lastKnownLineNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'שורה קודמת: ${note.lastKnownLineNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            onTap: located ? null : () => _repositionMissing(note),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'עריכה',
                  icon: const Icon(FluentIcons.edit_24_regular),
                  onPressed: () => _editNote(note),
                ),
                if (!located)
                  IconButton(
                    tooltip: 'מיקום מחדש',
                    icon: const Icon(FluentIcons.location_24_regular),
                    onPressed: () => _repositionMissing(note),
                  ),
                IconButton(
                  tooltip: 'מחיקה',
                  icon: const Icon(FluentIcons.delete_24_regular),
                  onPressed: () => _deleteNote(note),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editNote(PersonalNote note) async {
    final controller = TextEditingController(text: note.content);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => PersonalNoteEditorDialog(
        title: context.t.notes.editNote,
        controller: controller,
      ),
    );
    if (result == null) return;

    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      UiSnack.show(context.t.notes.emptyNoteNotSaved);
      return;
    }

    if (!mounted) return;
    context.read<PersonalNotesBloc>().add(
          UpdatePersonalNote(
            bookId: note.bookId,
            noteId: note.id,
            content: trimmed,
          ),
        );
    UiSnack.show(context.t.notes.noteUpdated);
  }

  Future<void> _deleteNote(PersonalNote note) async {
    final shouldDelete = await showConfirmationDialog(
      context: context,
      title: context.t.notes.deleteNote,
      content: context.t.notes.deleteNoteConfirm,
      confirmText: context.t.common.delete,
      isDangerous: true,
    );

    if (shouldDelete == true) {
      if (!mounted) return;
      context.read<PersonalNotesBloc>().add(
            DeletePersonalNote(
              bookId: note.bookId,
              noteId: note.id,
            ),
          );
      UiSnack.show(context.t.notes.noteDeleted);
    }
  }

  Future<void> _repositionMissing(PersonalNote note) async {
    final result = await showInputDialog(
      context: context,
      title: context.t.notes.repositionNote,
      subtitle: note.lastKnownLineNumber != null
          ? '${context.t.notes.previousLine}: ${note.lastKnownLineNumber}'
          : null,
      labelText: context.t.notes.newLineNumber,
      initialValue: (note.lastKnownLineNumber ?? '').toString(),
      keyboardType: TextInputType.number,
    );

    final newLine = result != null ? int.tryParse(result) : null;

    if (newLine != null) {
      if (!mounted) return;
      context.read<PersonalNotesBloc>().add(
            RepositionPersonalNote(
              bookId: note.bookId,
              noteId: note.id,
              lineNumber: newLine,
            ),
          );
      UiSnack.show('ההערה הועברה לשורה $newLine');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
