import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
import 'package:otzaria/search/view/tantivy_search_results.dart';
import 'package:otzaria/search/view/full_text_facet_filtering.dart';
import 'package:otzaria/widgets/resizable_facet_filtering.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/i18n/translations.g.dart';

class TantivyFullTextSearch extends StatefulWidget {
  final SearchingTab tab;
  const TantivyFullTextSearch({super.key, required this.tab});
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
    if (state.currentScreen == Screen.search ||
        state.currentScreen == Screen.reading) {
      _requestSearchFieldFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocListener<NavigationBloc, NavigationState>(
      listener: (context, state) => _onNavigationChanged(state),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) return _buildForSmallScreens();
            return _buildForWideScreens();
          },
        ),
      ),
    );
  }

  Widget _buildForSmallScreens() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              if (_showIndexWarning) _buildIndexWarning(),
              Row(children: [_buildMenuButton()]),
              // השורה התחתונה - מוצגת תמיד!
              _buildBottomRow(state),
              _buildDivider(),
              Expanded(
                child: Stack(
                  children: [
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state.searchQuery.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FluentIcons.search_24_regular,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.t.search
                                  .noSearchPerformed, // Old: "לא בוצע חיפוש"
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.t.search
                                  .startNewSearch, // Old: "לחץ על 'חיפוש חדש' כדי להתחיל"
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (state.results.isEmpty)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(context
                              .t.search.noResultsShort), // Old: 'אין תוצאות'
                        ),
                      )
                    else
                      Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: TantivySearchResults(tab: widget.tab),
                      ),
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
                                Expanded(
                                  child: SearchFacetFiltering(tab: widget.tab),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildForWideScreens() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: Column(
        children: [
          if (_showIndexWarning) _buildIndexWarning(),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                return Column(
                  children: [
                    // שורה אחת פשוטה
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        children: [
                          // כפתור תפריט
                          IconButton(
                            tooltip: context.t.search
                                .showHideTree, // Old: "הצג/הסתר עץ ספרים"
                            icon: const Icon(
                              FluentIcons.line_horizontal_3_20_regular,
                            ),
                            onPressed: () {
                              widget.tab.isLeftPaneOpen.value =
                                  !widget.tab.isLeftPaneOpen.value;
                            },
                          ),
                          // רווח כשהעץ פתוח
                          ValueListenableBuilder(
                            valueListenable: widget.tab.isLeftPaneOpen,
                            builder: (context, isOpen, child) {
                              if (!isOpen) {
                                return const SizedBox.shrink();
                              }
                              final width = context
                                  .watch<SettingsBloc>()
                                  .state
                                  .facetFilteringWidth;
                              return SizedBox(width: width);
                            },
                          ),
                          // מילות חיפוש + בקרות
                          Expanded(
                            child: BlocBuilder<SearchBloc, SearchState>(
                              builder: (context, searchState) {
                                if (searchState.searchQuery.isEmpty) {
                                  return const SizedBox.shrink();
                                }

                                return Row(
                                  children: [
                                    // הודעת "מוצגות תוצאות של חיפוש" - רק בחיפוש מתקדם
                                    if (searchState.isAdvancedSearchEnabled)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 16.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              context.t.search
                                                  .showingResultsFor, // Old: 'מוצגות תוצאות של חיפוש: '
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SearchTermsDisplay(
                                              tab: widget.tab,
                                            ),
                                          ],
                                        ),
                                      ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Text(
                                        context.t.search.resultsCount(
                                          count:
                                              '${searchState.results.length}/${searchState.totalResults}',
                                        ), // Old: '${searchState.results.length}/${searchState.totalResults} תוצאות'
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ),
                                    OrderOfResults(
                                      widget: TantivySearchResults(
                                        tab: widget.tab,
                                      ),
                                    ),
                                    NumOfResults(tab: widget.tab),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDivider(),
                    Expanded(
                      child: Row(
                        children: [
                          // עץ הסינון - עם אפשרות להסתיר/להציג
                          ValueListenableBuilder(
                            valueListenable: widget.tab.isLeftPaneOpen,
                            builder: (context, isOpen, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: isOpen ? null : 0,
                                child: isOpen
                                    ? ResizableFacetFiltering(tab: widget.tab)
                                    : const SizedBox.shrink(),
                              );
                            },
                          ),
                          // תוצאות החיפוש
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Builder(
                                    builder: (context) {
                                      if (state.isLoading) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      if (state.searchQuery.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                FluentIcons.search_24_regular,
                                                size: 64,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                context.t.search
                                                    .noSearchPerformed, // Old: "לא בוצע חיפוש"
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                context.t.search
                                                    .startNewSearchWide, // Old: "לחץ על כפתור 'חיפוש' בתפריט כדי להתחיל"
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      if (state.results.isEmpty) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(context.t.search
                                                .noResultsShort), // Old: 'אין תוצאות'
                                          ),
                                        );
                                      }
                                      return Container(
                                        clipBehavior: Clip.hardEdge,
                                        decoration: const BoxDecoration(),
                                        child: TantivySearchResults(
                                          tab: widget.tab,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
      child: IconButton(
        tooltip: "הגדרות חיפוש",
        icon: const Icon(FluentIcons.navigation_24_regular),
        onPressed: () {
          widget.tab.isLeftPaneOpen.value = !widget.tab.isLeftPaneOpen.value;
        },
      ),
    );
  }

  // השורה העליונה - רק כפתור תפריט
  Widget _buildBottomRow(SearchState state) {
    return Container(
      height: 60, // גובה קבוע
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        children: [
          // כפתור פתיחה/סגירה של עץ הספרים - שלושה פסים
          IconButton(
            tooltip: context.t.search.showHideTree, // Old: "הצג/הסתר עץ ספרים"
            icon: const Icon(FluentIcons.line_horizontal_3_20_regular),
            onPressed: () {
              widget.tab.isLeftPaneOpen.value =
                  !widget.tab.isLeftPaneOpen.value;
            },
          ),
        ],
      ),
    );
  }

  // פס מפריד מתחת לשורה התחתונה
  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
          Icon(FluentIcons.warning_24_regular, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.t.search
                  .indexUpdating, // Old: 'אינדקס החיפוש בתהליך עדכון. יתכן שחלק מהספרים לא יוצגו בתוצאות החיפוש.'
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.black87),
            ),
          ),
          IconButton(
            icon: const Icon(FluentIcons.dismiss_24_regular),
            onPressed: () {
              setState(() {
                _showIndexWarning = false;
              });
            },
          ),
        ],
      ),
    );
  }
}
