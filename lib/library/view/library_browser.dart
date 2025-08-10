import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/focus/focus_repository.dart';
import 'package:otzaria/library/bloc/library_bloc.dart';
import 'package:otzaria/library/bloc/library_event.dart';
import 'package:otzaria/library/bloc/library_state.dart';
import 'package:otzaria/navigation/bloc/navigation_bloc.dart';
import 'package:otzaria/navigation/bloc/navigation_event.dart';
import 'package:otzaria/navigation/bloc/navigation_state.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/bloc/tabs_bloc.dart';
import 'package:otzaria/tabs/bloc/tabs_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/library/models/library.dart';
import 'package:otzaria/tabs/models/pdf_tab.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/daf_yomi/daf_yomi_helper.dart';
import 'package:otzaria/file_sync/file_sync_bloc.dart';
import 'package:otzaria/file_sync/file_sync_repository.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/daf_yomi/daf_yomi.dart';
import 'package:otzaria/file_sync/file_sync_widget.dart';
import 'package:otzaria/widgets/filter_list/src/filter_list_dialog.dart';
import 'package:otzaria/widgets/filter_list/src/theme/filter_list_theme.dart';
import 'package:otzaria/library/view/grid_items.dart';
import 'package:otzaria/library/view/otzar_book_dialog.dart';
import 'package:otzaria/workspaces/view/workspace_switcher_dialog.dart';
import 'package:otzaria/history/history_dialog.dart';
import 'package:otzaria/history/bloc/history_bloc.dart';
import 'package:otzaria/history/bloc/history_event.dart';
import 'package:otzaria/bookmarks/bookmarks_dialog.dart';
import 'package:otzaria/widgets/workspace_icon_button.dart';

class LibraryBrowser extends StatefulWidget {
  const LibraryBrowser({Key? key}) : super(key: key);

  @override
  State<LibraryBrowser> createState() => _LibraryBrowserState();
}

