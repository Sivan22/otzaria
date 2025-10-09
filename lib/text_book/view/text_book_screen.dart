import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
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
import 'package:otzaria/data/data_providers/file_system_data_provider.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/printing/printing_screen.dart';
import 'package:otzaria/text_book/view/commentators_list_screen.dart';
import 'package:otzaria/text_book/view/links_screen.dart';
import 'package:otzaria/text_book/view/text_book_scaffold.dart';
import 'package:otzaria/text_book/view/text_book_search_screen.dart';
import 'package:otzaria/text_book/view/toc_navigator_screen.dart';
import 'package:otzaria/utils/open_book.dart';
import 'package:otzaria/utils/page_converter.dart';
import 'package:otzaria/utils/ref_helper.dart';
import 'package:otzaria/text_book/editing/widgets/text_section_editor_dialog.dart';
import 'package:otzaria/text_book/editing/helpers/editor_settings_helper.dart';
import 'package:otzaria/utils/text_manipulation.dart' as utils;
import 'package:url_launcher/url_launcher.dart';
import 'package:otzaria/notes/notes_system.dart';
import 'package:otzaria/models/phone_report_data.dart';
import 'package:otzaria/services/data_collection_service.dart';
import 'package:otzaria/services/phone_report_service.dart';

import 'package:otzaria/widgets/phone_report_tab.dart';
import 'package:otzaria/widgets/responsive_action_bar.dart';
import 'package:shamor_zachor/providers/shamor_zachor_data_provider.dart';
import 'package:shamor_zachor/providers/shamor_zachor_progress_provider.dart';
import 'package:shamor_zachor/models/book_model.dart';

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
  phone,
}

class TextBookViewerBloc extends StatefulWidget {
  final void Function(OpenedTab) openBookCallback;
  final TextBookTab tab;

  const TextBookViewerBloc({
    super.key,
    required this.openBookCallback,
    required this.tab,
  });

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
  int? _sidebarTabIndex; // אינדקס הכרטיסייה בסרגל הצדי
  static const String _reportFileName = 'דיווח שגיאות בספרים.txt';
  static const String _reportSeparator = '==============================';
  static const String _reportSeparator2 = '------------------------------';
  static const String _fallbackMail = 'otzaria.200@gmail.com';
  bool _isInitialFocusDone = false;

