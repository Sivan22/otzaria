import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/find_ref/find_ref_bloc.dart';
import 'package:otzaria/find_ref/find_ref_event.dart';
import 'package:otzaria/find_ref/find_ref_state.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';

class FindRefScreen extends StatefulWidget {
  const FindRefScreen({super.key});

  @override
  State<FindRefScreen> createState() => _FindRefScreenState();
}

class _FindRefScreenState extends State<FindRefScreen> {
  bool showIndexWarning = false;

  @override
  void initState() {
    super.initState();
    if (context.read<IndexingBloc>().state is IndexingInProgress) {
      showIndexWarning = true;
    }
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
            Icon(Icons.warning_amber, color: Colors.orange[700]),
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
                icon: const Icon(Icons.close))
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final focusRepository = context.read<FocusRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('איתור מקורות')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            _buildIndexingWarning(),
            TextField(
              focusNode: focusRepository.findRefSearchFocusNode,
              autofocus: true,
              decoration: InputDecoration(
                hintText:
                    'הקלד מקור מדוייק, לדוגמה: בראשית פרק א או שוע אוח יב   ',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    focusRepository.findRefSearchController.clear();
                    BlocProvider.of<FindRefBloc>(context)
                        .add(ClearSearchRequested());
                  },
                ),
              ),
              controller: focusRepository.findRefSearchController,
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
                        return ListTile(
                            leading: state.refs[index].isPdf
                                ? const Icon(Icons.picture_as_pdf)
                                : null,
                            title: Text(state.refs[index].reference),
                            onTap: () {
                              TabsBloc tabsBloc = context.read<TabsBloc>();
                              NavigationBloc navigationBloc =
                                  context.read<NavigationBloc>();
                              if (state.refs[index].isPdf) {
                                tabsBloc.add(AddTab(PdfBookTab(
                                    book: PdfBook(
                                        title: state.refs[index].title,
                                        path: state.refs[index].filePath),
                                    pageNumber:
                                        state.refs[index].segment.toInt(),
                                    openLeftPane:
                                        (Settings.getValue<bool>('key-pin-sidebar') ??
                                                false) ||
                                            (Settings.getValue<bool>(
                                                    'key-default-sidebar-open') ??
                                                false))));
                              } else {
                                tabsBloc.add(AddTab(TextBookTab(
                                    book: TextBook(
                                      title: state.refs[index].title,
                                    ),
                                    index: state.refs[index].segment.toInt(),
                                    openLeftPane:
                                        (Settings.getValue<bool>('key-pin-sidebar') ??
                                                false) ||
                                            (Settings.getValue<bool>(
                                                    'key-default-sidebar-open') ??
                                                false))));
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
