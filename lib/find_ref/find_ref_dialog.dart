import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_event.dart';
import 'package:otzaria/find_ref/find_ref_state.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/i18n/translations.g.dart';

class FindRefDialog extends StatefulWidget {
  const FindRefDialog({super.key});

  @override
  State<FindRefDialog> createState() => _FindRefDialogState();
}

class _FindRefDialogState extends State<FindRefDialog> {
  bool showIndexWarning = false;
  int _selectedIndex = 0;
  final Map<int, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    if (context.read<IndexingBloc>().state is IndexingInProgress) {
      showIndexWarning = true;
    }
  }

  GlobalKey _getKeyForIndex(int index) {
    if (!_itemKeys.containsKey(index)) {
      _itemKeys[index] = GlobalKey();
    }
    return _itemKeys[index]!;
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _getKeyForIndex(_selectedIndex);
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: 0.5, // מרכז המסך
        );
      }
    });
  }

  Widget _buildIndexingWarning() {
    if (showIndexWarning) {
      return Container(
        padding: const EdgeInsets.all(8.0),
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: Colors.yellow.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(FluentIcons.warning_24_regular, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'אינדקס המקורות בתהליך בנייה. תוצאות החיפוש עלולות להיות חלקיות.',
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.black87),
              ),
            ),
            IconButton(
                onPressed: () => setState(() => showIndexWarning = false),
                icon: const Icon(FluentIcons.dismiss_24_regular))
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final focusRepository = context.read<FocusRepository>();

    return AlertDialog(
      title: const Text(
        'איתור מקורות',
        style: TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            _buildIndexingWarning(),
            BlocBuilder<FindRefBloc, FindRefState>(
              builder: (context, state) {
                final refs = state is FindRefSuccess ? state.refs : [];
                return Focus(
                  onKeyEvent: (node, event) {
                    if (event is! KeyDownEvent) {
                      return KeyEventResult.ignored;
                    }

                    // טיפול בחיצים רק אם יש תוצאות
                    if (refs.isNotEmpty) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex + 1).clamp(0, refs.length - 1);
                        });
                        _scrollToSelected();
                        return KeyEventResult.handled;
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        setState(() {
                          _selectedIndex =
                              (_selectedIndex - 1).clamp(0, refs.length - 1);
                        });
                        _scrollToSelected();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    focusNode: focusRepository.findRefSearchFocusNode,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:
                          'הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב   ',
                      suffixIcon: IconButton(
                        icon: const Icon(FluentIcons.dismiss_24_regular),
                        onPressed: () {
                          focusRepository.findRefSearchController.clear();
                          BlocProvider.of<FindRefBloc>(context)
                              .add(ClearSearchRequested());
                          setState(() {
                            _selectedIndex = 0;
                          });
                        },
                      ),
                    ),
                    controller: focusRepository.findRefSearchController,
                    onChanged: (ref) {
                      BlocProvider.of<FindRefBloc>(context)
                          .add(SearchRefRequested(ref));
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                    onSubmitted: (value) {
                      // פתיחת המקור הנבחר בלחיצה על אנטר
                      if (refs.isNotEmpty) {
                        final ref = refs[_selectedIndex];
                        final book = ref.isPdf
                            ? PdfBook(title: ref.title, path: ref.filePath)
                            : TextBook(title: ref.title);
                        Navigator.of(context).pop();
                        openBook(context, book, ref.segment.toInt(), '');
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<FindRefBloc, FindRefState>(
                builder: (context, state) {
                  if (state is FindRefLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FindRefError) {
                    return Text('Error: ${state.message}');
                  } else if (state is FindRefSuccess && state.refs.isEmpty) {
                    if (focusRepository.findRefSearchController.text.length >=
                        3) {
                      return const Center(
                        child: Text(
                          'אין תוצאות',
                          style: TextStyle(fontSize: 16),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  } else if (state is FindRefSuccess) {
                    return ListView.builder(
                      itemCount: state.refs.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedIndex;
                        return Container(
                          key: _getKeyForIndex(index),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                              leading: state.refs[index].isPdf
                                  ? const Icon(
                                      FluentIcons.document_pdf_24_regular)
                                  : null,
                              title: Text(
                                state.refs[index].reference,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                final ref = state.refs[index];
                                final book = ref.isPdf
                                    ? PdfBook(
                                        title: ref.title, path: ref.filePath)
                                    : TextBook(title: ref.title);
                                // סגירת הדיאלוג לפני פתיחת הספר
                                Navigator.of(context).pop();
                                openBook(
                                    context, book, ref.segment.toInt(), '');
                              }),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.close), // Old: 'סגור'
        ),
      ],
    );
  }
}