  // משתנים לשמירת נתונים כבדים שנטענים ברקע
  Future<Map<String, dynamic>>? _preloadedHeavyData;
  bool _isLoadingHeavyData = false;

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }

  /// בדיקה אם הספר נתמך על ידי שמור וזכור
  bool _isBookSupportedByShamorZachor(String bookTitle) {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();
      if (!dataProvider.hasData) {
        debugPrint('Shamor Zachor data not loaded yet');
        return false;
      }

      // לא להציג בתלמוד ירושלמי
      if (bookTitle.contains('ירושלמי')) {
        debugPrint('Book $bookTitle is Yerushalmi - not supported');
        return false;
      }

      // חיפוש הספר בכל הקטגוריות - חיפוש מדויק יותר
      final searchResults = dataProvider.searchBooks(bookTitle);
      debugPrint(
          'Searching for book: $bookTitle, found ${searchResults.length} results');

      // בדיקה מדויקת יותר - גם שם מלא וגם חלקי
      final isSupported = searchResults.any((result) =>
          result.bookName == bookTitle ||
          result.bookName.contains(bookTitle) ||
          bookTitle.contains(result.bookName));

      debugPrint(
          'Book $bookTitle is ${isSupported ? 'supported' : 'not supported'} by Shamor Zachor');
      return isSupported;
    } catch (e) {
      // אם אין provider או שגיאה אחרת, הספר לא נתמך
      debugPrint('Error checking Shamor Zachor support: $e');
      return false;
    }
  }

  /// סימון V בשמור וזכור
  Future<void> _markShamorZachorProgress(String bookTitle) async {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();
      final progressProvider = context.read<ShamorZachorProgressProvider>();
      final state = context.read<TextBookBloc>().state as TextBookLoaded;

      if (!dataProvider.hasData) {
        UiSnack.showError('נתוני שמור וזכור לא נטענו');
        return;
      }

      // חיפוש הספר - נחפש גם לפי שם קצר
      final searchResults = dataProvider.searchBooks(bookTitle);

      // זיהוי קטגוריה לפי נתיב הספר
      String searchName = bookTitle;
      String? detectedCategory;

      try {
        // קבלת נתיב הספר
        final titleToPath = await state.book.data.titleToPath;
        final bookPath = titleToPath[bookTitle];

        if (bookPath != null) {
          debugPrint('Book path: $bookPath');

          // זיהוי קטגוריה לפי הנתיב
          if (bookPath.contains('תלמוד בבלי')) {
            detectedCategory = 'תלמוד בבלי';
          } else if (bookPath.contains('תנך') || bookPath.contains('תנ"ך')) {
            detectedCategory = 'תנ"ך';
          } else if (bookPath.contains('משנה')) {
            detectedCategory = 'משנה';
          } else if (bookPath.contains('הלכה')) {
            detectedCategory = 'הלכה';
          } else if (bookPath.contains('ירושלמי')) {
            detectedCategory = 'תלמוד ירושלמי';
          } else if (bookPath.contains('רמב"ם') || bookPath.contains('רמבם')) {
            detectedCategory = 'רמב"ם';
          }

          debugPrint('Detected category from path: $detectedCategory');
        }
      } catch (e) {
        debugPrint('Error getting book path: $e');
      }

      // הכנת שם החיפוש
      searchName = bookTitle;
      if (bookTitle.contains(' - ')) {
        final parts = bookTitle.split(' - ');
        searchName = parts.last.trim();
        debugPrint('Extracted book name from title: $searchName');
      }

      // חיפוש הספר המתאים לפי הקטגוריה המזוהה
      BookSearchResult? bookResult;

      if (detectedCategory != null) {
        // חיפוש בקטגוריה הספציפית שזוהתה מהנתיב
        try {
          bookResult = searchResults.firstWhere(
            (result) =>
                (result.bookName == searchName ||
                    result.bookName.contains(searchName)) &&
                result.topLevelCategoryName == detectedCategory,
          );
          debugPrint(
              'Found in detected category "$detectedCategory": ${bookResult.bookName}');
        } catch (e) {
          debugPrint(
              'Not found in detected category "$detectedCategory", trying general search');
          bookResult = null;
        }
      }

      // אם לא מצאנו בקטגוריה הספציפית, נחפש רגיל
      if (bookResult == null) {
        try {
          bookResult = searchResults.firstWhere(
            (result) =>
                result.bookName == bookTitle ||
                result.bookName == searchName ||
                result.bookName.contains(searchName) ||
                bookTitle.contains(result.bookName),
          );
          debugPrint(
              'Found in general search: ${bookResult.bookName} in ${bookResult.topLevelCategoryName}');
        } catch (e) {
          throw Exception('ספר לא נמצא');
        }
      }

      final categoryName = bookResult.topLevelCategoryName;
      final bookName = bookResult.bookName;
      final bookDetails = bookResult.bookDetails;

      debugPrint('Selected book: $bookName in category: $categoryName');
      debugPrint('Book content type: ${bookDetails.contentType}');

      // קבלת הפרק הנוכחי
      final currentIndex =
          state.positionsListener.itemPositions.value.isNotEmpty
              ? state.positionsListener.itemPositions.value.first.index
              : 0;

      // קבלת הכותרת הנוכחית
      String currentRef =
          await refFromIndex(currentIndex, state.book.tableOfContents);

      // אם הכותרת היא רק שם הספר (H1), נחפש את H2 הבאה
      if (currentRef == state.book.title || currentRef.split(',').length == 1) {
        debugPrint('Current ref is H1 (book title), looking for next H2...');
        final toc = await state.book.tableOfContents;

        // חיפוש הכותרת הבאה שגדולה מהאינדקס הנוכחי
        for (final entry in toc) {
          if (entry.index > currentIndex) {
            currentRef = entry.text;
            debugPrint('Found next H2: $currentRef');
            break;
          }
          // חיפוש גם בכותרות המשנה
          for (final child in entry.children) {
            if (child.index > currentIndex) {
              currentRef = '${entry.text}, ${child.text}';
              debugPrint('Found next H2 child: $currentRef');
              break;
            }
          }
          if (currentRef !=
              await refFromIndex(currentIndex, state.book.tableOfContents)) {
            break;
          }
        }
      }

      debugPrint('Current ref: $currentRef');

      // חילוץ מספר הפרק מהפניה
      int? chapterNumber = _extractChapterNumber(currentRef);
      String? chapterName = _extractChapterName(currentRef);
      String? amudKey = _extractAmudKey(currentRef);

      if (chapterNumber == null) {
        UiSnack.showError('לא הצלחתי לזהות את הפרק הנוכחי');
        return;
      }

      debugPrint('Chapter number: $chapterNumber');
      debugPrint('Chapter name: $chapterName');
      debugPrint('Amud key: $amudKey');
      debugPrint('Book content type: ${bookDetails.contentType}');
      debugPrint('Book is daf type: ${bookDetails.isDafType}');
      debugPrint('Total learnable items: ${bookDetails.learnableItems.length}');

      // מציאת הפריט הרלוונטי בשמור וזכור
      final learnableItems = bookDetails.learnableItems;

      // חיפוש הפריט המתאים - בתלמוד לפי דף ועמוד, אחרת לפי פרק
      LearnableItem? targetItem;

      if (bookDetails.isDafType || amudKey != null) {
        // זה תלמוד - חפש לפי דף ועמוד
        final targetAmud = amudKey ?? 'a'; // ברירת מחדל עמוד א'
        try {
          targetItem = learnableItems.firstWhere(
            (item) =>
                item.pageNumber == chapterNumber && item.amudKey == targetAmud,
          );
        } catch (e) {
          targetItem = null;
        }
      } else {
        // זה לא תלמוד - חפש לפי מספר פרק
        try {
          targetItem = learnableItems.firstWhere(
            (item) => item.pageNumber == chapterNumber,
          );
        } catch (e) {
          targetItem = null;
        }
      }

      if (targetItem == null) {
        throw Exception('${chapterName ?? chapterNumber} לא נמצא בשמור וזכור');
      }

      debugPrint(
          'Target item: ${targetItem.pageNumber}${targetItem.amudKey}, absoluteIndex: ${targetItem.absoluteIndex}');

      // בדיקת מצב העמודות עבור הפרק הספציפי
      final itemProgress = progressProvider.getProgressForItem(
          categoryName, bookName, targetItem.absoluteIndex);

      // מציאת העמודה הראשונה שלא מסומנת
      String? columnToMark;
      const columns = ['learn', 'review1', 'review2', 'review3'];

      for (final column in columns) {
        if (!itemProgress.getProperty(column)) {
          columnToMark = column;
          break;
        }
      }

      if (columnToMark == null) {
        UiSnack.show(
            'אין מקום פנוי ב${chapterName ?? chapterNumber}, למדת הרבה!');
        return;
      }

      // סימון הפרק הספציפי
      await progressProvider.updateProgress(
        categoryName,
        bookName,
        targetItem.absoluteIndex,
        columnToMark,
        true,
        bookDetails,
      );

      final columnName = _getColumnDisplayName(columnToMark);
      // השתמש בשם המקורי מהכותרת
      final displayName = chapterName ?? 'פרק $chapterNumber';
      UiSnack.showSuccess('$displayName סומן כ$columnName בהצלחה!');
    } catch (e) {
      debugPrint('Error in _markShamorZachorProgress: $e');
      UiSnack.showError('שגיאה בסימון: ${e.toString()}');
    }
  }

  /// חילוץ מספר הפרק מהפניה
  int? _extractChapterNumber(String ref) {
    // דוגמאות לפניות: "בראשית, פרק א", "שמות, פרק ב", "בראשית א", "שמות ב"

    // חיפוש מספרים עבריים
    final hebrewNumbers = {
      'א': 1,
      'ב': 2,
      'ג': 3,
      'ד': 4,
      'ה': 5,
      'ו': 6,
      'ז': 7,
      'ח': 8,
      'ט': 9,
      'י': 10,
      'יא': 11,
      'יב': 12,
      'יג': 13,
      'יד': 14,
      'טו': 15,
      'טז': 16,
      'יז': 17,
      'יח': 18,
      'יט': 19,
      'כ': 20,
      'כא': 21,
      'כב': 22,
      'כג': 23,
      'כד': 24,
      'כה': 25,
      'כו': 26,
      'כז': 27,
      'כח': 28,
      'כט': 29,
      'ל': 30,
      'לא': 31,
      'לב': 32,
      'לג': 33,
      'לד': 34,
      'לה': 35,
      'לו': 36,
      'לז': 37,
      'לח': 38,
      'לט': 39,
      'מ': 40,
      'מא': 41,
      'מב': 42,
      'מג': 43,
      'מד': 44,
      'מה': 45,
      'מו': 46,
      'מז': 47,
      'מח': 48,
      'מט': 49,
      'נ': 50
    };

    // חיפוש דפוסים שונים - פרק, דף, או רק מספר
    final patterns = [
      RegExp(r'פרק\s+([א-ת]+)'),
      RegExp(r'דף\s+([א-ת]+)\.?'), // תמיכה ב"דף ו." או "דף ו"
      RegExp(r',\s*([א-ת]+)\.?$'), // תמיכה ב", ו." או ", ו"
      RegExp(r'\s+([א-ת]+)\.?$'), // תמיכה ב" ו." או " ו"
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(ref);
      if (match != null) {
        final hebrewNum = match.group(1);
        if (hebrewNum != null && hebrewNumbers.containsKey(hebrewNum)) {
          return hebrewNumbers[hebrewNum];
        }
      }
    }

    // חיפוש מספרים רגילים
    final numberPattern = RegExp(r'(\d+)');
    final numberMatch = numberPattern.firstMatch(ref);
    if (numberMatch != null) {
      return int.tryParse(numberMatch.group(1)!);
    }

    return null;
  }

  /// חילוץ עמוד (א'/ב') מהפניה
  String? _extractAmudKey(String ref) {
    // דוגמאות: "חגיגה, דף ג:" -> "b", "ברכות, דף ו." -> "a"

    if (ref.contains(':')) {
      return 'b'; // נקודתיים מציינים עמוד ב'
    } else if (ref.contains('.')) {
      return 'a'; // נקודה מציינת עמוד א'
    }

    return null; // לא תלמוד
  }

  /// חילוץ שם הפרק/דף מהפניה (לתצוגה)
  String? _extractChapterName(String ref) {
    // דוגמאות: "בראשית, פרק א" -> "פרק א", "ברכות, דף ו." -> "דף ו"

    final patterns = [
      RegExp(r'(פרק\s+[א-ת]+)'),
      RegExp(r'(דף\s+[א-ת]+[.:]?)'), // שמירת הנקודה או הנקודתיים
      RegExp(r',\s*([א-ת]+[.:]?)$'), // אם זה רק האות בסוף עם הסימן
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(ref);
      if (match != null) {
        String result = match.group(1) ?? '';
        return result;
      }
    }

    // אם לא מצאנו דפוס מיוחד, ננסה לחלץ רק את החלק האחרון
    final parts = ref.split(',');
    if (parts.length > 1) {
      String lastPart = parts.last.trim();
      return lastPart; // שמירת הסימן המקורי
    }

    return null;
  }

  /// קבלת שם העמודה להצגה
  String _getColumnDisplayName(String column) {
    switch (column) {
      case 'learn':
        return 'נלמד';
      case 'review1':
        return 'חזרה ראשונה';
      case 'review2':
        return 'חזרה שנייה';
      case 'review3':
        return 'חזרה שלישית';
      default:
        return column;
    }
  }

  int _getCurrentLineNumber() {
    try {
      final state = context.read<TextBookBloc>().state;
      if (state is TextBookLoaded) {
        final positions = state.positionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final firstVisible =
              positions.reduce((a, b) => a.index < b.index ? a : b);
          return firstVisible.index + 1;
        }
      }
      return 1; // Fallback to line 1
    } catch (e) {
      debugPrint('Error getting current line number: $e');
      return 1;
    }
  }

  // Build 4+4 words context around a selection range within fullText
  String _buildContextAroundSelection(
    String fullText,
    int selectionStart,
    int selectionEnd, {
    int wordsBefore = 4,
    int wordsAfter = 4,
  }) {
    if (selectionStart < 0 || selectionEnd <= selectionStart) {
      return fullText;
    }
    final wordRegex = RegExp("\\S+", multiLine: true);
    final matches = wordRegex.allMatches(fullText).toList();
    if (matches.isEmpty) return fullText;

    int startWordIndex = 0;
    int endWordIndex = matches.length - 1;

    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      if (selectionStart >= m.start && selectionStart < m.end) {
        startWordIndex = i;
        break;
      }
      if (selectionStart < m.start) {
        startWordIndex = i;
        break;
      }
    }

    for (int i = matches.length - 1; i >= 0; i--) {
      final m = matches[i];
      final selEndMinusOne = selectionEnd - 1;
      if (selEndMinusOne >= m.start && selEndMinusOne < m.end) {
        endWordIndex = i;
        break;
      }
      if (selEndMinusOne > m.end) {
        endWordIndex = i;
        break;
      }
    }

    final ctxStart =
        (startWordIndex - wordsBefore) < 0 ? 0 : (startWordIndex - wordsBefore);
    final ctxEnd = (endWordIndex + wordsAfter) >= matches.length
        ? matches.length - 1
        : (endWordIndex + wordsAfter);

    final from = matches[ctxStart].start;
    final to = matches[ctxEnd].end;
    if (from < 0 || to <= from || to > fullText.length) return fullText;
    return fullText.substring(from, to);
  }

  @override
  void initState() {
    super.initState();

    // וודא שהמיקום הנוכחי נשמר בטאב

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
        return BlocConsumer<TextBookBloc, TextBookState>(
          bloc: context.read<TextBookBloc>(),
          listener: (context, state) {
            if (state is TextBookLoaded &&
                state.isEditorOpen &&
                state.editorIndex != null) {
              _openEditorDialog(context, state);
            }

            // איפוס אינדקס הכרטיסייה כשהחלונית נסגרת
            if (state is TextBookLoaded &&
                !state.showSplitView &&
                _sidebarTabIndex != null) {
              setState(() {
                _sidebarTabIndex = null;
              });
            }
          },
          builder: (context, state) {
            if (state is TextBookInitial) {
              // איפוס אינדקס הכרטיסייה כשטוענים ספר חדש
              if (_sidebarTabIndex != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _sidebarTabIndex = null;
                  });
                });
              }

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
                  return KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) =>
                        _handleGlobalKeyEvent(event, context, state),
                    child: Scaffold(
                      appBar: _buildAppBar(context, state, wideScreen),
                      body: _buildBody(context, state, wideScreen),
                    ),
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
    if (state.currentTitle == null) {
      return const SizedBox.shrink();
    }

    const style = TextStyle(fontSize: 17);
    final text = state.currentTitle!;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.rtl,
        )..layout(minWidth: 0, maxWidth: constraints.maxWidth);

        final child = SelectionArea(
          child: Text(
            text,
            style: style,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

        if (textPainter.didExceedMaxLines) {
          return Tooltip(
            message: text,
            child: child,
          );
        }

        return child;
      },
    );
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
    final screenWidth = MediaQuery.of(context).size.width;

    // במסכים רחבים מאוד (יותר מ-1200), נציג את כל הכפתורים כרגיל
    if (screenWidth >= 1200) {
      return [
        // PDF Button
        _buildPdfButton(context, state),

        // Split View Button
        _buildSplitViewButton(context, state),

        // Nikud Button
        _buildNikudButton(context, state),

        // Bookmark Button
        _buildBookmarkButton(context, state),

        // Notes Buttons
        _buildShowNotesButton(context, state),
        _buildAddNoteButton(context, state),

        // Search Button
        _buildSearchButton(context, state),

        // Zoom Buttons
        _buildZoomInButton(context, state),
        _buildZoomOutButton(context, state),

        // Navigation Buttons
        _buildFirstPageButton(state),
        _buildPreviousPageButton(state),
        _buildNextPageButton(state),
        _buildLastPageButton(state),

        // Print Button
        _buildPrintButton(context, state),

        // Full File Editor Button
        _buildFullFileEditorButton(context, state),

        // Report Bug Button
        _buildReportBugButton(context, state),

        // Shamor Zachor Button
        _buildShamorZachorButton(context, state),
      ];
    }

    // במסכים צרים, נשתמש ברכיב הרספונסיבי
    // נקבע כמה כפתורים להציג בהתאם לרוחב המסך
    int maxButtons;

    if (screenWidth < 400) {
      maxButtons = 2; // 2 כפתורים חשובים + "..." במסכים קטנים מאוד
    } else if (screenWidth < 500) {
      maxButtons = 4; // 4 כפתורים חשובים + "..." במסכים קטנים
    } else if (screenWidth < 600) {
      maxButtons = 6; // 6 כפתורים חשובים + "..." במסכים בינוניים קטנים
    } else if (screenWidth < 700) {
      maxButtons = 8; // 8 כפתורים חשובים + "..." במסכים בינוניים
    } else if (screenWidth < 800) {
      maxButtons = 10; // 10 כפתורים חשובים + "..." במסכים בינוניים גדולים
    } else if (screenWidth < 900) {
      maxButtons = 12; // 12 כפתורים חשובים + "..." במסכים גדולים
    } else if (screenWidth < 1100) {
      maxButtons = 14; // 14 כפתורים חשובים + "..." במסכים גדולים יותר
    } else {
      maxButtons = 15; // כמעט כל הכפתורים במסכים רחבים מאוד
    }

    return [
      ResponsiveActionBar(
        actions: _buildPrioritizedActions(context, state),
        originalOrder: _buildOriginalOrderActions(context, state),
        maxVisibleButtons: maxButtons,
      ),
    ];
  }

  /// בניית רשימת כפתורים בסדר המקורי (כמו במסך הרחב)
  List<ActionButtonData> _buildOriginalOrderActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // PDF Button (ראשון במסך הרחב)
      ActionButtonData(
        widget: _buildPdfButton(context, state),
        icon: Icons.picture_as_pdf,
        tooltip: 'פתח ספר במהדורה מודפסת',
        onPressed: () => _handlePdfButtonPress(context, state),
      ),

      // Split View Button
      ActionButtonData(
        widget: _buildSplitViewButton(context, state),
        icon: !state.showSplitView
            ? Icons.vertical_split_outlined
            : Icons.horizontal_split_outlined,
        tooltip: !state.showSplitView
            ? 'הצגת מפרשים בצד הטקסט'
            : 'הצגת מפרשים מתחת הטקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              ToggleSplitView(!state.showSplitView),
            ),
      ),

      // Nikud Button
      ActionButtonData(
        widget: _buildNikudButton(context, state),
        icon: Icons.format_overline,
        tooltip: 'הצג או הסתר ניקוד',
        onPressed: () =>
            context.read<TextBookBloc>().add(ToggleNikud(!state.removeNikud)),
      ),

      // Bookmark Button
      ActionButtonData(
        widget: _buildBookmarkButton(context, state),
        icon: Icons.bookmark_add,
        tooltip: 'הוספת סימניה',
        onPressed: () => _handleBookmarkPress(context, state),
      ),

      // Show Notes Button
      ActionButtonData(
        widget: _buildShowNotesButton(context, state),
        icon: Icons.notes,
        tooltip: 'הצג הערות',
        onPressed: () {
          context.read<TextBookBloc>().add(const ToggleNotesSidebar());
        },
      ),

      // Add Note Button
      ActionButtonData(
        widget: _buildAddNoteButton(context, state),
        icon: Icons.note_add,
        tooltip: 'הוסף הערה אישית',
        onPressed: () => _handleAddNotePress(context, state),
      ),

      // Search Button
      ActionButtonData(
        widget: _buildSearchButton(context, state),
        icon: Icons.search,
        tooltip: 'חיפוש',
        onPressed: () {
          context.read<TextBookBloc>().add(const ToggleLeftPane(true));
          tabController.index = 1;
          textSearchFocusNode.requestFocus();
        },
      ),

      // Zoom In Button
      ActionButtonData(
        widget: _buildZoomInButton(context, state),
        icon: Icons.zoom_in,
        tooltip: 'הגדלת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(min(50.0, state.fontSize + 3)),
            ),
      ),

      // Zoom Out Button
      ActionButtonData(
        widget: _buildZoomOutButton(context, state),
        icon: Icons.zoom_out,
        tooltip: 'הקטנת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(max(15.0, state.fontSize - 3)),
            ),
      ),

      // Navigation Buttons
      ActionButtonData(
        widget: _buildFirstPageButton(state),
        icon: Icons.first_page,
        tooltip: 'תחילת הספר',
        onPressed: () {
          state.scrollController.scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
      ActionButtonData(
        widget: _buildPreviousPageButton(state),
        icon: Icons.navigate_before,
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
      ),
      ActionButtonData(
        widget: _buildNextPageButton(state),
        icon: Icons.navigate_next,
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
      ),
      ActionButtonData(
        widget: _buildLastPageButton(state),
        icon: Icons.last_page,
        tooltip: 'סוף הספר',
        onPressed: () {
          state.scrollController.scrollTo(
            index: state.content.length,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),

      // Print Button
      ActionButtonData(
        widget: _buildPrintButton(context, state),
        icon: Icons.print,
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
      ),

      // Full File Editor Button
      ActionButtonData(
        widget: _buildFullFileEditorButton(context, state),
        icon: Icons.edit_document,
        tooltip: 'ערוך את הספר (Ctrl+Shift+E)',
        onPressed: () => _handleFullFileEditorPress(context, state),
      ),

      // Report Bug Button
      ActionButtonData(
        widget: _buildReportBugButton(context, state),
        icon: Icons.error_outline,
        tooltip: 'דווח על טעות בספר',
        onPressed: () => _showReportBugDialog(context, state),
      ),

      // Shamor Zachor Button
      ActionButtonData(
        widget: _buildShamorZachorButton(context, state),
        icon: Icons.check_circle,
        tooltip: 'סמן כנלמד בשמור וזכור',
        onPressed: () => _markShamorZachorProgress(state.book.title),
      ),
    ];
  }

  /// בניית רשימת כפתורים לפי סדר עדיפות (החשוב ביותר ראשון)
  List<ActionButtonData> _buildPrioritizedActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // 1) כפתורי הגדל/הקטן, וכפתורי ההחלפה בין טקסט לPDF
      ActionButtonData(
        widget: _buildZoomInButton(context, state),
        icon: Icons.zoom_in,
        tooltip: 'הגדלת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(min(50.0, state.fontSize + 3)),
            ),
      ),
      ActionButtonData(
        widget: _buildZoomOutButton(context, state),
        icon: Icons.zoom_out,
        tooltip: 'הקטנת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(max(15.0, state.fontSize - 3)),
            ),
      ),
      ActionButtonData(
        widget: _buildPdfButton(context, state),
        icon: Icons.picture_as_pdf,
        tooltip: 'פתח ספר במהדורה מודפסת',
        onPressed: () => _handlePdfButtonPress(context, state),
      ),

      // 3) חיפוש
      ActionButtonData(
        widget: _buildSearchButton(context, state),
        icon: Icons.search,
        tooltip: 'חיפוש',
        onPressed: () {
          context.read<TextBookBloc>().add(const ToggleLeftPane(true));
          tabController.index = 1;
          textSearchFocusNode.requestFocus();
        },
      ),

      // 3) ערוך את הספר
      ActionButtonData(
        widget: _buildFullFileEditorButton(context, state),
        icon: Icons.edit_document,
        tooltip: 'ערוך את הספר (Ctrl+Shift+E)',
        onPressed: () => _handleFullFileEditorPress(context, state),
      ),

      // 4) הוסף הערות
      ActionButtonData(
        widget: _buildAddNoteButton(context, state),
        icon: Icons.note_add,
        tooltip: 'הוסף הערה אישית',
        onPressed: () => _handleAddNotePress(context, state),
      ),

      // 5) כפתורי השליטה בספר: הקטע הקודם/הבא, תחילת/סוף הספר
      ActionButtonData(
        widget: _buildFirstPageButton(state),
        icon: Icons.first_page,
        tooltip: 'תחילת הספר',
        onPressed: () {
          state.scrollController.scrollTo(
            index: 0,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
      ActionButtonData(
        widget: _buildPreviousPageButton(state),
        icon: Icons.navigate_before,
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
      ),
      ActionButtonData(
        widget: _buildNextPageButton(state),
        icon: Icons.navigate_next,
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
      ),
      ActionButtonData(
        widget: _buildLastPageButton(state),
        icon: Icons.last_page,
        tooltip: 'סוף הספר',
        onPressed: () {
          state.scrollController.scrollTo(
            index: state.content.length,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),

      // 5) הצג הערות
      ActionButtonData(
        widget: _buildShowNotesButton(context, state),
        icon: Icons.notes,
        tooltip: 'הצג הערות',
        onPressed: () {
          context.read<TextBookBloc>().add(const ToggleNotesSidebar());
        },
      ),

      // 6) הוספת סימניה
      ActionButtonData(
        widget: _buildBookmarkButton(context, state),
        icon: Icons.bookmark_add,
        tooltip: 'הוספת סימניה',
        onPressed: () => _handleBookmarkPress(context, state),
      ),

      // 7) הצגת מפרשים בצד/מתחת הטקסט
      ActionButtonData(
        widget: _buildSplitViewButton(context, state),
        icon: !state.showSplitView
            ? Icons.vertical_split_outlined
            : Icons.horizontal_split_outlined,
        tooltip: !state.showSplitView
            ? 'הצגת מפרשים בצד הטקסט'
            : 'הצגת מפרשים מתחת הטקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              ToggleSplitView(!state.showSplitView),
            ),
      ),

      // 8) הצג/הסתר ניקוד
      ActionButtonData(
        widget: _buildNikudButton(context, state),
        icon: Icons.format_overline,
        tooltip: 'הצג או הסתר ניקוד',
        onPressed: () =>
            context.read<TextBookBloc>().add(ToggleNikud(!state.removeNikud)),
      ),

      // 9) כפתורי הדיווח על טעות
      ActionButtonData(
        widget: _buildReportBugButton(context, state),
        icon: Icons.error_outline,
        tooltip: 'דווח על טעות בספר',
        onPressed: () => _showReportBugDialog(context, state),
      ),

      // 10) כפתור הדפסה
      ActionButtonData(
        widget: _buildPrintButton(context, state),
        icon: Icons.print,
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
      ),

      // 11) כפתור שמור וזכור
      ActionButtonData(
        widget: _buildShamorZachorButton(context, state),
        icon: Icons.check_circle,
        tooltip: 'סמן כנלמד בשמור וזכור',
        onPressed: () => _markShamorZachorProgress(state.book.title),
      ),
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
                final currentIndex = state
                        .positionsListener.itemPositions.value.isNotEmpty
                    ? state.positionsListener.itemPositions.value.first.index
                    : 0;
                widget.tab.index = currentIndex;

                final library = await DataRepository.instance.library;
                if (!context.mounted) return;

                final book = library.findBookByTitle(state.book.title, PdfBook);
                if (book == null) {
                  return;
                }

                final index = await textToPdfPage(
                  state.book,
                  currentIndex,
                );

                if (!context.mounted) return;

                openBook(context, book, index ?? 1, '', ignoreHistory: true);
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
        if (!mounted || !context.mounted) return;

        bool bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
              ref: ref,
              book: state.book,
              index: index,
              commentatorsToShow: state.activeCommentators,
            );
        UiSnack.showQuick(
            bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת');
      },
      icon: const Icon(Icons.bookmark_add),
      tooltip: 'הוספת סימניה',
    );
  }

  Widget _buildShowNotesButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () {
        // נוסיף event חדש ל-TextBookBloc להצגת/הסתרת הערות
        context.read<TextBookBloc>().add(const ToggleNotesSidebar());
      },
      icon: const Icon(Icons.notes),
      tooltip: 'הצג הערות',
    );
  }

  Widget _buildAddNoteButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () {
        final selectedText = state.selectedTextForNote;
        if (selectedText == null || selectedText.trim().isEmpty) {
          UiSnack.show(UiSnack.noTextSelected);
          return;
        }

        // יצירת הערה עם הטקסט הנבחר
        _showNoteEditor(
          context,
          selectedText,
          state.selectedTextStart ?? 0,
          state.selectedTextEnd ?? selectedText.length,
          state.book.title,
        );
      },
      icon: const Icon(Icons.note_add),
      tooltip: 'הוסף הערה אישית',
    );
  }

  void _showNoteEditor(BuildContext context, String selectedText, int charStart,
      int charEnd, String bookId) {
    // שמירת ה-context המקורי וה-bloc
    final originalContext = context;
    final textBookBloc = context.read<TextBookBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => NoteEditorDialog(
        selectedText: selectedText,
        bookId: bookId,
        charStart: charStart,
        charEnd: charEnd,
        onSave: (noteRequest) async {
          try {
            final notesService = NotesIntegrationService.instance;
            await notesService.createNoteFromSelection(
              bookId,
              selectedText,
              charStart,
              charEnd,
              noteRequest.contentMarkdown,
              tags: noteRequest.tags,
              privacy: noteRequest.privacy,
            );

            if (originalContext.mounted) {
              // Dialog is already closed by NoteEditorDialog
              // הצגת סרגל ההערות אם הוא לא פתוח
              final currentState = textBookBloc.state;
              if (currentState is TextBookLoaded &&
                  !currentState.showNotesSidebar) {
                textBookBloc.add(const ToggleNotesSidebar());
              }
              UiSnack.show(UiSnack.noteCreated);
            }
          } catch (e) {
            if (originalContext.mounted) {
              UiSnack.showError('שגיאה ביצירת הערה',
                  backgroundColor: Theme.of(originalContext).colorScheme.error);
            }
          }
        },
      ),
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

  Widget _buildShamorZachorButton(BuildContext context, TextBookLoaded state) {
    if (!_isBookSupportedByShamorZachor(state.book.title)) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => _markShamorZachorProgress(state.book.title),
      icon: Image.asset(
        'assets/icon/shamor_zachor_with_v.png',
        width: 24,
        height: 24,
      ),
      tooltip: 'סמן כנלמד בשמור וזכור',
    );
  }

  /// פונקציות עזר לטיפול בלחיצות על כפתורים בתפריט הנפתח
  void _handlePdfButtonPress(BuildContext context, TextBookLoaded state) async {
    final currentIndex = state.positionsListener.itemPositions.value.isNotEmpty
        ? state.positionsListener.itemPositions.value.first.index
        : 0;
    widget.tab.index = currentIndex;

    final library = await DataRepository.instance.library;
    if (!context.mounted) return;

    final book = library.findBookByTitle(state.book.title, PdfBook);
    if (book == null) {
      return;
    }

    final index = await textToPdfPage(state.book, currentIndex);

    if (!context.mounted) return;

    openBook(context, book, index ?? 1, '', ignoreHistory: true);
  }

  void _handleAddNotePress(BuildContext context, TextBookLoaded state) {
    final selectedText = state.selectedTextForNote;
    if (selectedText == null || selectedText.trim().isEmpty) {
      UiSnack.show(UiSnack.noTextSelected);
      return;
    }

    _showNoteEditor(
      context,
      selectedText,
      state.selectedTextStart ?? 0,
      state.selectedTextEnd ?? selectedText.length,
      state.book.title,
    );
  }

  void _handleBookmarkPress(BuildContext context, TextBookLoaded state) async {
    final index = state.positionsListener.itemPositions.value.first.index;
    final toc = state.book.tableOfContents;
    final ref = await refFromIndex(index, toc);
    if (!mounted || !context.mounted) return;

    final bookmarkAdded = context.read<BookmarkBloc>().addBookmark(
          ref: ref,
          book: state.book,
          index: index,
          commentatorsToShow: state.activeCommentators,
        );

    final successColor =
        bookmarkAdded ? Theme.of(context).colorScheme.tertiaryContainer : null;
    UiSnack.showSuccess(
        bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת',
        backgroundColor: successColor);
  }

  Future<void> _showReportBugDialog(
    BuildContext context,
    TextBookLoaded state,
  ) async {
    final allText = state.content;
    final visiblePositions = state.positionsListener.itemPositions.value
        .toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final visibleText = visiblePositions
        .map((pos) => utils.stripHtmlIfNeeded(allText[pos.index]))
        .join('\n');

    if (!mounted || !context.mounted) return;

    final dynamic result = await _showTabbedReportDialog(
      context,
      visibleText,
      state.fontSize,
      state.book.title,
      state, // העבר את ה-state לדיאלוג
    );

    try {
      if (result == null) return; // בוטל
      if (!mounted || !context.mounted) return;

      // Handle different result types
      if (result is ReportedErrorData) {
        // Regular report - the heavy data should already be loaded by now
        final ReportAction? action =
            await _showConfirmationDialog(context, result);

        if (!mounted || !context.mounted) return;

        if (action == null || action == ReportAction.cancel) return;

        // Get the heavy data that was loaded in background
        final heavyData = await _getPreloadedHeavyData(state);

        // Compute accurate line number and 4+4 words context based on selection
        final baseLineNumber = _getCurrentLineNumber();
        final selectionStart = visibleText.indexOf(result.selectedText);
        int computedLineNumber = baseLineNumber;
        if (selectionStart >= 0) {
          final before = visibleText.substring(0, selectionStart);
          final offset = '\n'.allMatches(before).length;
          computedLineNumber = baseLineNumber + offset;
        }
        final safeStart = selectionStart >= 0 ? selectionStart : 0;
        final safeEnd = safeStart + result.selectedText.length;
        final contextText = _buildContextAroundSelection(
          visibleText,
          safeStart,
          safeEnd,
          wordsBefore: 4,
          wordsAfter: 4,
        );

        // Handle regular report actions
        await _handleRegularReportAction(
          action,
          result,
          state,
          heavyData['currentRef'],
          heavyData['bookDetails'],
          computedLineNumber,
          contextText,
        );
      } else if (result is PhoneReportData) {
        // Phone report - handle directly
        await _handlePhoneReport(result);
      }
    } finally {
      // נקה את הנתונים הכבדים מהזיכרון בכל מקרה (דיווח או ביטול)
      _clearHeavyDataFromMemory();
    }
  }

  /// Load heavy data for regular report in background
  Future<Map<String, dynamic>> _loadHeavyDataForRegularReport(
      TextBookLoaded state) async {
    final currentRef = await refFromIndex(
      state.positionsListener.itemPositions.value.isNotEmpty
          ? state.positionsListener.itemPositions.value.first.index
          : 0,
      state.book.tableOfContents,
    );

    final bookDetails = await _getBookDetails(state.book.title);

    return {'currentRef': currentRef, 'bookDetails': bookDetails};
  }

  /// Get preloaded heavy data or load it if not ready
  Future<Map<String, dynamic>> _getPreloadedHeavyData(
      TextBookLoaded state) async {
    if (_preloadedHeavyData != null) {
      return await _preloadedHeavyData!;
    } else {
      return await _loadHeavyDataForRegularReport(state);
    }
  }

  /// Clear heavy data from memory to free up resources
  void _clearHeavyDataFromMemory() {
    _preloadedHeavyData = null;
    _isLoadingHeavyData = false;
  }

  Future<dynamic> _showTabbedReportDialog(
    BuildContext context,
    String text,
    double fontSize,
    String bookTitle,
    TextBookLoaded state,
  ) async {
    // קבל את מספר השורה ההתחלתי לפני פתיחת הדיאלוג
    final currentLineNumber = _getCurrentLineNumber();

    // התחל לטעון נתונים כבדים ברקע מיד אחרי פתיחת הדיאלוג
    _startLoadingHeavyDataInBackground(state);

    return showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return _TabbedReportDialog(
          visibleText: text,
          fontSize: fontSize,
          bookTitle: bookTitle,
          currentLineNumber: currentLineNumber,
          state: state, // העבר את ה-state לדיאלוג
        );
      },
    );
  }

  /// Start loading heavy data in background immediately after dialog opens
  void _startLoadingHeavyDataInBackground(TextBookLoaded state) {
    if (_isLoadingHeavyData) return; // כבר טוען

    _isLoadingHeavyData = true;

    // התחל טעינה ברקע
    _preloadedHeavyData = _loadHeavyDataForRegularReport(state).then((data) {
      _isLoadingHeavyData = false;
      return data;
    }).catchError((error) {
      _isLoadingHeavyData = false;
      throw error;
    });
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
    int lineNumber,
    String contextText,
  ) {
    final detailsSection = (() {
      final base = errorDetails.isEmpty ? '' : '\n$errorDetails';
      final extra = '''
      
    מספר שורה: $lineNumber
    הקשר (4 מילים לפני ואחרי):
    $contextText''';
      return '$base$extra';
    })();

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

  /// Handle regular report action (email or save)
  Future<void> _handleRegularReportAction(
    ReportAction action,
    ReportedErrorData reportData,
    TextBookLoaded state,
    String currentRef,
    Map<String, String> bookDetails,
    int lineNumber,
    String contextText,
  ) async {
    final emailBody = _buildEmailBody(
      state.book.title,
      currentRef,
      bookDetails,
      reportData.selectedText,
      reportData.errorDetails,
      lineNumber,
      contextText,
    );

    if (action == ReportAction.sendEmail) {
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
    } else if (action == ReportAction.saveForLater) {
      final saved = await _saveReportToFile(emailBody);
      if (!saved) {
        _showSimpleSnack('שמירת הדיווח נכשלה.');
        return;
      }

      final count = await _countReportsInFile();
      _showSavedSnack(count);
    }
  }

  /// Handle phone report submission
  Future<void> _handlePhoneReport(PhoneReportData reportData) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final phoneReportService = PhoneReportService();
      final result = await phoneReportService.submitReport(reportData);
      if (!mounted || !context.mounted) return;

      // Hide loading indicator
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (result.isSuccess) {
        _showPhoneReportSuccessDialog();
      } else {
        _showSimpleSnack(result.message);
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted && context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      debugPrint('Phone report error: $e');
      _showSimpleSnack('שגיאה בשליחת הדיווח: ${e.toString()}');
    }
  }

  /// Show success dialog for phone report
  void _showPhoneReportSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('דיווח נשלח בהצלחה'),
        content: const Text('הדיווח נשלח בהצלחה לצוות אוצריא. תודה על הדיווח!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('סגור'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open another report dialog
              _showReportBugDialog(context,
                  context.read<TextBookBloc>().state as TextBookLoaded);
            },
            child: const Text('פתח דוח שגיאות אחר'),
          ),
        ],
      ),
    );
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
    UiSnack.show(message);
  }

  /// SnackBar לאחר שמירה: מציג מונה + פעולה לפתיחת דוא"ל (mailto).
  void _showSavedSnack(int count) {
    if (!mounted) return;

    final message =
        "הדיווח נשמר בהצלחה לקובץ '$_reportFileName', הנמצא בתיקייה הראשית של אוצריא.\n"
        "יש לך כבר $count דיווחים!\n"
        "כעת תוכל לשלוח את הקובץ למייל: $_fallbackMail";

    UiSnack.showWithAction(
      message: message,
      actionLabel: 'שלח',
      onAction: () => _launchMail(_fallbackMail),
      duration: const Duration(seconds: 8),
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
                if (!mounted || !context.mounted) return;
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
              child: TextBookScaffold(
                content: state.content,
                openBookCallback: widget.openBookCallback,
                openLeftPaneTab: _openLeftPaneTab,
                searchTextController: TextEditingValue(text: state.searchText),
                tab: widget.tab,
                initialSidebarTabIndex: _sidebarTabIndex,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTab(String text, int index, TextBookLoaded state) {
    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        final isSelected = tabController.index == index;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              tabController.animateTo(index);
              if (index == 1 && !Platform.isAndroid) {
                textSearchFocusNode.requestFocus();
              } else if (index == 0 && !Platform.isAndroid) {
                navigationSearchFocusNode.requestFocus();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  tabController.animateTo(index);
                  if (index == 1 && !Platform.isAndroid) {
                    textSearchFocusNode.requestFocus();
                  } else if (index == 0 && !Platform.isAndroid) {
                    navigationSearchFocusNode.requestFocus();
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border(
                            bottom: BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2))
                        : null,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar(TextBookLoaded state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.showLeftPane && !Platform.isAndroid && !_isInitialFocusDone) {
        if (tabController.index == 1) {
          textSearchFocusNode.requestFocus();
        } else if (tabController.index == 0) {
          navigationSearchFocusNode.requestFocus();
        }
        _isInitialFocusDone = true;
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: _buildCustomTab('ניווט', 0, state)),
                              Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2)),
                              Expanded(
                                  child: _buildCustomTab('חיפוש', 1, state)),
                              Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2)),
                              Expanded(
                                  child: _buildCustomTab('מפרשים', 2, state)),
                              Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey.shade400,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 2)),
                              Expanded(
                                  child: _buildCustomTab('קישורים', 3, state)),
                            ],
                          ),
                          Container(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                        ],
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
      closeLeftPanelCallback: () =>
          context.read<TextBookBloc>().add(const ToggleLeftPane(false)),
      isSplitViewOpen: state.showSplitView &&
          (state.activeCommentators.isNotEmpty || _sidebarTabIndex != null),
      links: state.visibleLinks,
      openInSidebarCallback: () {
        final isSplitOpen = state.showSplitView &&
            (state.activeCommentators.isNotEmpty || _sidebarTabIndex != null);

        if (isSplitOpen) {
          // אם החלונית פתוחה - סוגר אותה
          context.read<TextBookBloc>().add(const ToggleSplitView(false));
        } else {
          // אם החלונית סגורה - פותח אותה עם כרטיסיית הקישורים
          setState(() {
            _sidebarTabIndex = 1; // כרטיסיית הקישורים
          });
          context.read<TextBookBloc>().add(const ToggleSplitView(true));
        }
      },
    );
  }

  Widget _buildCommentaryView() {
    return const CommentatorsListView();
  }
}

