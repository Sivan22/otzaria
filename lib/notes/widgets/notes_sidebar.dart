import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../models/note.dart';

import '../services/notes_telemetry.dart';

/// Sidebar widget for displaying and managing notes
class NotesSidebar extends StatefulWidget {
  final String? bookId;
  final VoidCallback? onClose;
  final Function(Note)? onNoteSelected;
  final Function(int, int)? onNavigateToPosition;

  const NotesSidebar({
    super.key,
    this.bookId,
    this.onClose,
    this.onNoteSelected,
    this.onNavigateToPosition,
  });

  @override
  State<NotesSidebar> createState() => _NotesSidebarState();
}

class _NotesSidebarState extends State<NotesSidebar> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  NoteSortOption _sortOption = NoteSortOption.dateDesc;
  NoteStatusFilter _statusFilter = NoteStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _loadNotes();
    
    // רענון ההערות כל 2 שניות כדי לתפוס הערות חדשות
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && widget.bookId != null) {
        try {
          context.read<NotesBloc>().add(LoadNotesEvent(widget.bookId!));
        } catch (e) {
          // אם ה-BLoC לא זמין, נעצור את הטיימר
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didUpdateWidget(NotesSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookId != oldWidget.bookId) {
      _loadNotes();
    }
  }

  void _loadNotes() {
    if (widget.bookId != null) {
      try {
        context.read<NotesBloc>().add(LoadNotesEvent(widget.bookId!));
      } catch (e) {
        // BLoC not available yet - will be handled in build method
        print('NotesBloc not available: $e');
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.trim();
    });
    
    if (_searchQuery.isNotEmpty) {
      final stopwatch = Stopwatch()..start();
      context.read<NotesBloc>().add(SearchNotesEvent(_searchQuery));
      
      // Track search performance
      NotesTelemetry.trackSearchPerformance(
        _searchQuery,
        0, // Will be updated when results arrive
        stopwatch.elapsed,
      );
    } else {
      _loadNotes();
    }
  }

  void _onSortChanged(NoteSortOption? option) {
    if (option != null) {
      setState(() {
        _sortOption = option;
      });
    }
  }

  void _onStatusFilterChanged(NoteStatusFilter? filter) {
    if (filter != null) {
      setState(() {
        _statusFilter = filter;
      });
    }
  }

  List<Note> _filterAndSortNotes(List<Note> notes) {
    // Apply status filter
    var filteredNotes = notes.where((note) {
      switch (_statusFilter) {
        case NoteStatusFilter.all:
          return true;
        case NoteStatusFilter.anchored:
          return note.status == NoteStatus.anchored;
        case NoteStatusFilter.shifted:
          return note.status == NoteStatus.shifted;
        case NoteStatusFilter.orphan:
          return note.status == NoteStatus.orphan;
      }
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case NoteSortOption.dateDesc:
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case NoteSortOption.dateAsc:
        filteredNotes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case NoteSortOption.status:
        filteredNotes.sort((a, b) {
          final statusOrder = {
            NoteStatus.anchored: 0,
            NoteStatus.shifted: 1,
            NoteStatus.orphan: 2,
          };
          return statusOrder[a.status]!.compareTo(statusOrder[b.status]!);
        });
        break;
      case NoteSortOption.relevance:
        // For search results, keep original order (relevance-based)
        // For regular notes, sort by date
        if (_searchQuery.isEmpty) {
          filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        }
        break;
    }

    return filteredNotes;
  }

  void _onNotePressed(Note note) {
    // Track user action
    NotesTelemetry.trackUserAction('note_selected', {
      'note_count': 1,
      'status': note.status.name,
      'content_length': note.contentMarkdown.length,
    });

    // Navigate to note position if possible
    if (note.status != NoteStatus.orphan && widget.onNavigateToPosition != null) {
      widget.onNavigateToPosition!(note.charStart, note.charEnd);
    }

    // Notify parent
    widget.onNoteSelected?.call(note);
  }

  void _onEditNote(Note note) {
    context.read<NotesBloc>().add(EditNoteEvent(note));
  }

  void _onDeleteNote(Note note) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק הערה'),
        content: const Text('האם אתה בטוח שברצונך למחוק הערה זו?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NotesBloc>().add(DeleteNoteEvent(note.id));
              
              NotesTelemetry.trackUserAction('note_deleted', {
                'note_count': 1,
                'status': note.status.name,
              });
            },
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header - עיצוב דומה למפרשים
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'הערות אישיות',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.onClose != null)
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  tooltip: 'סגור',
                ),
            ],
          ),
        ),

        // Search and filters - עיצוב דומה למפרשים
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                  onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'חפש הערות...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          icon: const Icon(Icons.close),
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Flexible(
                    flex: 3,
                    child: DropdownButtonFormField<NoteSortOption>(
                      value: _sortOption,
                      onChanged: _onSortChanged,
                      decoration: const InputDecoration(
                        labelText: 'מיון',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: NoteSortOption.values.map((option) {
                        return DropdownMenuItem(
                          value: option,
                          child: Text(
                            _getSortOptionLabel(option),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    flex: 2,
                    child: DropdownButtonFormField<NoteStatusFilter>(
                      value: _statusFilter,
                      onChanged: _onStatusFilterChanged,
                      decoration: const InputDecoration(
                        labelText: 'סטטוס',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      items: NoteStatusFilter.values.map((filter) {
                        return DropdownMenuItem(
                          value: filter,
                          child: Text(
                            _getStatusFilterLabel(filter),
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notes list
        Expanded(
            child: Builder(
              builder: (context) {
                try {
                  return BlocBuilder<NotesBloc, NotesState>(
                    builder: (context, state) {
                if (state is NotesLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is NotesError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'שגיאה בטעינת הערות',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadNotes,
                          child: const Text('נסה שוב'),
                        ),
                      ],
                    ),
                  );
                }

                List<Note> notes = [];
                if (state is NotesLoaded) {
                  notes = state.notes;
                } else if (state is NotesSearchResults) {
                  notes = state.results;
                }

                final filteredNotes = _filterAndSortNotes(notes);

                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty 
                              ? Icons.search_off 
                              : Icons.note_add_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'לא נמצאו תוצאות'
                              : 'אין הערות עדיין',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty 
                              ? 'נסה מילות חיפוש אחרות'
                              : 'בחר טקסט והוסף הערה ראשונה',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return _NoteListItem(
                      note: note,
                      onPressed: () => _onNotePressed(note),
                      onEdit: () => _onEditNote(note),
                      onDelete: () => _onDeleteNote(note),
                    );
                  },
                );
                    },
                  );
                } catch (e) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'שגיאה בטעינת הערות',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NotesBloc לא זמין. נסה לעשות restart לאפליקציה.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      );
  }

  String _getSortOptionLabel(NoteSortOption option) {
    switch (option) {
      case NoteSortOption.dateDesc:
        return 'תאריך (חדש לישן)';
      case NoteSortOption.dateAsc:
        return 'תאריך (ישן לחדש)';
      case NoteSortOption.status:
        return 'סטטוס';
      case NoteSortOption.relevance:
        return 'רלוונטיות';
    }
  }

  String _getStatusFilterLabel(NoteStatusFilter filter) {
    switch (filter) {
      case NoteStatusFilter.all:
        return 'הכל';
      case NoteStatusFilter.anchored:
        return 'מעוגנות';
      case NoteStatusFilter.shifted:
        return 'זזזו';
      case NoteStatusFilter.orphan:
        return 'יתומות';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Individual note item in the sidebar list
class _NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onPressed;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteListItem({
    required this.note,
    required this.onPressed,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and actions
              Row(
                children: [
                  _StatusIndicator(status: note.status),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatDate(note.updatedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('ערוך'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('מחק'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Note content preview
              Text(
                note.contentMarkdown,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Tags if any
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: note.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'היום ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'אתמול';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ימים';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Status indicator widget
class _StatusIndicator extends StatelessWidget {
  final NoteStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String tooltip;

    switch (status) {
      case NoteStatus.anchored:
        color = Colors.green;
        tooltip = 'מעוגנת במיקום המדויק';
        break;
      case NoteStatus.shifted:
        color = Colors.orange;
        tooltip = 'זזזה ממיקום המקורי';
        break;
      case NoteStatus.orphan:
        color = Colors.red;
        tooltip = 'לא נמצא מיקום מתאים';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Sort options for notes
enum NoteSortOption {
  dateDesc,
  dateAsc,
  status,
  relevance,
}

/// Status filter options
enum NoteStatusFilter {
  all,
  anchored,
  shifted,
  orphan,
}