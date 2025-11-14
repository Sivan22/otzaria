import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/text_book/models/search_results.dart';
import 'package:otzaria/text_book/models/text_book_searcher.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:otzaria/widgets/search_pane_base.dart';
import 'package:otzaria/i18n/translations.g.dart';

class _GroupedResultItem {
  final String? header;
  final TextSearchResult? result;
  const _GroupedResultItem.header(this.header) : result = null;
  const _GroupedResultItem.result(this.result) : header = null;
  bool get isHeader => header != null;
}

class TextBookSearchView extends StatefulWidget {
  final String data;
  final ItemScrollController scrollControler;
  final FocusNode focusNode;
  final void Function() closeLeftPaneCallback;

  const TextBookSearchView(
      {super.key,
      required this.data,
      required this.scrollControler,
      required this.focusNode,
      required this.closeLeftPaneCallback,
      required String initialQuery});

  @override
  TextBookSearchViewState createState() => TextBookSearchViewState();
}

class TextBookSearchViewState extends State<TextBookSearchView>
    with AutomaticKeepAliveClientMixin<TextBookSearchView> {
  TextEditingController searchTextController = TextEditingController();
  late final TextBookSearcher markdownTextSearcher;
  List<TextSearchResult> searchResults = [];
  late ItemScrollController scrollControler;

  @override
  void initState() {
    super.initState();
    markdownTextSearcher = TextBookSearcher(widget.data);
    markdownTextSearcher.addListener(_searchResultUpdated);

    searchTextController.text =
        (context.read<TextBookBloc>().state as TextBookLoaded).searchText;

    scrollControler = widget.scrollControler;
    widget.focusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialSearch();
    });
  }

  void _runInitialSearch() {
    _searchTextUpdated();
  }

  void _searchTextUpdated() {
    markdownTextSearcher.startTextSearch(searchTextController.text);
  }

  void _searchResultUpdated() {
    if (mounted) {
      setState(() {
        searchResults = markdownTextSearcher.searchResults;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // יצירת רשימה מקובצת - כותרת מופיעה רק כשהיא משתנה
    final List<_GroupedResultItem> items = [];
    String? lastAddress;
    for (final r in searchResults) {
      if (lastAddress != r.address) {
        items.add(_GroupedResultItem.header(r.address));
        lastAddress = r.address;
      }
      items.add(_GroupedResultItem.result(r));
    }

    return SearchPaneBase(
      searchController: searchTextController,
      focusNode: widget.focusNode,
      progressWidget: null,
      resultCountString: searchResults.isNotEmpty
          ? context.t.search.resultsCount(count: searchResults.length.toString())
          : null,
      resultsWidget: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          // אם זו כותרת קבוצה
          if (item.isHeader) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, settingsState) {
                String text = item.header!;
                if (settingsState.replaceHolyNames) {
                  text = utils.replaceHolyNames(text);
                }
                return Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    bottom: 8.0,
                    right: 4.0,
                    left: 4.0,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.text_align_right_24_regular,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
          
          // אם זו תוצאה רגילה
          final result = item.result!;
          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              String snippet = result.snippet;
              
              if (settingsState.replaceHolyNames) {
                snippet = utils.replaceHolyNames(snippet);
              }

              // יצירת TextSpans עם הדגשה של מילות החיפוש
              final highlightedSnippet = _buildHighlightedText(
                snippet,
                result.query,
                settingsState,
                context,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    widget.scrollControler.scrollTo(
                      index: result.index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.ease,
                    );
                    if (Platform.isAndroid) {
                      widget.closeLeftPaneCallback();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  hoverColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  splashColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: RichText(
                      textAlign: TextAlign.right,
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: settingsState.fontFamily,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.5,
                        ),
                        children: highlightedSnippet,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      isNoResults: searchResults.isEmpty && searchTextController.text.isNotEmpty,
      onSearchTextChanged: (value) {
        context.read<TextBookBloc>().add(UpdateSearchText(value));
        _searchTextUpdated();
      },
      resetSearchCallback: () {},
      hintText: context.t.search.placeholder,
    );
  }

  // פונקציה ליצירת טקסט מודגש
  List<InlineSpan> _buildHighlightedText(
    String text,
    String query,
    SettingsState settingsState,
    BuildContext context,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<InlineSpan> spans = [];
    final searchTerms = query.trim().split(RegExp(r'\s+'));
    
    final highlightRegex = RegExp(
      searchTerms.map(RegExp.escape).join('|'),
      caseSensitive: false,
    );

    int currentPosition = 0;

    for (final match in highlightRegex.allMatches(text)) {
      // טקסט רגיל לפני ההדגשה
      if (match.start > currentPosition) {
        spans.add(TextSpan(
          text: text.substring(currentPosition, match.start),
        ));
      }
      // הטקסט המודגש
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Color(0xFFD32F2F), // צבע אדום חזק למילות החיפוש
        ),
      ));
      currentPosition = match.end;
    }

    // טקסט רגיל אחרי ההדגשה האחרונה
    if (currentPosition < text.length) {
      spans.add(TextSpan(
        text: text.substring(currentPosition),
      ));
    }

    return spans;
  }

  @override
  bool get wantKeepAlive => true;
}
