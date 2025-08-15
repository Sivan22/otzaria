import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/notes_bloc.dart';
import '../bloc/notes_event.dart';
import '../bloc/notes_state.dart';
import '../models/note.dart';
import '../models/anchor_models.dart';
import '../repository/notes_repository.dart';
import '../services/notes_telemetry.dart';


/// Widget for managing orphaned notes and helping re-anchor them
class OrphanNotesManager extends StatefulWidget {
  final String bookId;
  final VoidCallback? onClose;

  const OrphanNotesManager({
    super.key,
    required this.bookId,
    this.onClose,
  });

  @override
  State<OrphanNotesManager> createState() => _OrphanNotesManagerState();
}

class _OrphanNotesManagerState extends State<OrphanNotesManager> {
  Note? _selectedOrphan;
  List<AnchorCandidate> _candidates = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadOrphanNotes();
  }

  void _loadOrphanNotes() {
    context.read<NotesBloc>().add(LoadNotesEvent(widget.bookId));
  }

  void _selectOrphan(Note orphan) {
    setState(() {
      _selectedOrphan = orphan;
      _isSearching = true;
      _candidates = [];
    });

    // Find potential anchor candidates for this orphan
    context.read<NotesBloc>().add(FindAnchorCandidatesEvent(orphan));
  }

  void _acceptCandidate(AnchorCandidate candidate) {
    if (_selectedOrphan == null) return;

    // Track user action
    NotesTelemetry.trackUserAction('orphan_reanchored', {
      'note_count': 1,
      'strategy': candidate.strategy,
      'score': (candidate.score * 100).round(),
    });

    // Update the note with new anchor position
    final updateRequest = UpdateNoteRequest(
      charStart: candidate.start,
      charEnd: candidate.end,
      status: NoteStatus.shifted, // Mark as shifted since it's re-anchored
    );

    context.read<NotesBloc>().add(UpdateNoteEvent(_selectedOrphan!.id, updateRequest));

    // Clear selection
    setState(() {
      _selectedOrphan = null;
      _candidates = [];
      _isSearching = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('הערה עוגנה מחדש בהצלחה'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectCandidate() {
    setState(() {
      _selectedOrphan = null;
      _candidates = [];
      _isSearching = false;
    });
  }

  void _deleteOrphan(Note orphan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחק הערה יתומה'),
        content: const Text('האם אתה בטוח שברצונך למחוק הערה זו? פעולה זו לא ניתנת לביטול.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NotesBloc>().add(DeleteNoteEvent(orphan.id));
              
              NotesTelemetry.trackUserAction('orphan_deleted', {
                'note_count': 1,
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('מחק'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ניהול הערות יתומות',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'הערות יתומות הן הערות שלא ניתן למצוא עבורן מיקום מתאים בגרסה הנוכחית של הטקסט.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Orphan notes list
                  Expanded(
                    flex: 1,
                    child: _buildOrphansList(),
                  ),
                  
                  const SizedBox(width: 24),
                  
                  // Candidates panel
                  Expanded(
                    flex: 2,
                    child: _buildCandidatesPanel(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrphansList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הערות יתומות',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Expanded(
          child: BlocBuilder<NotesBloc, NotesState>(
            builder: (context, state) {
              if (state is NotesLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is NotesError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text(state.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrphanNotes,
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                );
              }

              List<Note> orphans = [];
              if (state is NotesLoaded) {
                orphans = state.notes.where((note) => note.status == NoteStatus.orphan).toList();
              }

              if (orphans.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                      SizedBox(height: 16),
                      Text('אין הערות יתומות!'),
                      SizedBox(height: 8),
                      Text('כל ההערות מעוגנות כראוי.'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: orphans.length,
                itemBuilder: (context, index) {
                  final orphan = orphans[index];
                  final isSelected = _selectedOrphan?.id == orphan.id;
                  
                  return Card(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      title: Text(
                        orphan.contentMarkdown,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'נוצרה: ${_formatDate(orphan.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'find':
                              _selectOrphan(orphan);
                              break;
                            case 'delete':
                              _deleteOrphan(orphan);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'find',
                            child: Row(
                              children: [
                                Icon(Icons.search),
                                SizedBox(width: 8),
                                Text('חפש מיקום'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('מחק'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _selectOrphan(orphan),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCandidatesPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'מועמדים לעיגון מחדש',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Expanded(
          child: _selectedOrphan == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_back, size: 48),
                      SizedBox(height: 16),
                      Text('בחר הערה יתומה מהרשימה'),
                      SizedBox(height: 8),
                      Text('כדי לחפש מועמדים לעיגון מחדש'),
                    ],
                  ),
                )
              : _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCandidatesList(),
        ),
      ],
    );
  }

  Widget _buildCandidatesList() {
    if (_candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48),
            const SizedBox(height: 16),
            const Text('לא נמצאו מועמדים מתאימים'),
            const SizedBox(height: 8),
            const Text('ייתכן שהטקסט השתנה משמעותית'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _rejectCandidate,
              child: const Text('חזור'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Selected orphan info
        Card(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'הערה יתומה:',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedOrphan!.contentMarkdown,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'טקסט מקורי: "${_selectedOrphan!.selectedTextNormalized}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Candidates list
        Expanded(
          child: ListView.builder(
            itemCount: _candidates.length,
            itemBuilder: (context, index) {
              final candidate = _candidates[index];
              return _CandidateItem(
                candidate: candidate,
                onAccept: () => _acceptCandidate(candidate),
                onReject: index == _candidates.length - 1 ? _rejectCandidate : null,
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Individual candidate item widget
class _CandidateItem extends StatelessWidget {
  final AnchorCandidate candidate;
  final VoidCallback onAccept;
  final VoidCallback? onReject;

  const _CandidateItem({
    required this.candidate,
    required this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final scorePercent = (candidate.score * 100).round();
    final scoreColor = _getScoreColor(candidate.score);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with score and strategy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scoreColor),
                  ),
                  child: Text(
                    '$scorePercent%',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    _getStrategyLabel(candidate.strategy),
                    style: const TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                Text(
                  'מיקום: ${candidate.start}-${candidate.end}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Preview text (would be extracted from document)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'טקסט לדוגמה במיקום המוצע...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('אשר'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('דחה'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getStrategyLabel(String strategy) {
    switch (strategy) {
      case 'exact':
        return 'התאמה מדויקת';
      case 'context':
        return 'התאמת הקשר';
      case 'fuzzy':
        return 'התאמה מטושטשת';
      default:
        return strategy;
    }
  }
}