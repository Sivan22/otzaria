import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_bloc.dart';
import 'package:otzaria/indexing/bloc/indexing_state.dart';
import 'package:otzaria/search/bloc/search_bloc.dart';
import 'package:otzaria/search/bloc/search_state.dart';
import 'package:otzaria/tabs/models/searching_tab.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/search/view/full_text_settings_widgets.dart';
import 'package:otzaria/search/view/tantivy_search_field.dart';
import 'package:otzaria/search/view/tantivy_search_results.dart';
import 'package:otzaria/search/view/full_text_facet_filtering.dart';

class TantivyFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const TantivyFullTextSearch({Key? key, required this.tab}) : super(key: key);
  @override
  State<TantivyFullTextSearch> createState() => _TantivyFullTextSearchState();
}

class _TantivyFullTextSearchState extends State<TantivyFullTextSearch>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _showIndexWarning = false;

  @override
  void initState() {
    super.initState();
    // Check if indexing is in progress using the IndexingBloc
    final indexingState = context.read<IndexingBloc>().state;
    _showIndexWarning = indexingState is IndexingInProgress;
    
    // Request focus on search field when the widget is first created
    _requestSearchFieldFocus();
  }

  @override
  void didUpdateWidget(TantivyFullTextSearch oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Request focus when switching back to this tab
    _requestSearchFieldFocus();
  }

  void _requestSearchFieldFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.tab.searchFieldFocusNode.canRequestFocus) {
        // Check if this tab is the currently selected tab
        final tabsState = context.read<TabsBloc>().state;
        if (tabsState.hasOpenTabs && 
            tabsState.currentTabIndex < tabsState.tabs.length &&
            tabsState.tabs[tabsState.currentTabIndex] == widget.tab) {
          widget.tab.searchFieldFocusNode.requestFocus();
        }
      }
    });
  }

  void _onNavigationChanged(NavigationState state) {
    // Request focus when navigating to search screen
    if (state.currentScreen == Screen.search
    || state.currentScreen == Screen.reading) {
      _requestSearchFieldFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) => _onNavigationChanged(state),
      child: Scaffold(
        body: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 800) return _buildForSmallScreens();
          return _buildForWideScreens();
        }),
      ),
    );
  }

  Widget _buildForSmallScreens() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Column(children: [
          if (_showIndexWarning) _buildIndexWarning(),
          Row(
            children: [
              _buildMenuButton(),
              Expanded(child: TantivySearchField(widget: widget)),
            ],
          ),
          Expanded(
            child: Stack(
              children: [
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.searchQuery.isEmpty)
                  const Center(child: Text("לא בוצע חיפוש"))
                else if (state.results.isEmpty)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('אין תוצאות'),
                  ))
                else
                  TantivySearchResults(tab: widget.tab),
                ValueListenableBuilder(
                    valueListenable: widget.tab.isLeftPaneOpen,
                    builder: (context, value, child) => AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: value ? 500 : 0,
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    FuzzyDistance(tab: widget.tab),
                                    NumOfResults(tab: widget.tab),
                                  ],
                                ),
                                FuzzyToggle(tab: widget.tab),
                                Expanded(
                                  child: SearchFacetFiltering(
                                    tab: widget.tab,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )))
              ],
            ),
          )
        ]);
      },
    );
  }

  Column _buildForWideScreens() {
    return Column(children: [
      if (_showIndexWarning) _buildIndexWarning(),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: TantivySearchField(widget: widget),
          ),
          FuzzyDistance(tab: widget.tab),
          FuzzyToggle(tab: widget.tab)
        ],
      ),
      Expanded(
        child: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            return Row(
              children: [
                SizedBox(
                  width: 350,
                  child: SearchFacetFiltering(tab: widget.tab),
                ),
                Expanded(
                  child: Builder(builder: (context) {
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
                    return TantivySearchResults(tab: widget.tab);
                  }),
                )
              ],
            );
          },
        ),
      )
    ]);
  }

  Widget _buildMenuButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      child: IconButton(
        tooltip: "הגדרות חיפוש",
        icon: const Icon(Icons.menu),
        onPressed: () {
          widget.tab.isLeftPaneOpen.value = !widget.tab.isLeftPaneOpen.value;
        },
      ),
    );
  }

  Container _buildIndexWarning() {
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
              'אינדקס החיפוש בתהליך עידכון. חלק מהספרים עלולים להיות חסרים בתוצאות החיפוש.',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _showIndexWarning = false;
              });
            },
          )
        ],
      ),
    );
  }
}