// החלף את כל המחלקה הזו בקובץ text_book_screen.TXT

/// Tabbed dialog for error reporting with regular and phone options
class _TabbedReportDialog extends StatefulWidget {
  final String visibleText;
  final double fontSize;
  final String bookTitle;
  final int currentLineNumber;
  final TextBookLoaded state;

  const _TabbedReportDialog({
    required this.visibleText,
    required this.fontSize,
    required this.bookTitle,
    required this.currentLineNumber,
    required this.state,
  });

  @override
  State<_TabbedReportDialog> createState() => _TabbedReportDialogState();
}

class _TabbedReportDialogState extends State<_TabbedReportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedText;
  final DataCollectionService _dataService = DataCollectionService();

  // Phone report data
  String _libraryVersion = 'unknown';
  int? _bookId;
  bool _isLoadingData = true;
  List<String> _dataErrors = [];

  // הסרנו את הפונקציה המיותרת _calculateLineNumberForSelectedText

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // טען נתוני דיווח טלפוני רק אחרי שהדיאלוג נפתח
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPhoneReportData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneReportData() async {
    try {
      final availability =
          await _dataService.checkDataAvailability(widget.bookTitle);

      if (mounted) {
        setState(() {
          _libraryVersion = availability['libraryVersion'] ?? 'unknown';
          _bookId = availability['bookId'];
          _dataErrors = List<String>.from(availability['errors'] ?? []);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading phone report data: $e');
      if (mounted) {
        setState(() {
          _dataErrors = ['שגיאה בטעינת נתוני הדיווח'];
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Dialog title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'דיווח על טעות בספר',
                style: Theme.of(context).textTheme.headlineSmall,
                textDirection: TextDirection.rtl,
              ),
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'דיווח רגיל'),
                Tab(text: 'דיווח דרך קו אוצריא'),
              ],
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRegularReportTab(),
                  _buildPhoneReportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularReportTab() {
    return _RegularReportTab(
      visibleText: widget.visibleText,
      fontSize: widget.fontSize,
      initialSelectedText: _selectedText,
      onTextSelected: (text) {
        setState(() {
          _selectedText = text;
        });
      },
      onSubmit: (reportData) {
        Navigator.of(context).pop(reportData);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildPhoneReportTab() {
    if (_isLoadingData) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('טוען נתוני דיווח...'),
          ],
        ),
      );
    }

    if (_dataErrors.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'לא ניתן לטעון את נתוני הדיווח:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._dataErrors.map((error) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('סגור'),
            ),
          ],
        ),
      );
    }

    // --- כאן התיקון המרכזי ---
    return PhoneReportTab(
      visibleText: widget.visibleText,
      fontSize: widget.fontSize,
      libraryVersion: _libraryVersion,
      bookId: _bookId,
      lineNumber: widget.currentLineNumber, // העבר את מספר השורה ההתחלתי
      initialSelectedText: _selectedText,
      // עדכן את ה-onSubmit כדי לקבל את מספר השורה המחושב בחזרה
      onSubmit: (selectedText, errorId, moreInfo, lineNumber) async {
        final reportData = PhoneReportData(
          selectedText: selectedText,
          errorId: errorId,
          moreInfo: moreInfo,
          libraryVersion: _libraryVersion,
          bookId: _bookId!,
          lineNumber: lineNumber, // השתמש במספר השורה המעודכן שהתקבל!
        );
        Navigator.of(context).pop(reportData);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }
}

/// Regular report tab widget
class _RegularReportTab extends StatefulWidget {
  final String visibleText;
  final double fontSize;
  final String? initialSelectedText;
  final Function(String) onTextSelected;
  final Function(ReportedErrorData) onSubmit;
  final VoidCallback onCancel;

  const _RegularReportTab({
    required this.visibleText,
    required this.fontSize,
    this.initialSelectedText,
    required this.onTextSelected,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<_RegularReportTab> createState() => _RegularReportTabState();
}

class _RegularReportTabState extends State<_RegularReportTab> {
  String? _selectedContent;
  final TextEditingController _detailsController = TextEditingController();
  int? _selectionStart;
  int? _selectionEnd;

  @override
  void initState() {
    super.initState();
    _selectedContent = widget.initialSelectedText;
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('סמן את הטקסט שבו נמצאת הטעות:'),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.3,
            ),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Builder(
                  builder: (context) => TextSelectionTheme(
                    data: const TextSelectionThemeData(
                      selectionColor: Colors.transparent,
                    ),
                    child: SelectableText.rich(
                      TextSpan(
                        children: () {
                          final text = widget.visibleText;
                          final start = _selectionStart ?? -1;
                          final end = _selectionEnd ?? -1;
                          final hasSel =
                              start >= 0 && end > start && end <= text.length;
                          if (!hasSel) {
                            return [TextSpan(text: text)];
                          }
                          final highlight = Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.25);
                          return [
                            if (start > 0)
                              TextSpan(text: text.substring(0, start)),
                            TextSpan(
                              text: text.substring(start, end),
                              style: TextStyle(backgroundColor: highlight),
                            ),
                            if (end < text.length)
                              TextSpan(text: text.substring(end)),
                          ];
                        }(),
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontFamily:
                              Settings.getValue('key-font-family') ?? 'candara',
                        ),
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      onSelectionChanged: (selection, cause) {
                        if (selection.start != selection.end) {
                          final newContent = widget.visibleText.substring(
                            selection.start,
                            selection.end,
                          );
                          if (newContent.isNotEmpty) {
                            setState(() {
                              _selectedContent = newContent;
                              _selectionStart = selection.start;
                              _selectionEnd = selection.end;
                            });
                            widget.onTextSelected(newContent);
                          }
                        }
                      },
                      contextMenuBuilder: (context, editableTextState) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
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
            controller: _detailsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: 'כתוב כאן מה לא תקין, הצע תיקון וכו\'',
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('ביטול'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedContent == null || _selectedContent!.isEmpty
                    ? null
                    : () {
                        widget.onSubmit(
                          ReportedErrorData(
                            selectedText: _selectedContent!,
                            errorDetails: _detailsController.text.trim(),
                          ),
                        );
                      },
                child: const Text('המשך'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildFullFileEditorButton(BuildContext context, TextBookLoaded state) {
  return IconButton(
    onPressed: () => _handleFullFileEditorPress(context, state),
    icon: const Icon(Icons.edit_document),
    tooltip: 'ערוך את הספר (Ctrl+Shift+E)',
  );
}

void _handleTextEditorPress(BuildContext context, TextBookLoaded state) {
  final positions = state.positionsListener.itemPositions.value;
  if (positions.isEmpty) return;

  final currentIndex = positions.first.index;
  context.read<TextBookBloc>().add(OpenEditor(index: currentIndex));
}

void _handleFullFileEditorPress(BuildContext context, TextBookLoaded state) {
  context.read<TextBookBloc>().add(OpenFullFileEditor());
}

bool _handleGlobalKeyEvent(
    KeyEvent event, BuildContext context, TextBookLoaded state) {
  if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      case LogicalKeyboardKey.keyE:
        if (!state.isEditorOpen) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            _handleFullFileEditorPress(context, state);
          } else {
            _handleTextEditorPress(context, state);
          }
          return true;
        }
        break;
    }
  }
  return false;
}

void _openEditorDialog(BuildContext context, TextBookLoaded state) async {
  if (state.editorIndex == null || state.editorSectionId == null) return;

  final settings = EditorSettingsHelper.getSettings();

  // Reload the content from file system to ensure fresh data
  String freshContent = '';
  try {
    // Try to reload content from file system
    final dataProvider = FileSystemData.instance;
    freshContent = await dataProvider.getBookText(state.book.title);
  } catch (e) {
    debugPrint('Failed to load fresh content: $e');
    // Fall back to cached content
    freshContent = state.editorText ?? '';
  }

  if (!context.mounted) return;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => BlocProvider.value(
      value: context.read<TextBookBloc>(),
      child: TextSectionEditorDialog(
        bookId: state.book.title,
        sectionIndex: state.editorIndex!,
        sectionId: state.editorSectionId!,
        initialContent:
            freshContent.isNotEmpty ? freshContent : state.editorText ?? '',
        hasLinksFile: state.hasLinksFile,
        hasDraft: state.hasDraft,
        settings: settings,
      ),
    ),
  );

  if (!context.mounted) return;

  // Close editor when dialog is dismissed
  context.read<TextBookBloc>().add(const CloseEditor());
}
