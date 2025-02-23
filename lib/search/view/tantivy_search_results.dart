import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/search/view/full_text_settings_widgets.dart';

class TantivySearchResults extends StatefulWidget {
  final SearchingTab tab;
  const TantivySearchResults({
    Key? key,
    required this.tab,
  }) : super(key: key);

  @override
  State<TantivySearchResults> createState() => _TantivySearchResultsState();
}

class _TantivySearchResultsState extends State<TantivySearchResults> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      return BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.searchQuery.isEmpty) {
            return const Center(child: Text("לא בוצע חיפוש"));
          }
          if (state.results.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('אין תוצאות'),
            ));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            '${state.results.length} תוצאות מתוך ${state.totalResults}',
                          ),
                        ),
                      ),
                      if (constrains.maxWidth > 800)
                        OrderOfResults(widget: widget),
                      if (constrains.maxWidth > 800)
                        NumOfResults(tab: widget.tab),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.results.length,
                  itemBuilder: (context, index) {
                    final result = state.results[index];
                    return ListTile(
                      onTap: () {
                        if (result.isPdf) {
                          context.read<TabsBloc>().add(AddTab(
                                PdfBookTab(
                                  book: PdfBook(
                                      title: result.title,
                                      path: result.filePath),
                                  initialPage: result.segment.toInt() + 1,
                                ),
                              ));
                        } else {
                          context.read<TabsBloc>().add(AddTab(
                                TextBookTab(
                                    book: TextBook(
                                      title: result.title,
                                    ),
                                    index: result.segment.toInt(),
                                    searchText:
                                        widget.tab.queryController.text),
                              ));
                        }
                      },
                      title: Text('[תוצאה ${index + 1}] ${result.reference}'),
                      subtitle: Html(data: result.text, style: {
                        'body': Style(
                            fontSize: FontSize(
                              context.read<SettingsBloc>().state.fontSize,
                            ),
                            fontFamily:
                                context.read<SettingsBloc>().state.fontFamily,
                            textAlign: TextAlign.justify),
                      }),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