class _LibraryBrowserState extends State<LibraryBrowser>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _depth = 0;
  @override
  void initState() {
    super.initState();
    context.read<LibraryBloc>().add(LoadLibrary());
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    Text('טוען ספרייה...'),
                  ],
                ),
              );
            }

            if (state.error != null) {
              return Center(child: Text('Error: ${state.error}'));
            }

            if (state.library == null) {
              return const Center(child: Text('No library data available'));
            }

            return Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        children: [
                          // קבוצה 1: סינכרון
                          BlocProvider(
                            create: (context) => FileSyncBloc(
                              repository: FileSyncRepository(
                                githubOwner: "zevisvei",
                                repositoryName: "otzaria-library",
                                branch: "main",
                              ),
                            ),
                            child: const SyncIconButton(),
                          ),
                          // קו מפריד
                          Container(
                            height: 24,
                            width: 1,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          // קבוצה 2: שולחן עבודה, היסטוריה ומועדפים
                          WorkspaceIconButton(
                            onPressed: () =>
                                _showSwitchWorkspaceDialog(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: 'הצג היסטוריה',
                            onPressed: () => _showHistoryDialog(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark),
                            tooltip: 'הצג מועדפים',
                            onPressed: () => _showBookmarksDialog(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          state.currentCategory?.title ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    DafYomi(
                      onDafYomiTap: (tractate, daf) {
                        openDafYomiBook(context, tractate, ' $daf.');
                      },
                    ),
                  ],
                ),
                leadingWidth: 100,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // קבוצה 1: חזור ובית (צמודים)
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      tooltip: 'חזרה לתיקיה הקודמת',
                      onPressed: () {
                        if (state.currentCategory?.parent != null) {
                          setState(() => _depth = _depth > 0 ? _depth - 1 : 0);
                          context.read<LibraryBloc>().add(NavigateUp());
                          context.read<LibraryBloc>().add(const SearchBooks());
                          _refocusSearchBar(selectAll: true);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.home),
                      tooltip: 'חזרה לתיקיה הראשית',
                      onPressed: () {
                        setState(() => _depth = 0);
                        context.read<LibraryBloc>().add(LoadLibrary());
                        context
                            .read<FocusRepository>()
                            .librarySearchController
                            .clear();
                        _update(context, state, settingsState);
                        _refocusSearchBar(selectAll: true);
                      },
                    ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  _buildSearchBar(state),
                  if (context
                          .read<FocusRepository>()
                          .librarySearchController
                          .text
                          .length >
                      2)
                    _buildTopicsSelection(context, state, settingsState),
                  Expanded(child: _buildContent(state)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar(LibraryState state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final focusRepository = context.read<FocusRepository>();
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: focusRepository.librarySearchController,
                  focusNode:
                      context.read<FocusRepository>().librarySearchFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    constraints: const BoxConstraints(maxWidth: 400),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        focusRepository.librarySearchController.clear();
                        _update(context, state, settingsState);
                        _refocusSearchBar();
                      },
                      icon: const Icon(Icons.cancel),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    ),
                    hintText:
                        'איתור ספר ב${state.currentCategory?.title ?? ""}',
                  ),
                  onChanged: (value) {
                    context.read<LibraryBloc>().add(UpdateSearchQuery(value));
                    context.read<LibraryBloc>().add(const SelectTopics([]));
                    _update(context, state, settingsState);
                  },
                ),
              ),
              if (settingsState.showExternalBooks)
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showFilterDialog(context, state),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopicsSelection(
    BuildContext context,
    LibraryState state,
    SettingsState settingsState,
  ) {
    if (state.searchResults == null) {
      return const SizedBox.shrink();
    }

    final categoryTopics = [
      "תנך",
      "מדרש",
      "משנה",
      "תלמוד בבלי",
      "תלמוד ירושלמי",
      "הלכה",
      "משנה תורה",
      "שולחן ערוך",
      "חסידות",
      "קבלה",
      "ספרי מוסר",
      "שות",
      "ראשונים",
      "אחרונים",
      "מחברי זמננו",
    ];

    final allTopics = _getAllTopics(state.searchResults!);

    final relevantTopics =
        categoryTopics.where((element) => allTopics.contains(element)).toList();

    return FilterListWidget<String>(
      hideSearchField: true,
      controlButtons: const [],
      themeData: FilterListThemeData(
        context,
        wrapAlignment: WrapAlignment.center,
      ),
      onApplyButtonClick: (list) {
        context.read<LibraryBloc>().add(SelectTopics(list ?? []));
        _update(context, state, settingsState);
        _refocusSearchBar();
      },
      validateSelectedItem: (list, item) => list != null && list.contains(item),
      onItemSearch: (item, query) => item == query,
      listData: relevantTopics,
      selectedListData: state.selectedTopics ?? [],
      choiceChipLabel: (p0) => p0,
      hideSelectedTextCount: true,
      choiceChipBuilder: (context, item, isSelected) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: Chip(
          label: Text(item),
          backgroundColor:
              isSelected! ? Theme.of(context).colorScheme.secondary : null,
          labelStyle: TextStyle(
            color:
                isSelected ? Theme.of(context).colorScheme.onSecondary : null,
            fontSize: 11,
          ),
          labelPadding: const EdgeInsets.all(0),
        ),
      ),
    );
  }

  Widget _buildContent(LibraryState state) {
    final items = state.searchResults != null
        ? _buildSearchResults(state.searchResults!)
        : _buildCategoryContent(state.currentCategory!);

    return FutureBuilder<List<Widget>>(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.hasData && snapshot.data!.isEmpty) {
          final focusRepository = context.read<FocusRepository>();
          return Center(
            child: Text(
              focusRepository.librarySearchController.text.isNotEmpty
                  ? 'אין תוצאות עבור "${focusRepository.librarySearchController.text}"'
                  : 'אין פריטים להצגה בתיקייה זו',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          key: PageStorageKey(state.currentCategory),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => snapshot.data![index],
        );
      },
    );
  }

  Future<List<Widget>> _buildSearchResults(List<Book> books) async {
    return [
      Column(
        children: [
          MyGridView(
            items: Future.value(
              books
                  .take(100)
                  .map((book) => _buildBookItem(book, showTopics: true))
                  .toList(),
            ),
          ),
        ],
      ),
    ];
  }

  Future<List<Widget>> _buildCategoryContent(Category category) async {
    List<Widget> items = [];

    category.books.sort((a, b) => a.order.compareTo(b.order));
    category.subCategories.sort((a, b) => a.order.compareTo(b.order));

    if (_depth != 0) {
      // Add books
      items.add(
        MyGridView(
          items: Future.value(
            category.books.map((book) => _buildBookItem(book)).toList(),
          ),
        ),
      );

      // Add subcategories
      for (Category subCategory in category.subCategories) {
        subCategory.books.sort((a, b) => a.order.compareTo(b.order));
        subCategory.subCategories.sort((a, b) => a.order.compareTo(b.order));

        items.add(Center(child: HeaderItem(category: subCategory)));
        items.add(
          MyGridView(
            items: Future.value([
              ...subCategory.books.map((book) => _buildBookItem(book)),
              ...subCategory.subCategories.map(
                (cat) => CategoryGridItem(
                  category: cat,
                  onCategoryClickCallback: () => _openCategory(cat),
                ),
              ),
            ]),
          ),
        );
      }
    } else {
      items.add(
        MyGridView(
          items: Future.value([
            ...category.books.map((book) => _buildBookItem(book)),
            ...category.subCategories.map(
              (cat) => CategoryGridItem(
                category: cat,
                onCategoryClickCallback: () => _openCategory(cat),
              ),
            ),
          ]),
        ),
      );
    }

    return items;
  }

  Widget _buildBookItem(Book book, {bool showTopics = false}) {
    if (book is ExternalBook) {
      return BookGridItem(
        book: book,
        onBookClickCallback: () => _openOtzarBook(book),
        showTopics: showTopics,
      );
    }

    return BookGridItem(
      book: book,
      showTopics: showTopics,
      onBookClickCallback: () => _openBook(book),
    );
  }

  void _openBook(Book book) {
    if (book is PdfBook) {
      context.read<TabsBloc>().add(
            AddTab(
              PdfBookTab(
                book: book,
                pageNumber: 1,
                openLeftPane:
                    (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                        (Settings.getValue<bool>('key-default-sidebar-open') ??
                            false),
              ),
            ),
          );
    } else if (book is TextBook) {
      context.read<TabsBloc>().add(
            AddTab(
              TextBookTab(
                book: book,
                index: 0,
                openLeftPane:
                    (Settings.getValue<bool>('key-pin-sidebar') ?? false) ||
                        (Settings.getValue<bool>('key-default-sidebar-open') ??
                            false),
              ),
            ),
          );
    }
    context.read<NavigationBloc>().add(const NavigateToScreen(Screen.reading));
  }

  void _openCategory(Category category) {
    setState(() => _depth++);
    context.read<LibraryBloc>().add(NavigateToCategory(category));
    _refocusSearchBar();
  }

  void _openOtzarBook(ExternalBook book) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OtzarBookDialog(book: book);
      },
    );
    _refocusSearchBar();
  }

  void _showSwitchWorkspaceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WorkspaceSwitcherDialog(),
    );
  }

  void _showFilterDialog(BuildContext context, LibraryState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, settingsState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text('הצג ספרים מאוצר החכמה'),
                  value: settingsState.showOtzarHachochma,
                  onChanged: (bool? value) {
                    setState(() {
                      context.read<SettingsBloc>().add(
                            UpdateShowOtzarHachochma(value!),
                          );
                      _update(context, state, settingsState);
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('הצג ספרים מהיברובוקס'),
                  value: settingsState.showHebrewBooks,
                  onChanged: (bool? value) {
                    setState(() {
                      context.read<SettingsBloc>().add(
                            UpdateShowHebrewBooks(value!),
                          );
                      _update(context, state, settingsState);
                    });
                  },
                ),
              ],
            );
          },
        ),
      ),
    ).then((_) => _refocusSearchBar());
  }

  List<String> _getAllTopics(List<Book> books) {
    final Set<String> topics = {};
    for (final book in books) {
      topics.addAll(book.topics.split(', '));
    }
    return topics.toList();
  }

  void _update(
    BuildContext context,
    LibraryState state,
    SettingsState settingsState,
  ) {
    context.read<LibraryBloc>().add(
          UpdateSearchQuery(
            context.read<FocusRepository>().librarySearchController.text,
          ),
        );
    context.read<LibraryBloc>().add(
          SearchBooks(
            showHebrewBooks: settingsState.showHebrewBooks,
            showOtzarHachochma: settingsState.showOtzarHachochma,
          ),
        );
    setState(() {});
    _refocusSearchBar();
  }

  void _refocusSearchBar({bool selectAll = false}) {
    final focusRepository = context.read<FocusRepository>();
    focusRepository.requestLibrarySearchFocus(selectAll: selectAll);
  }

  void _showHistoryDialog(BuildContext context) {
    context.read<HistoryBloc>().add(FlushHistory());
    showDialog(
      context: context,
      builder: (context) => const HistoryDialog(),
    );
  }

  void _showBookmarksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const BookmarksDialog(),
    );
  }
}
