import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_state.dart';
import 'package:otzaria/tabs/models/text_tab.dart';
import 'package:otzaria/text_book/bloc/text_book_bloc.dart';
import 'package:otzaria/text_book/bloc/text_book_event.dart';
import 'package:otzaria/text_book/bloc/text_book_state.dart';
import 'package:otzaria/data/repository/data_repository.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/printing/printing_screen.dart';
import 'package:otzaria/text_book/view/combined_view/combined_book_screen.dart';
import 'package:otzaria/text_book/view/commentators_list_screen.dart';
import 'package:otzaria/text_book/view/links_screen.dart';
import 'package:otzaria/text_book/view/splited_view/splited_view_screen.dart';
import 'package:otzaria/text_book/view/text_book_search_screen.dart';
import 'package:otzaria/text_book/view/toc_navigator_screen.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:url_launcher/url_launcher.dart';

class TextBookViewerBloc extends StatefulWidget {
  final void Function(OpenedTab) openBookCallback;
  final TextBookTab tab;

  const TextBookViewerBloc({
    Key? key,
    required this.openBookCallback,
    required this.tab,
  }) : super(key: key);

  @override
  State<TextBookViewerBloc> createState() => _TextBookViewerBlocState();
}

class _TextBookViewerBlocState extends State<TextBookViewerBloc>
    with TickerProviderStateMixin {
  final FocusNode textSearchFocusNode = FocusNode();
  final FocusNode navigationSearchFocusNode = FocusNode();
  late TabController tabController;

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    textSearchFocusNode.dispose();
    navigationSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextBookBloc, TextBookState>(
      bloc: context.read<TextBookBloc>(),
      builder: (context, state) {
        if (state is TextBookInitial) {
          context.read<TextBookBloc>().add(LoadContent());
        }
        if (state is TextBookInitial || state is TextBookLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is TextBookError) {
          return Center(child: Text('Error: ${(state).message}'));
        }

        if (state is TextBookLoaded) {
          return LayoutBuilder(builder: (context, constrains) {
            final wideScreen = (MediaQuery.of(context).size.width >= 600);
            return Scaffold(
              appBar: _buildAppBar(context, state, wideScreen),
              body: _buildBody(context, state, wideScreen),
            );
          });
        }

        // Fallback
        return const Center(child: Text('Unknown state'));
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, TextBookLoaded state, bool wideScreen) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: Border(
        bottom: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 0.3,
        ),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,

      title: _buildTitle(state),
      leading: _buildMenuButton(context, state),
      actions: _buildActions(context, state, wideScreen),
    );
  }

  Widget _buildTitle(TextBookLoaded state) {
    return state.currentTitle != null
      ? SelectionArea(
              child: Text(
                state.currentTitle!,
                style: const TextStyle(fontSize: 17),
                textAlign: TextAlign.end,
              ),
            )
        : const SizedBox.shrink();
  }

  Widget _buildMenuButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: "ניווט וחיפוש",
      onPressed: () => context.read<TextBookBloc>().add(
            ToggleLeftPane(!state.showLeftPane),
          ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context, TextBookLoaded state, bool wideScreen) {
    return [
      // PDF Button
      _buildPdfButton(context, state),

      // Split View Button
      _buildSplitViewButton(context, state),

      // Nikud Button
      _buildNikudButton(context, state),

      // Bookmark Button
      _buildBookmarkButton(context, state),

      // Search Button (wide screen only)
      if (wideScreen) _buildSearchButton(context, state),

      // Zoom Buttons (wide screen only)
      if (wideScreen) ...[
        _buildZoomInButton(context, state),
        _buildZoomOutButton(context, state),
      ],

      // Navigation Buttons (wide screen only)
      if (wideScreen) ...[
        _buildFirstPageButton(state),
        _buildPreviousPageButton(state),
        _buildNextPageButton(state),
        _buildLastPageButton(state),
      ],

      // Print Button
      _buildPrintButton(context, state),

      // Report Bug Button
      _buildReportBugButton(context, state),
    ];
  }

  Widget _buildPdfButton(BuildContext context, TextBookLoaded state) {
    return FutureBuilder(
      future: DataRepository.instance.library.then(
          (library) => library.findBookByTitle(state.book.title, PdfBook)),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'פתח ספר במהדורה מודפסת ',
              onPressed: () async {
                final library = DataRepository.instance.library;
                final book = await library.then((library) =>
                    library.findBookByTitle(state.book.title, PdfBook));
                final index = await textToPdfPage(
                  state.book,
                  state.positionsListener.itemPositions.value.isNotEmpty
                      ? state.positionsListener.itemPositions.value.first.index
                      : 0,
                );
                openBook(context, book!, index ?? 0, '');
              },
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSplitViewButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () => context.read<TextBookBloc>().add(
            ToggleSplitView(!state.showSplitView),
          ),
      icon: Icon(
        !state.showSplitView
            ? Icons.vertical_split_outlined
            : Icons.horizontal_split_outlined,
      ),
      tooltip: !state.showSplitView
          ? ' הצגת מפרשים בצד הטקסט'
          : 'הצגת מפרשים מתחת הטקסט',
    );
  }

  Widget _buildNikudButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () => context.read<TextBookBloc>().add(
            ToggleNikud(!state.removeNikud),
          ),
      icon: const Icon(Icons.format_overline),
      tooltip: 'הצג או הסתר ניקוד',
    );
  }

  Widget _buildBookmarkButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () async {
        int index = state.positionsListener.itemPositions.value.first.index;
        final toc = state.book.tableOfContents;
        String ref = await refFromIndex(index, toc);
        bool bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
            ref: ref,
            book: state.book,
            index: index,
            commentatorsToShow: state.activeCommentators);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת'),
            ),
          );
        }
      },
      icon: const Icon(Icons.bookmark_add),
      tooltip: 'הוספת סימניה',
    );
  }

  Widget _buildSearchButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () {
        context.read<TextBookBloc>().add(const ToggleLeftPane(true));
        tabController.index = 1;
        textSearchFocusNode.requestFocus();
      },
      icon: const Icon(Icons.search),
      tooltip: 'חיפוש',
    );
  }

  Widget _buildZoomInButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.zoom_in),
      tooltip: 'הגדלת טקסט',
      onPressed: () => context.read<TextBookBloc>().add(
            UpdateFontSize(min(50.0, state.fontSize + 3)),
          ),
    );
  }

  Widget _buildZoomOutButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.zoom_out),
      tooltip: 'הקטנת טקסט',
      onPressed: () => context.read<TextBookBloc>().add(
            UpdateFontSize(max(15.0, state.fontSize - 3)),
          ),
    );
  }

  Widget _buildFirstPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.first_page),
      tooltip: 'תחילת הספר',
      onPressed: () {
        state.scrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildPreviousPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.navigate_before),
      tooltip: 'הקטע הקודם',
      onPressed: () {
        state.scrollController.scrollTo(
          duration: const Duration(milliseconds: 300),
          index: max(
            0,
            state.positionsListener.itemPositions.value.first.index - 1,
          ),
        );
      },
    );
  }

  Widget _buildNextPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.navigate_next),
      tooltip: 'הקטע הבא',
      onPressed: () {
        state.scrollController.scrollTo(
          index: max(
            state.positionsListener.itemPositions.value.first.index + 1,
            state.positionsListener.itemPositions.value.length - 1,
          ),
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildLastPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.last_page),
      tooltip: 'סוף הספר',
      onPressed: () {
        state.scrollController.scrollTo(
          index: state.content.length,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildPrintButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.print),
      tooltip: 'הדפסה',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PrintingScreen(
            data: Future.value(state.content.join('\n')),
            startLine: state.visibleIndices.first,
            removeNikud: state.removeNikud,
          ),
        ),
      ),
    );
  }

  Widget _buildReportBugButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(Icons.error_outline),
      tooltip: 'דווח על טעות בספר',
      onPressed: () => _showReportBugDialog(context, state),
    );
  }

  Future<void> _showReportBugDialog(
      BuildContext context, TextBookLoaded state) async {
    final currentRef = await refFromIndex(
      state.positionsListener.itemPositions.value.isNotEmpty
          ? state.positionsListener.itemPositions.value.first.index
          : 0,
      state.book.tableOfContents,
    );

    final bookDetails = await _getBookDetails(state.book.title);
    final allText = state.content;
    final visiblePositions = state.positionsListener.itemPositions.value
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final visibleText = visiblePositions
        .map((pos) => utils.stripHtmlIfNeeded(allText[pos.index]))
        .join('\n');

    if (!mounted) return;

    final selectedText = await _showTextSelectionDialog(
      context,
      visibleText,
      state.fontSize,
    );

    if (selectedText == null || selectedText.isEmpty) return;
    if (!mounted) return;

    final shouldProceed = await _showConfirmationDialog(
      context,
      selectedText,
    );

    if (shouldProceed != true) return;

    final emailAddress =
        bookDetails['תיקיית המקור']?.contains('sefaria') == true
            ? 'corrections@sefaria.org'
            : 'otzaria.200@gmail.com';

    final emailUri = Uri(
      scheme: 'mailto',
      path: emailAddress,
      query: encodeQueryParameters(<String, String>{
        'subject': 'דיווח על טעות: ${state.book.title}',
        'body': _buildEmailBody(
          state.book.title,
          currentRef,
          bookDetails,
          selectedText,
        ),
      }),
    );

    try {
      if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('לא ניתן לפתוח את תוכנת הדואר'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('לא ניתן לפתוח את תוכנת הדואר'),
          ),
        );
      }
    }
  }

  Future<String?> _showTextSelectionDialog(
      BuildContext context, String text, double fontSize) async {
    String? selectedContent;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('בחר את הטקסט שבו יש טעות'),
              content: SizedBox(
                width: double.maxFinite,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('סמן את הטקסט שבו נמצאת הטעות:'),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            text,
                            style: TextStyle(
                              fontSize: fontSize,
                              fontFamily:
                                  Settings.getValue('key-font-family') ??
                                      'candara',
                            ),
                            onSelectionChanged: (selection, cause) {
                              if (selection.start != selection.end) {
                                final newContent = text.substring(
                                    selection.start, selection.end);
                                if (newContent.isNotEmpty) {
                                  setDialogState(() {
                                    selectedContent = newContent;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('ביטול'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: selectedContent == null || selectedContent!.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(selectedContent),
                  child: const Text('המשך'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String selectedText) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('דיווח על טעות בספר'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'הטקסט שנבחר:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(selectedText),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('פתיחת דוא"ל'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
  }

  String _buildEmailBody(String bookTitle, String currentRef,
      Map<String, String> bookDetails, String selectedText) {
    return '''שם הספר: $bookTitle
מיקום: $currentRef
שם הקובץ: ${bookDetails['שם הקובץ']}
נתיב הקובץ: ${bookDetails['נתיב הקובץ']}
תיקיית המקור: ${bookDetails['תיקיית המקור']}

הטקסט שבו נמצאה הטעות:
$selectedText

פירוט הטעות:
''';
  }

  Future<Map<String, String>> _getBookDetails(String bookTitle) async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      final file = File(
          '$libraryPath${Platform.pathSeparator}אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}SourcesBooks.csv');
      if (await file.exists()) {
        final contents = await file.readAsString();
        final lines = contents.split('\n');

        for (var i = 1; i < lines.length; i++) {
          final parts = lines[i].split(',');
          if (parts.length >= 3) {
            final fileName = parts[0].replaceAll('.txt', '');
            if (fileName == bookTitle) {
              return {
                'שם הקובץ': parts[0],
                'נתיב הקובץ': parts[1],
                'תיקיית המקור': parts[2],
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading sourcebooks.csv: $e');
    }
    return {
      'שם הקובץ': 'לא ניתן למצוא את הספר',
      'נתיב הקובץ': 'לא ניתן למצוא את הספר',
      'תיקיית המקור': 'לא ניתן למצוא את הספר'
    };
  }

  Widget _buildBody(
      BuildContext context, TextBookLoaded state, bool wideScreen) {
    return LayoutBuilder(
      builder: (context, constraints) => MediaQuery.of(context).size.width < 600
          ? Stack(
              children: [
                _buildHTMLViewer(state),
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildTabBar(state),
                ),
              ],
            )
          : Row(
              children: [
                _buildTabBar(state),
                Expanded(child: _buildHTMLViewer(state)),
              ],
            ),
    );
  }

  Widget _buildHTMLViewer(TextBookLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 5, 5),
      child: GestureDetector(
        onScaleUpdate: (details) {
          context.read<TextBookBloc>().add(
                UpdateFontSize(
                  (state.fontSize * details.scale).clamp(15, 60),
                ),
              );
        },
        child: NotificationListener<UserScrollNotification>(
          onNotification: (scrollNotification) {
            if (!state.pinLeftPane) {
              Future.microtask(() {
                context.read<TextBookBloc>().add(const ToggleLeftPane(false));
              });
            }
            return false;
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              LogicalKeySet(
                  LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): () {
                context.read<TextBookBloc>().add(const ToggleLeftPane(true));
                tabController.index = 1;
                textSearchFocusNode.requestFocus();
              },
            },
            child: Focus(
              focusNode: FocusNode(),
              autofocus: !Platform.isAndroid,
              child: _buildSplitedOrCombinedView(state),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitedOrCombinedView(TextBookLoaded state) {
    if (state.showSplitView && state.activeCommentators.isNotEmpty) {
      return SplitedViewScreen(
        content: state.content,
        openBookCallback: widget.openBookCallback,
        searchTextController: TextEditingValue(text: state.searchText),
        tab: widget.tab,
      );
    }

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Padding(
          padding: state.showLeftPane
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: settingsState.paddingSize),
          child: _buildCombinedView(state),
        );
      },
    );
  }

  Widget _buildCombinedView(TextBookLoaded state) {
    return CombinedView(
      data: state.content,
      textSize: state.fontSize,
      openBookCallback: widget.openBookCallback,
      showSplitedView: ValueNotifier(state.showSplitView),
      tab: widget.tab,
    );
  }

  Widget _buildTabBar(TextBookLoaded state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.showLeftPane && !Platform.isAndroid) {
        if (tabController.index == 1) {
          textSearchFocusNode.requestFocus();
        } else if (tabController.index == 0) {
          navigationSearchFocusNode.requestFocus();
        }
      }
    });
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: state.showLeftPane ? 400 : 0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TabBar(
                      tabs: const [
                        Tab(text: 'ניווט'),
                        Tab(text: 'חיפוש'),
                        Tab(text: 'פרשנות'),
                        Tab(text: 'קישורים')
                      ],
                      controller: tabController,
                      onTap: (value) {
                        if (value == 1 && !Platform.isAndroid) {
                          textSearchFocusNode.requestFocus();
                        } else if (value == 0 && !Platform.isAndroid) {
                          navigationSearchFocusNode.requestFocus();
                        }
                      },
                    ),
                  ),
                  if (MediaQuery.of(context).size.width >= 600)
                    IconButton(
                      onPressed: () => context.read<TextBookBloc>().add(
                            TogglePinLeftPane(!state.pinLeftPane),
                          ),
                      icon: const Icon(Icons.push_pin),
                      isSelected: state.pinLeftPane,
                    ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    _buildTocViewer(context, state),
                    CallbackShortcuts(
                      bindings: <ShortcutActivator, VoidCallback>{
                        LogicalKeySet(LogicalKeyboardKey.control,
                            LogicalKeyboardKey.keyF): () {
                          context
                              .read<TextBookBloc>()
                              .add(const ToggleLeftPane(true));
                          tabController.index = 1;
                          textSearchFocusNode.requestFocus();
                        },
                      },
                      child: _buildSearchView(context, state),
                    ),
                    _buildCommentaryView(),
                    _buildLinkView(context, state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchView(BuildContext context, TextBookLoaded state) {
    return TextBookSearchView(
      focusNode: textSearchFocusNode,
      data: state.content.join('\n'),
      scrollControler: state.scrollController,
      closeLeftPaneCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
    );
  }

  Widget _buildTocViewer(BuildContext context, TextBookLoaded state) {
    return TocViewer(
      scrollController: state.scrollController,
      focusNode: navigationSearchFocusNode,
      closeLeftPaneCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
    );
  }

  Widget _buildLinkView(BuildContext context, TextBookLoaded state) {
    return LinksViewer(
      openTabcallback: widget.openBookCallback,
      itemPositionsListener: state.positionsListener,
      closeLeftPanelCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
    );
  }

  Widget _buildCommentaryView() {
    return const CommentatorsListView();
  }
}
