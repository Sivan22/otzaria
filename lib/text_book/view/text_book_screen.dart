import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_settings_screens/flutter_settings_screens.dart';
import 'package:otzaria/bookmarks/bloc/bookmark_bloc.dart';
import 'package:otzaria/settings/settings_bloc.dart';
import 'package:otzaria/settings/settings_event.dart' hide UpdateFontSize;
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

/// נתוני הדיווח שנאספו מתיבת סימון הטקסט + פירוט הטעות שהמשתמש הקליד.
class ReportedErrorData {
  final String selectedText; // הטקסט שסומן ע"י המשתמש
  final String errorDetails; // פירוט הטעות (שדה טקסט נוסף)
  const ReportedErrorData(
      {required this.selectedText, required this.errorDetails});
}

/// פעולה שנבחרה בדיאלוג האישור.
enum ReportAction {
  cancel,
  sendEmail,
  saveForLater,
}

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
  late final ValueNotifier<double> _sidebarWidth;
  late final StreamSubscription<SettingsState> _settingsSub;
  static const String _reportFileName = 'דיווח שגיאות בספרים.txt';
  static const String _reportSeparator = '==============================';
  static const String _reportSeparator2 = '------------------------------';
  static const String _fallbackMail = 'otzaria.200@gmail.com';

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  @override
  void initState() {
    super.initState();

    // אם יש טקסט חיפוש (searchText), נתחיל בלשונית 'חיפוש' (שנמצאת במקום ה-1)
    // אחרת, נתחיל בלשונית 'ניווט' (שנמצאת במקום ה-0)
    final int initialIndex = widget.tab.searchText.isNotEmpty ? 1 : 0;

    // יוצרים את בקר הלשוניות עם האינדקס ההתחלתי שקבענו
    tabController = TabController(
      length: 4, // יש 4 לשוניות
      vsync: this,
      initialIndex: initialIndex,
    );

    _sidebarWidth = ValueNotifier<double>(
        Settings.getValue<double>('key-sidebar-width', defaultValue: 300)!);
    _settingsSub = context
        .read<SettingsBloc>()
        .stream
        .listen((state) => _sidebarWidth.value = state.sidebarWidth);
  }

  @override
  void dispose() {
    tabController.dispose();
    textSearchFocusNode.dispose();
    navigationSearchFocusNode.dispose();
    _sidebarWidth.dispose();
    _settingsSub.cancel();
    super.dispose();
  }

  void _openLeftPaneTab(int index) {
    context.read<TextBookBloc>().add(const ToggleLeftPane(true));
    tabController.index = index;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<TextBookBloc, TextBookState>(
          bloc: context.read<TextBookBloc>(),
          builder: (context, state) {
            if (state is TextBookInitial) {
              context.read<TextBookBloc>().add(
                    LoadContent(
                      fontSize: settingsState.fontSize,
                      showSplitView:
                          Settings.getValue<bool>('key-splited-view') ?? false,
                      removeNikud: settingsState.defaultRemoveNikud,
                    ),
                  );
            }

            if (state is TextBookInitial || state is TextBookLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TextBookError) {
              return Center(child: Text('Error: ${(state).message}'));
            }

            if (state is TextBookLoaded) {
              return LayoutBuilder(
                builder: (context, constrains) {
                  final wideScreen = (MediaQuery.of(context).size.width >= 600);
                  return Scaffold(
                    appBar: _buildAppBar(context, state, wideScreen),
                    body: _buildBody(context, state, wideScreen),
                  );
                },
              );
            }

            // Fallback
            return const Center(child: Text('Unknown state'));
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    TextBookLoaded state,
    bool wideScreen,
  ) {
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
      onPressed: () =>
          context.read<TextBookBloc>().add(ToggleLeftPane(!state.showLeftPane)),
    );
  }

  List<Widget> _buildActions(
    BuildContext context,
    TextBookLoaded state,
    bool wideScreen,
  ) {
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
        (library) => library.findBookByTitle(state.book.title, PdfBook),
      ),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'פתח ספר במהדורה מודפסת ',
              onPressed: () async {
                final library = DataRepository.instance.library;
                final book = await library.then(
                  (library) =>
                      library.findBookByTitle(state.book.title, PdfBook),
                );
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
      onPressed: () =>
          context.read<TextBookBloc>().add(ToggleNikud(!state.removeNikud)),
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
              commentatorsToShow: state.activeCommentators,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת',
              ),
              duration: const Duration(milliseconds: 350),
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
    BuildContext context,
    TextBookLoaded state,
  ) async {
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

    final ReportedErrorData? reportData = await _showTextSelectionDialog(
      context,
      visibleText,
      state.fontSize,
    );

    if (reportData == null) return; // בוטל או לא נבחר טקסט
    if (!mounted) return;

    final ReportAction? action =
        await _showConfirmationDialog(context, reportData);

    if (action == null || action == ReportAction.cancel) return;

    // נבנה את גוף המייל (נעשה שימוש גם לשליחה וגם לשמירה)
    final emailBody = _buildEmailBody(
      state.book.title,
      currentRef,
      bookDetails,
      reportData.selectedText,
      reportData.errorDetails,
    );

    if (action == ReportAction.sendEmail) {
      // בחירת כתובת דוא"ל לקבלת הדיווח
      final emailAddress =
          bookDetails['תיקיית המקור']?.contains('sefaria') == true
              ? 'corrections@sefaria.org'
              : _fallbackMail;

      final emailUri = Uri(
        scheme: 'mailto',
        path: emailAddress,
        query: encodeQueryParameters(<String, String>{
          'subject': 'דיווח על טעות: ${state.book.title}',
          'body': emailBody,
        }),
      );

      try {
        if (!await launchUrl(emailUri, mode: LaunchMode.externalApplication)) {
          _showSimpleSnack('לא ניתן לפתוח את תוכנת הדואר');
        }
      } catch (_) {
        _showSimpleSnack('לא ניתן לפתוח את תוכנת הדואר');
      }
      return;
    }

    if (action == ReportAction.saveForLater) {
      final saved = await _saveReportToFile(emailBody);
      if (!saved) {
        _showSimpleSnack('שמירת הדיווח נכשלה.');
        return;
      }

      final count = await _countReportsInFile();
      _showSavedSnack(count);
      return;
    }
  }

  Future<ReportedErrorData?> _showTextSelectionDialog(
    BuildContext context,
    String text,
    double fontSize,
  ) async {
    String? selectedContent;
    final TextEditingController detailsController = TextEditingController();
    return showDialog<ReportedErrorData>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('בחר את הטקסט שבו יש טעות'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('סמן את הטקסט שבו נמצאת הטעות:'),
                    const SizedBox(height: 8),
                    // השתמשנו ב-ConstrainedBox כדי לתת גובה מקסימלי, במקום Expanded
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
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
                                  selection.start,
                                  selection.end,
                                );
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
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'פירוט הטעות (חובה לפרט מהי הטעות, בלא פירוט לא נוכל לטפל):',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: detailsController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'כתוב כאן מה לא תקין, הצע תיקון וכו\'',
                      ),
                      textDirection: TextDirection.rtl,
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
                      : () => Navigator.of(context).pop(
                            ReportedErrorData(
                              selectedText: selectedContent!,
                              errorDetails: detailsController.text.trim(),
                            ),
                          ),
                  child: const Text('המשך'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<ReportAction?> _showConfirmationDialog(
    BuildContext context,
    ReportedErrorData reportData,
  ) {
    return showDialog<ReportAction>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('דיווח על טעות בספר'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'הטקסט שנבחר:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reportData.selectedText),
                const SizedBox(height: 16),
                if (reportData.errorDetails.isNotEmpty) ...[
                  const Text(
                    'פירוט הטעות:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(reportData.errorDetails),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('ביטול'),
              onPressed: () => Navigator.of(context).pop(ReportAction.cancel),
            ),
            TextButton(
              child: const Text('שמור לדיווח מאוחר'),
              onPressed: () =>
                  Navigator.of(context).pop(ReportAction.saveForLater),
            ),
            TextButton(
              child: const Text('פתיחת דוא"ל'),
              onPressed: () =>
                  Navigator.of(context).pop(ReportAction.sendEmail),
            ),
          ],
        );
      },
    );
  }

  String _buildEmailBody(
    String bookTitle,
    String currentRef,
    Map<String, String> bookDetails,
    String selectedText,
    String errorDetails,
  ) {
    final detailsSection = errorDetails.isEmpty ? '' : '\n$errorDetails';

    return '''
שם הספר: $bookTitle
מיקום: $currentRef
שם הקובץ: ${bookDetails['שם הקובץ']}
נתיב הקובץ: ${bookDetails['נתיב הקובץ']}
תיקיית המקור: ${bookDetails['תיקיית המקור']}

הטקסט שבו נמצאה הטעות:
$selectedText

פירוט הטעות:
$detailsSection
''';
  }

  /// שמירת דיווח לקובץ בתיקייה הראשית של הספרייה (libraryPath).
  Future<bool> _saveReportToFile(String reportContent) async {
    try {
      final libraryPath = Settings.getValue('key-library-path');

      if (libraryPath == null || libraryPath.isEmpty) {
        debugPrint('libraryPath not set; cannot save report.');
        return false;
      }

      final filePath = '$libraryPath${Platform.pathSeparator}$_reportFileName';
      final file = File(filePath);

      final exists = await file.exists();

      final sink = file.openWrite(
        mode: exists ? FileMode.append : FileMode.write,
        encoding: utf8,
      );

      // אם זה קובץ חדש, כתוב את השורה הראשונה עם הוראות השליחה
      if (!exists) {
        sink.writeln('יש לשלוח קובץ זה למייל: $_fallbackMail');
        sink.writeln(_reportSeparator2);
        sink.writeln(''); // שורת רווח
      }

      // אם יש כבר תוכן קודם בקובץ קיים -> הוסף מפריד לפני הרשומה החדשה
      if (exists && (await file.length()) > 0) {
        sink.writeln(''); // שורת רווח
        sink.writeln(_reportSeparator);
        sink.writeln(''); // שורת רווח
      }

      sink.write(reportContent);
      await sink.flush();
      await sink.close();
      return true;
    } catch (e) {
      debugPrint('Failed saving report: $e');
      return false;
    }
  }

  /// סופר כמה דיווחים יש בקובץ – לפי המפריד.
  Future<int> _countReportsInFile() async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      if (libraryPath == null || libraryPath.isEmpty) return 0;

      final filePath = '$libraryPath${Platform.pathSeparator}$_reportFileName';
      final file = File(filePath);
      if (!await file.exists()) return 0;

      final content = await file.readAsString(encoding: utf8);
      if (content.trim().isEmpty) return 0;

      final occurrences = _reportSeparator.allMatches(content).length;
      return occurrences + 1;
    } catch (e) {
      debugPrint('countReports error: $e');
      return 0;
    }
  }

  void _showSimpleSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// SnackBar לאחר שמירה: מציג מונה + פעולה לפתיחת דוא"ל (mailto).
  void _showSavedSnack(int count) {
    if (!mounted) return;

    final message =
        "הדיווח נשמר בהצלחה לקובץ '$_reportFileName', הנמצא בתיקייה הראשית של אוצריא.\n"
        "יש לך כבר $count דיווחים!\n"
        "כעת תוכל לשלוח את הקובץ למייל: $_fallbackMail";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 8),
        content: Text(message, textDirection: TextDirection.rtl),
        action: SnackBarAction(
          label: 'שלח',
          onPressed: () {
            _launchMail(_fallbackMail);
          },
        ),
      ),
    );
  }

  Future<void> _launchMail(String email) async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSimpleSnack('לא ניתן לפתוח את תוכנת הדואר');
    }
  }

  Future<Map<String, String>> _getBookDetails(String bookTitle) async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      final file = File(
          '$libraryPath${Platform.pathSeparator}אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}SourcesBooks.csv');
      if (!await file.exists()) {
        return _getDefaultBookDetails();
      }

      // קריאת הקובץ כ-stream
      final inputStream = file.openRead();
      final converter = const CsvToListConverter();

      var isFirstLine = true;

      await for (final line in inputStream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        // דילוג על שורת הכותרת
        if (isFirstLine) {
          isFirstLine = false;
          continue;
        }

        try {
          // המרת השורה לרשימה
          final row = converter.convert(line).first;

          if (row.length >= 3) {
            final fileNameRaw = row[0].toString();
            final fileName = fileNameRaw.replaceAll('.txt', '');

            if (fileName == bookTitle) {
              return {
                'שם הקובץ': fileNameRaw,
                'נתיב הקובץ': row[1].toString(),
                'תיקיית המקור': row[2].toString(),
              };
            }
          }
        } catch (e) {
          // אם יש שגיאה בפירוק השורה, נמשיך לשורה הבאה
          debugPrint('Error parsing CSV line: $line, Error: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error reading sourcebooks.csv: $e');
    }

    return _getDefaultBookDetails();
  }

  Map<String, String> _getDefaultBookDetails() {
    return {
      'שם הקובץ': 'לא ניתן למצוא את הספר',
      'נתיב הקובץ': 'לא ניתן למצוא את הספר',
      'תיקיית המקור': 'לא ניתן למצוא את הספר',
    };
  }

  Widget _buildBody(
    BuildContext context,
    TextBookLoaded state,
    bool wideScreen,
  ) {
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
                if (state.showLeftPane)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragUpdate: (details) {
                        final newWidth =
                            (_sidebarWidth.value - details.delta.dx)
                                .clamp(200.0, 600.0);
                        _sidebarWidth.value = newWidth;
                      },
                      onHorizontalDragEnd: (_) {
                        context
                            .read<SettingsBloc>()
                            .add(UpdateSidebarWidth(_sidebarWidth.value));
                      },
                      child: const VerticalDivider(width: 4),
                    ),
                  ),
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
                UpdateFontSize((state.fontSize * details.scale).clamp(15, 60)),
              );
        },
        child: NotificationListener<UserScrollNotification>(
          onNotification: (scrollNotification) {
            if (!(state.pinLeftPane ||
                (Settings.getValue<bool>('key-pin-sidebar') ?? false))) {
              Future.microtask(() {
                context.read<TextBookBloc>().add(const ToggleLeftPane(false));
              });
            }
            return false;
          },
          child: CallbackShortcuts(
            bindings: <ShortcutActivator, VoidCallback>{
              LogicalKeySet(
                LogicalKeyboardKey.control,
                LogicalKeyboardKey.keyF,
              ): () {
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
        openLeftPaneTab: _openLeftPaneTab,
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
      openLeftPaneTab: _openLeftPaneTab,
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
    return ValueListenableBuilder<double>(
      valueListenable: _sidebarWidth,
      builder: (context, width, child) => AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: SizedBox(
          width: state.showLeftPane ? width : 0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 0, 4, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        tabs: const [
                          Tab(
                              child: Center(
                                  child: Text('ניווט',
                                      textAlign: TextAlign.center))),
                          Tab(
                              child: Center(
                                  child: Text('חיפוש',
                                      textAlign: TextAlign.center))),
                          Tab(
                              child: Center(
                                  child: Text('מפרשים',
                                      textAlign: TextAlign.center))),
                          Tab(
                              child: Center(
                                  child: Text('קישורים',
                                      textAlign: TextAlign.center))),
                        ],
                        controller: tabController,
                        isScrollable: false,
                        tabAlignment: TabAlignment.fill,
                        padding: EdgeInsets.zero,
                        indicatorPadding: EdgeInsets.zero,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
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
                        onPressed:
                            (Settings.getValue<bool>('key-pin-sidebar') ??
                                    false)
                                ? null
                                : () => context.read<TextBookBloc>().add(
                                      TogglePinLeftPane(!state.pinLeftPane),
                                    ),
                        icon: const Icon(Icons.push_pin),
                        isSelected: state.pinLeftPane ||
                            (Settings.getValue<bool>('key-pin-sidebar') ??
                                false),
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
                          LogicalKeySet(
                            LogicalKeyboardKey.control,
                            LogicalKeyboardKey.keyF,
                          ): () {
                            context.read<TextBookBloc>().add(
                                  const ToggleLeftPane(true),
                                );
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
      ),
    );
  }

  Widget _buildSearchView(BuildContext context, TextBookLoaded state) {
    return TextBookSearchView(
      focusNode: textSearchFocusNode,
      data: state.content.join('\n'),
      scrollControler: state.scrollController,
      // הוא מעביר את טקסט החיפוש מה-state הנוכחי אל תוך רכיב החיפוש
      initialQuery: state.searchText,
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
