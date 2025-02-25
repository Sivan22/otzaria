import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_event.dart';
import 'package:otzaria/find_ref/find_ref_state.dart';
import 'package:otzaria/focus/focus_bloc.dart';
import 'package:otzaria/focus/focus_event.dart';
import 'package:otzaria/focus/focus_state.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/ref_indexing/ref_indexing_screen.dart';

class FindRefScreen extends StatefulWidget {
  const FindRefScreen({super.key});

  @override
  State<FindRefScreen> createState() => _FindRefScreenState();
}

class _FindRefScreenState extends State<FindRefScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _textController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initial focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to FocusBloc state changes
    context.read<FocusBloc>().stream.listen((state) {
      if (state.focusTarget == FocusTarget.findRefSearch && mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Widget _buildIndexingWarning() {
    return BlocBuilder<FindRefBloc, FindRefState>(
      builder: (context, state) {
        if (state is FindRefIndexingStatus) {
          if (state.totalBooks == null ||
              state.booksProcessed == null ||
              state.booksProcessed! >= state.totalBooks!) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.all(8.0),
            margin: const EdgeInsets.only(bottom: 8.0),
            decoration: BoxDecoration(
              color: Colors.yellow.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'אינדקס המקורות בתהליך בנייה. תוצאות החיפוש עלולות להיות חלקיות.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      drawer: const Drawer(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.zero)),
          semanticLabel: 'הגדרות אינדקס',
          child: RefIndexingScreen()),
      appBar: AppBar(
        title: const Center(child: Text('איתור מקורות')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildIndexingWarning(),
            TextField(
              focusNode: _searchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב   ',
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _textController.clear();
                        BlocProvider.of<FindRefBloc>(context)
                            .add(ClearSearchRequested());
                      },
                    ),
                  ],
                ),
              ),
              controller: _textController,
              onChanged: (ref) {
                BlocProvider.of<FindRefBloc>(context)
                    .add(SearchRefRequested(ref));
              },
            ),
            Expanded(
              child: BlocBuilder<FindRefBloc, FindRefState>(
                builder: (context, state) {
                  if (state is FindRefLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is FindRefError) {
                    return Text('Error: ${state.message}');
                  } else if (state is FindRefSuccess && state.refs.isEmpty) {
                    if (_textController.text.length >= 3) {
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
                        return ListTile(
                            title: Text(state.refs[index].ref),
                            onTap: () {
                              TabsBloc tabsBloc = context.read<TabsBloc>();
                              NavigationBloc navigationBloc =
                                  context.read<NavigationBloc>();
                              if (state.refs[index].pdfBook) {
                                tabsBloc.add(AddTab(PdfBookTab(
                                    book: PdfBook(
                                        title: state.refs[index].bookTitle,
                                        path: state.refs[index].pdfPath!),
                                    initialPage: state.refs[index].index)));
                              } else {
                                tabsBloc.add(AddTab(TextBookTab(
                                    book: TextBook(
                                      title: state.refs[index].bookTitle,
                                    ),
                                    index: state.refs[index].index)));
                              }
                              navigationBloc
                                  .add(const NavigateToScreen(Screen.reading));
                            });
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
    );
  }
}
