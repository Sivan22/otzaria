import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:csv/csv.dart';
import 'package:otzaria/core/scaffold_messenger.dart';
import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
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
import 'package:otzaria/personal_notes/personal_notes_system.dart';
import 'package:otzaria/models/phone_report_data.dart';
import 'package:otzaria/services/data_collection_service.dart';
import 'package:otzaria/services/phone_report_service.dart';
import 'package:window_manager/window_manager.dart';

import 'package:otzaria/widgets/phone_report_tab.dart';
import 'package:otzaria/widgets/responsive_action_bar.dart';
import 'package:shamor_zachor/providers/shamor_zachor_data_provider.dart';
import 'package:shamor_zachor/providers/shamor_zachor_progress_provider.dart';
import 'package:shamor_zachor/models/book_model.dart';
import 'package:otzaria/i18n/translations.g.dart';

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

  /// Check if book is already being tracked in Shamor Zachor
  bool _isBookTrackedInShamorZachor(String bookTitle) {
    try {
      final dataProvider = context.read<ShamorZachorDataProvider>();
      if (!dataProvider.hasData) {
        return false;
      }

      // Extract clean book name
      String cleanBookName = bookTitle;
      if (bookTitle.contains(' - ')) {
        final parts = bookTitle.split(' - ');
        cleanBookName = parts.last.trim();
      }

      // For dynamic provider, use the dedicated method
      if (dataProvider.useDynamicLoader) {
        // Try to detect category (similar to add function)
        // For now, search across all categories
        final searchResults = dataProvider.searchBooks(cleanBookName);
        return searchResults.any((result) =>
            result.bookName == cleanBookName ||
            result.bookName.contains(cleanBookName) ||
            cleanBookName.contains(result.bookName));
      }

      // Legacy: Search for the book
      final searchResults = dataProvider.searchBooks(cleanBookName);

      // If found in existing categories, it's tracked
      return searchResults.any((result) =>
          result.bookName == cleanBookName ||
          result.bookName.contains(cleanBookName) ||
          cleanBookName.contains(result.bookName));
    } catch (e) {
      debugPrint('Error checking if book is tracked: $e');
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

      // חילוץ שם הפרק מהפניה
      String? chapterName = _extractChapterName(currentRef);

      // אם לא הצלחנו לחלץ שם פרק, נשתמש בכל הפניה
      if (chapterName == null || chapterName.isEmpty) {
        chapterName = currentRef;
      }

      debugPrint('Chapter name: $chapterName');
      debugPrint('Book content type: ${bookDetails.contentType}');
      debugPrint('Book is daf type: ${bookDetails.isDafType}');
      debugPrint('Total learnable items: ${bookDetails.learnableItems.length}');

      // מציאת הפריט הרלוונטי בשמור וזכור
      final learnableItems = bookDetails.learnableItems;

      // חיפוש הפריט המתאים לפי שם הכותרת (כפי שהיא מופיעה בטקסט)
      LearnableItem? targetItem;

      // נחפש לפי שם הכותרת הנוכחית
      final searchTitle = chapterName;

      debugPrint('Searching for title: "$searchTitle"');
      debugPrint('Available learnable items:');
      for (int i = 0; i < learnableItems.length && i < 10; i++) {
        final item = learnableItems[i];
        debugPrint(
            '  [$i] displayLabel: "${item.displayLabel}", partName: "${item.partName}", hierarchyPath: ${item.hierarchyPath}');
      }
      if (learnableItems.length > 10) {
        debugPrint('  ... and ${learnableItems.length - 10} more items');
      }

      try {
        // חיפוש לפי displayLabel או partName שמכיל את שם הכותרת
        targetItem = learnableItems.firstWhere(
          (item) {
            // בדיקה לפי displayLabel
            if (item.displayLabel != null &&
                item.displayLabel!.contains(searchTitle)) {
              return true;
            }
            // בדיקה לפי partName
            if (item.partName.contains(searchTitle)) {
              return true;
            }
            // בדיקה לפי hierarchyPath
            if (item.hierarchyPath.any((path) => path.contains(searchTitle))) {
              return true;
            }
            return false;
          },
        );
      } catch (e) {
        // אם לא מצאנו בחיפוש מדויק, ננסה חיפוש חלקי
        try {
          targetItem = learnableItems.firstWhere(
            (item) {
              final itemTitle = item.displayLabel ?? item.partName;
              final searchWords = searchTitle.split(' ');
              return searchWords
                  .any((word) => word.length > 2 && itemTitle.contains(word));
            },
          );
        } catch (e2) {
          targetItem = null;
        }
      }

      if (targetItem == null) {
        throw Exception('$searchTitle לא נמצא בשמור וזכור');
      }

      debugPrint(
          'Found target item: displayLabel="${targetItem.displayLabel}", partName="${targetItem.partName}"');

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
        UiSnack.show('אין מקום פנוי ב$chapterName, למדת הרבה!');
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
      final displayName = chapterName;
      UiSnack.showSuccess('$displayName סומן כ$columnName בהצלחה!');
    } catch (e) {
      debugPrint('Error in _markShamorZachorProgress: $e');
      UiSnack.showError('שגיאה בסימון: ${e.toString()}');
    }
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
      length: 3, // יש 3 לשוניות
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
              final screenWidth = MediaQuery.of(context).size.width;
              return Scaffold(
                appBar: AppBar(
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                  shape: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 0.3,
                    ),
                  ),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  centerTitle: false,
                  title: Text(
                    widget.tab.book.title,
                    style: const TextStyle(fontSize: 17),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  leading: IconButton(
                    icon: const Icon(FluentIcons.navigation_24_regular),
                    tooltip: "ניווט וחיפוש",
                    onPressed: null,
                  ),
                  actions: [
                    ResponsiveActionBar(
                      key: ValueKey('loading_actions_$screenWidth'),
                      actions: [
                        ActionButtonData(
                          widget: IconButton(
                            icon:
                                const Icon(FluentIcons.document_pdf_24_regular),
                            tooltip: 'פתח ספר במהדורה מודפסת',
                            onPressed: null,
                          ),
                          icon: FluentIcons.document_pdf_24_regular,
                          tooltip: 'פתח ספר במהדורה מודפסת',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.panel_left_24_regular),
                            tooltip: 'הצגת מפרשים',
                            onPressed: null,
                          ),
                          icon: FluentIcons.panel_left_24_regular,
                          tooltip: 'הצגת מפרשים',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.text_font_24_regular),
                            tooltip: 'הצג או הסתר ניקוד',
                            onPressed: null,
                          ),
                          icon: FluentIcons.text_font_24_regular,
                          tooltip: 'הצג או הסתר ניקוד',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.search_24_regular),
                            tooltip: 'חיפוש',
                            onPressed: null,
                          ),
                          icon: FluentIcons.search_24_regular,
                          tooltip: 'חיפוש',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.zoom_in_24_regular),
                            tooltip: 'הגדלת טקסט',
                            onPressed: null,
                          ),
                          icon: FluentIcons.zoom_in_24_regular,
                          tooltip: 'הגדלת טקסט',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.zoom_out_24_regular),
                            tooltip: 'הקטנת טקסט',
                            onPressed: null,
                          ),
                          icon: FluentIcons.zoom_out_24_regular,
                          tooltip: 'הקטנת טקסט',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(
                                FluentIcons.arrow_previous_24_filled),
                            tooltip: 'תחילת הספר',
                            onPressed: null,
                          ),
                          icon: FluentIcons.arrow_previous_24_filled,
                          tooltip: 'תחילת הספר',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon:
                                const Icon(FluentIcons.chevron_left_24_regular),
                            tooltip: 'הקטע הקודם',
                            onPressed: null,
                          ),
                          icon: FluentIcons.chevron_left_24_regular,
                          tooltip: 'הקטע הקודם',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(
                                FluentIcons.chevron_right_24_regular),
                            tooltip: 'הקטע הבא',
                            onPressed: null,
                          ),
                          icon: FluentIcons.chevron_right_24_regular,
                          tooltip: 'הקטע הבא',
                          onPressed: null,
                        ),
                        ActionButtonData(
                          widget: IconButton(
                            icon: const Icon(FluentIcons.arrow_next_24_filled),
                            tooltip: 'סוף הספר',
                            onPressed: null,
                          ),
                          icon: FluentIcons.arrow_next_24_filled,
                          tooltip: 'סוף הספר',
                          onPressed: null,
                        ),
                      ],
                      alwaysInMenu: [],
                      maxVisibleButtons: screenWidth < 400
                          ? 2
                          : screenWidth < 500
                              ? 4
                              : screenWidth < 600
                                  ? 6
                                  : screenWidth < 700
                                      ? 8
                                      : screenWidth < 800
                                          ? 10
                                          : screenWidth < 900
                                              ? 12
                                              : screenWidth < 1100
                                                  ? 14
                                                  : 999,
                    ),
                  ],
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            if (state is TextBookError) {
              return Center(child: Text('${context.t.common.error}: ${(state).message}'));
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
            return Center(child: Text(context.t.common.unknown));
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
      icon: const Icon(FluentIcons.navigation_24_regular),
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

    // נקבע כמה כפתורים להציג בהתאם לרוחב המסך
    // שים לב: הכפתורים יוסתרו בסדר ההצגה (מימין לשמאל, כך שהימני ביותר יעלם אחרון)
    int maxButtons;

    if (screenWidth < 400) {
      maxButtons = 2; // 2 כפתורים + "..." במסכים קטנים מאוד
    } else if (screenWidth < 500) {
      maxButtons = 4; // 4 כפתורים + "..." במסכים קטנים
    } else if (screenWidth < 600) {
      maxButtons = 6; // 6 כפתורים + "..." במסכים בינוניים קטנים
    } else if (screenWidth < 700) {
      maxButtons = 8; // 8 כפתורים + "..." במסכים בינוניים
    } else if (screenWidth < 800) {
      maxButtons = 10; // 10 כפתורים + "..." במסכים בינוניים גדולים
    } else if (screenWidth < 900) {
      maxButtons = 12; // 12 כפתורים + "..." במסכים גדולים
    } else if (screenWidth < 1100) {
      maxButtons = 14; // 14 כפתורים + "..." במסכים גדולים יותר
    } else {
      maxButtons =
          999; // כל הכפתורים החיצוניים במסכים רחבים מאוד (ה-5 הקבועים תמיד בתפריט)
    }

    return [
      ResponsiveActionBar(
        key: ValueKey('responsive_actions_$screenWidth'),
        actions: _buildDisplayOrderActions(context, state),
        alwaysInMenu: _buildAlwaysInMenuActions(context, state),
        maxVisibleButtons: maxButtons,
      ),
    ];
  }

  /// בניית רשימת כפתורים בסדר ההצגה (מימין לשמאל ב-RTL)
  /// הכפתורים יוסתרו מהסוף לתחילה, כך שהכפתור הימני ביותר (ראשון ברשימה) יעלם אחרון
  List<ActionButtonData> _buildDisplayOrderActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // 1) PDF Button (ראשון מימין - יעלם אחרון!)
      ActionButtonData(
        widget: _buildPdfButton(context, state),
        icon: FluentIcons.document_pdf_24_regular,
        tooltip: 'פתח ספר במהדורה מודפסת',
        onPressed: () => _handlePdfButtonPress(context, state),
      ),

      // 2) Split View Button
      ActionButtonData(
        widget: _buildSplitViewButton(context, state),
        icon: FluentIcons.panel_left_24_regular,
        tooltip: state.showSplitView
            ? 'הצגת מפרשים מתחת הטקסט'
            : 'הצגת מפרשים בצד הטקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              ToggleSplitView(!state.showSplitView),
            ),
      ),

      // 3) Nikud Button
      ActionButtonData(
        widget: _buildNikudButton(context, state),
        icon: FluentIcons.text_font_24_regular,
        tooltip: 'הצג או הסתר ניקוד',
        onPressed: () =>
            context.read<TextBookBloc>().add(ToggleNikud(!state.removeNikud)),
      ),

      // 4) Search Button
      ActionButtonData(
        widget: _buildSearchButton(context, state),
        icon: FluentIcons.search_24_regular,
        tooltip: 'חיפוש',
        onPressed: () {
          context.read<TextBookBloc>().add(const ToggleLeftPane(true));
          tabController.index = 1;
          textSearchFocusNode.requestFocus();
        },
      ),

      // 5) Zoom In Button
      ActionButtonData(
        widget: _buildZoomInButton(context, state),
        icon: FluentIcons.zoom_in_24_regular,
        tooltip: 'הגדלת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(min(50.0, state.fontSize + 3)),
            ),
      ),

      // 6) Zoom Out Button
      ActionButtonData(
        widget: _buildZoomOutButton(context, state),
        icon: FluentIcons.zoom_out_24_regular,
        tooltip: 'הקטנת טקסט',
        onPressed: () => context.read<TextBookBloc>().add(
              UpdateFontSize(max(15.0, state.fontSize - 3)),
            ),
      ),

      // 7) Navigation Buttons
      ActionButtonData(
        widget: _buildFirstPageButton(state),
        icon: FluentIcons.arrow_previous_24_filled,
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
        icon: FluentIcons.chevron_left_24_regular,
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
        icon: FluentIcons.chevron_right_24_regular,
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
        icon: FluentIcons.arrow_next_24_filled,
        tooltip: 'סוף הספר',
        onPressed: () {
          state.scrollController.scrollTo(
            index: state.content.length,
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    ];
  }

  /// כפתורים שתמיד יהיו בתפריט "..." (בסדר הרצוי)
  List<ActionButtonData> _buildAlwaysInMenuActions(
    BuildContext context,
    TextBookLoaded state,
  ) {
    return [
      // 1) הוספת סימניה
      ActionButtonData(
        widget: _buildBookmarkButton(context, state),
        icon: FluentIcons.bookmark_add_24_regular,
        tooltip: 'הוספת סימניה',
        onPressed: () => _handleBookmarkPress(context, state),
      ),

      // 2) הוסף הערה לקטע זה
      ActionButtonData(
        widget: _buildAddNoteButton(context, state),
        icon: FluentIcons.note_add_24_regular,
        tooltip: 'הוסף הערה לקטע זה',
        onPressed: () => _handleAddNotePress(context, state),
      ),

      // 3) הצג הערות
      ActionButtonData(
        widget: _buildShowNotesButton(context, state),
        icon: FluentIcons.note_24_regular,
        tooltip: 'הצג הערות',
        onPressed: () {
          // פתיחת חלונית הצד עם כרטיסיית ההערות (אינדקס 2)
          setState(() {
            _sidebarTabIndex = 2; // כרטיסיית ההערות
          });
          context.read<TextBookBloc>().add(const ToggleSplitView(true));
        },
      ),

      // 4) שמור וזכור - סמן כנלמד או הוסף למעקב
      ActionButtonData(
        widget: _buildShamorZachorButton(context, state),
        icon: _isBookTrackedInShamorZachor(state.book.title)
            ? FluentIcons.checkmark_circle_24_regular
            : FluentIcons.add_circle_24_regular,
        tooltip: _isBookTrackedInShamorZachor(state.book.title)
            ? 'סמן כנלמד בשמור וזכור'
            : 'הוסף למעקב לימוד בשמור וזכור',
        onPressed: () {
          if (_isBookTrackedInShamorZachor(state.book.title)) {
            _markShamorZachorProgress(state.book.title);
          } else {
            _addBookToShamorZachorTracking(state.book.title);
          }
        },
      ),

      // 5) ערוך את הספר
      ActionButtonData(
        widget: _buildFullFileEditorButton(context, state),
        icon: FluentIcons.document_edit_24_regular,
        tooltip: 'ערוך את הספר',
        onPressed: () => _handleFullFileEditorPress(context, state),
      ),

      // 6) דווח על טעות בספר
      ActionButtonData(
        widget: _buildReportBugButton(context, state),
        icon: FluentIcons.error_circle_24_regular,
        tooltip: 'דווח על טעות בספר',
        onPressed: () => _showReportBugDialog(context, state),
      ),

      // 7) הדפסה
      ActionButtonData(
        widget: _buildPrintButton(context, state),
        icon: FluentIcons.print_24_regular,
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
    ];
  }

  Widget _buildPdfButton(BuildContext context, TextBookLoaded state) {
    return FutureBuilder(
      future: DataRepository.instance.library.then(
        (library) => library.findBookByTitle(state.book.title, PdfBook),
      ),
      builder: (context, snapshot) => snapshot.hasData
          ? IconButton(
              icon: const Icon(FluentIcons.document_pdf_24_regular),
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
      icon: RotatedBox(
        quarterTurns: state.showSplitView ? 0 : 3,  // מסובב 270 מעלות (90 נגד כיוון השעון) כשמתחת
        child: const Icon(FluentIcons.panel_left_24_regular),
      ),
      tooltip: state.showSplitView
          ? 'הצגת מפרשים מתחת הטקסט'
          : 'הצגת מפרשים בצד הטקסט',
    );
  }

  Widget _buildNikudButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () =>
          context.read<TextBookBloc>().add(ToggleNikud(!state.removeNikud)),
      icon: const Icon(FluentIcons.text_font_24_regular),
      tooltip: 'הצג או הסתר ניקוד',
    );
  }

  Widget _buildBookmarkButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-add-bookmark') ?? 'ctrl+b';
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
      icon: const Icon(FluentIcons.bookmark_add_24_regular),
      tooltip: 'הוספת סימניה (${shortcut.toUpperCase()})',
    );
  }

  Widget _buildShowNotesButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      onPressed: () {
        // פתיחת חלונית הצד עם כרטיסיית ההערות (אינדקס 2)
        setState(() {
          _sidebarTabIndex = 2; // כרטיסיית ההערות
        });
        context.read<TextBookBloc>().add(const ToggleSplitView(true));
      },
      icon: const Icon(FluentIcons.note_24_regular),
      tooltip: 'הצג הערות',
    );
  }

  Widget _buildAddNoteButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-add-note') ?? 'ctrl+n';
    return IconButton(
      onPressed: () => _handleAddNotePress(context, state),
      icon: const Icon(FluentIcons.note_add_24_regular),
      tooltip: 'הוסף הערה לקטע זה (${shortcut.toUpperCase()})',
    );
  }

  Widget _buildSearchButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-search-in-book') ?? 'ctrl+f';
    return IconButton(
      onPressed: () {
        context.read<TextBookBloc>().add(const ToggleLeftPane(true));
        tabController.index = 1;
        textSearchFocusNode.requestFocus();
      },
      icon: const Icon(FluentIcons.search_24_regular),
      tooltip: 'חיפוש (${shortcut.toUpperCase()})',
    );
  }

  Widget _buildZoomInButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.zoom_in_24_regular),
      tooltip: 'הגדלת טקסט (CTRL + +)',
      onPressed: () => context.read<TextBookBloc>().add(
            UpdateFontSize(min(50.0, state.fontSize + 3)),
          ),
    );
  }

  Widget _buildZoomOutButton(BuildContext context, TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.zoom_out_24_regular),
      tooltip: 'הקטנת טקסט (CTRL + -)',
      onPressed: () => context.read<TextBookBloc>().add(
            UpdateFontSize(max(15.0, state.fontSize - 3)),
          ),
    );
  }

  Widget _buildFirstPageButton(TextBookLoaded state) {
    return IconButton(
      icon: const Icon(FluentIcons.arrow_previous_24_filled),
      tooltip: 'תחילת הספר (CTRL + HOME)',
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
      icon: const Icon(FluentIcons.chevron_left_24_regular),
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
      icon: const Icon(FluentIcons.chevron_right_24_regular),
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
      icon: const Icon(FluentIcons.arrow_next_24_filled),
      tooltip: 'סוף הספר (CTRL + END)',
      onPressed: () {
        state.scrollController.scrollTo(
          index: state.content.length,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildPrintButton(BuildContext context, TextBookLoaded state) {
    final shortcut =
        Settings.getValue<String>('key-shortcut-print') ?? 'ctrl+p';
    return IconButton(
      icon: const Icon(FluentIcons.print_24_regular),
      tooltip: 'הדפסה (${shortcut.toUpperCase()})',
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
      icon: const Icon(FluentIcons.error_circle_24_regular),
      tooltip: 'דווח על טעות בספר',
      onPressed: () => _showReportBugDialog(context, state),
    );
  }

  Widget _buildShamorZachorButton(BuildContext context, TextBookLoaded state) {
    // Always show button - either for marking progress or for adding to tracking
    final isTracked = _isBookTrackedInShamorZachor(state.book.title);

    return IconButton(
      onPressed: () {
        if (isTracked) {
          // Book is already tracked - mark progress
          _markShamorZachorProgress(state.book.title);
        } else {
          // Book is not tracked - add to tracking
          _addBookToShamorZachorTracking(state.book.title);
        }
      },
      icon: isTracked
          ? Image.asset(
              'assets/icon/shamor_zachor_with_v.png',
              width: 24,
              height: 24,
            )
          : const Icon(FluentIcons.add_circle_24_regular, size: 24),
      tooltip:
          isTracked ? 'סמן כנלמד בשמור וזכור' : 'הוסף למעקב לימוד בשמור וזכור',
    );
  }

  /// Add book to Shamor Zachor tracking
  Future<void> _addBookToShamorZachorTracking(String bookTitle) async {
    try {
      final state = context.read<TextBookBloc>().state as TextBookLoaded;
      final dataProvider = context.read<ShamorZachorDataProvider>();

      // Check if provider supports dynamic loading
      if (!dataProvider.useDynamicLoader) {
        UiSnack.showError(
            'הוספת ספרים מותאמת אישית דורשת את הגרסה החדשה של שמור וזכור');
        return;
      }

      // 1. Get book path from library
      final titleToPath = await state.book.data.titleToPath;
      final bookPath = titleToPath[bookTitle];

      if (bookPath == null) {
        UiSnack.showError('לא נמצא נתיב לספר');
        return;
      }

      debugPrint('Adding book to tracking - Path: $bookPath');

      // 2. Detect category and content type from path
      String categoryName = 'כללי';
      String contentType = 'פרק'; // Default

      if (bookPath.contains('תלמוד בבלי')) {
        categoryName = 'תלמוד בבלי';
        contentType = 'דף';
      } else if (bookPath.contains('תנך') || bookPath.contains('תנ"ך')) {
        categoryName = 'תנ"ך';
        contentType = 'פרק';
      } else if (bookPath.contains('משנה') && !bookPath.contains('תורה')) {
        categoryName = 'משנה';
        contentType = 'משנה';
      } else if (bookPath.contains('ירושלמי')) {
        categoryName = 'תלמוד ירושלמי';
        contentType = 'דף';
      } else if (bookPath.contains('רמב"ם') || bookPath.contains('רמבם')) {
        categoryName = 'רמב"ם';
        contentType = 'הלכה';
      } else if (bookPath.contains('הלכה')) {
        categoryName = 'הלכה';
        contentType = 'הלכה';
      }

      debugPrint(
          'Detected - Category: $categoryName, ContentType: $contentType');

      // 3. Extract clean book name
      String cleanBookName = bookTitle;
      if (bookTitle.contains(' - ')) {
        final parts = bookTitle.split(' - ');
        cleanBookName = parts.last.trim();
      }

      // 4. Show loading indicator
      UiSnack.show('סורק ספר ומוסיף למעקב...');

      // 5. Add book via provider
      await dataProvider.addCustomBook(
        bookName: cleanBookName,
        categoryName: categoryName,
        bookPath: bookPath,
        contentType: contentType,
      );

      debugPrint(
          'Book added to tracking: $cleanBookName in category $categoryName');
      debugPrint(
          'All categories after add: ${dataProvider.getCategoryNames()}');
      debugPrint(
          'Has category "$categoryName": ${dataProvider.getCategory(categoryName) != null}');

      // 6. Success message
      UiSnack.show('הספר "$cleanBookName" נוסף למעקב בהצלחה!');

      // 7. Update UI to reflect the change
      setState(() {});
    } catch (e, stackTrace) {
      debugPrint('Error adding book to Shamor Zachor: $e');
      debugPrint('Stack trace: $stackTrace');
      UiSnack.showError('שגיאה בהוספת הספר למעקב: ${e.toString()}');
    }
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

  Future<void> _handleAddNotePress(
      BuildContext context, TextBookLoaded state) async {
    final positions = state.positionsListener.itemPositions.value;
    final currentIndex = positions.isNotEmpty ? positions.first.index : 0;
    final controller = TextEditingController(
      text: state.selectedTextForNote?.trim() ?? '',
    );
    final notesBloc = context.read<PersonalNotesBloc>();
    final textBookBloc = context.read<TextBookBloc>();

    final noteContent = await showDialog<String>(
      context: context,
      builder: (dialogContext) => PersonalNoteEditorDialog(
        title: context.t.notes.addNoteToSection,
        controller: controller,
      ),
    );

    if (noteContent == null) {
      return;
    }

    final trimmed = noteContent.trim();
    if (trimmed.isEmpty) {
      UiSnack.show('ההערה ריקה, לא נשמרה');
      return;
    }

    if (!mounted) return;

    try {
      notesBloc.add(AddPersonalNote(
        bookId: state.book.title,
        lineNumber: currentIndex + 1,
        content: trimmed,
      ));
      textBookBloc.add(const ToggleSplitView(true));
      setState(() {
        _sidebarTabIndex = 2;
      });
      UiSnack.show('ההערה נשמרה בהצלחה');
    } catch (e) {
      UiSnack.showError('שמירת ההערה נכשלה: $e');
    }
  }

  void _handleBookmarkPress(BuildContext context, TextBookLoaded state) async {
    final index = state.positionsListener.itemPositions.value.first.index;
    final toc = state.book.tableOfContents;
    final bookmarkBloc = context.read<BookmarkBloc>();
    final theme = Theme.of(context);
    final ref = await refFromIndex(index, toc);
    if (!mounted || !context.mounted) return;

    final bookmarkAdded = bookmarkBloc.addBookmark(
      ref: ref,
      book: state.book,
      index: index,
      commentatorsToShow: state.activeCommentators,
    );

    final successColor =
        bookmarkAdded ? theme.colorScheme.tertiaryContainer : null;
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
          title: Text(context.t.report.errorReportTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t.report.selectedText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(reportData.selectedText),
                const SizedBox(height: 16),
                if (reportData.errorDetails.isNotEmpty) ...[
                  Text(
                    context.t.report.errorDetails,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(reportData.errorDetails),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(context.t.common.cancel),
              onPressed: () => Navigator.of(context).pop(ReportAction.cancel),
            ),
            TextButton(
              child: Text(context.t.report.saveForLater),
              onPressed: () =>
                  Navigator.of(context).pop(ReportAction.saveForLater),
            ),
            TextButton(
              child: Text(context.t.report.openEmail),
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
      final String? sourceFolder = bookDetails['תיקיית המקור'];
      final emailAddress = sourceFolder?.contains('sefaria') == true ||
              sourceFolder?.contains('sefariaToOtzaria') == true
          ? 'corrections@sefaria.org'
          : sourceFolder?.contains('wiki_jewish_books') == true
              ? 'WikiJewishBooks@gmail.com'
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
          _showSimpleSnack(context.t.report.cannotOpenEmail);
        }
      } catch (_) {
        _showSimpleSnack(context.t.report.cannotOpenEmail);
      }
    } else if (action == ReportAction.saveForLater) {
      final saved = await _saveReportToFile(emailBody);
      if (!saved) {
        _showSimpleSnack(context.t.report.saveFailed);
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
      _showSimpleSnack('${context.t.report.sendError}: ${e.toString()}');
    }
  }

  /// Show success dialog for phone report
  void _showPhoneReportSuccessDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t.report.reportSentSuccessfully),
        content: Text(context.t.report.reportSentMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open another report dialog
              _showReportBugDialog(context,
                  context.read<TextBookBloc>().state as TextBookLoaded);
            },
            child: Text(context.t.report.openAnotherReport),
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
        "${context.t.report.reportSavedToFile(fileName: _reportFileName)}\n"
        "${context.t.report.youHaveReports(count: count)}\n"
        "${context.t.report.canSendToEmail(email: _fallbackMail)}";

    UiSnack.showWithAction(
      message: message,
      actionLabel: context.t.report.send,
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
        _showSimpleSnack(context.t.report.cannotOpenEmail);
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
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: tabController,
                          tabs: const [
                            Tab(text: 'ניווט'),
                            Tab(text: 'חיפוש'),
                            Tab(text: 'מפרשים'),
                          ],
                          labelColor: Theme.of(context).colorScheme.primary,
                          unselectedLabelColor: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          dividerColor: Colors.transparent,
                          overlayColor: WidgetStateProperty.all(Colors.transparent),
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
                          icon: AnimatedRotation(
                            turns: (state.pinLeftPane ||
                                    (Settings.getValue<bool>('key-pin-sidebar') ??
                                        false))
                                ? -0.125
                                : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              (state.pinLeftPane ||
                                      (Settings.getValue<bool>(
                                              'key-pin-sidebar') ??
                                          false))
                                  ? FluentIcons.pin_24_filled
                                  : FluentIcons.pin_24_regular,
                            ),
                          ),
                          color: (state.pinLeftPane ||
                                  (Settings.getValue<bool>('key-pin-sidebar') ??
                                      false))
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          isSelected: state.pinLeftPane ||
                              (Settings.getValue<bool>('key-pin-sidebar') ??
                                  false),
                        ),
                    ],
                  ),
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

    // טען נתוני דיווח טלפוני תמיד
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
            // Tab bar - תמיד מציג שתי כרטיסיות
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'שליחת דיווח'),
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
      state: widget.state, // העבר את ה-state כדי לגשת לפרטי הספר
      onTextSelected: (text) {
        setState(() {
          _selectedText = text;
        });
      },
      onSubmit: (reportData) {
        Navigator.of(context).pop(reportData);
      },
      onPhoneSubmit: (phoneReportData) {
        Navigator.of(context).pop(phoneReportData);
      },
      onCancel: () {
        Navigator.of(context).pop();
      },
    );
  }

  Widget _buildPhoneReportTab() {
    if (_isLoadingData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.t.report.loadingReportData),
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
              context.t.report.cannotLoadReportData,
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
              child: Text(context.t.common.close),
            ),
          ],
        ),
      );
    }

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
  final TextBookLoaded state;
  final Function(String) onTextSelected;
  final Function(ReportedErrorData) onSubmit;
  final Function(PhoneReportData) onPhoneSubmit;
  final VoidCallback onCancel;

  const _RegularReportTab({
    required this.visibleText,
    required this.fontSize,
    this.initialSelectedText,
    required this.state,
    required this.onTextSelected,
    required this.onSubmit,
    required this.onPhoneSubmit,
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
  final DataCollectionService _dataService = DataCollectionService();

  // נתונים לדיווח טלפוני
  String _libraryVersion = 'unknown';
  int? _bookId;
  bool _isLoadingPhoneData = false;

  @override
  void initState() {
    super.initState();
    _selectedContent = widget.initialSelectedText;
    _loadPhoneReportData();
  }

  /// טעינת נתוני דיווח טלפוני
  Future<void> _loadPhoneReportData() async {
    setState(() {
      _isLoadingPhoneData = true;
    });

    try {
      final availability =
          await _dataService.checkDataAvailability(widget.state.book.title);

      if (mounted) {
        setState(() {
          _libraryVersion = availability['libraryVersion'] ?? 'unknown';
          _bookId = availability['bookId'];
          _isLoadingPhoneData = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading phone report data: $e');
      if (mounted) {
        setState(() {
          _isLoadingPhoneData = false;
        });
      }
    }
  }

  /// בדיקה אם כפתור "שלח דיווח" צריך להיות מושבת בדיווח הרגיל
  Future<bool> _isPhoneReportDisabled() async {
    try {
      final bookDetails = await _getBookDetails(widget.state.book.title);
      final sourceFolder = bookDetails['תיקיית המקור'];

      if (sourceFolder != null) {
        return sourceFolder.contains('sefariaToOtzaria') ||
            sourceFolder.contains('wiki_jewish_books');
      }

      return false;
    } catch (e) {
      debugPrint('Error checking phone report availability: $e');
      return false;
    }
  }

  /// קבלת פרטי הספר מה-CSV
  Future<Map<String, String>> _getBookDetails(String bookTitle) async {
    try {
      final libraryPath = Settings.getValue('key-library-path');
      if (libraryPath == null || libraryPath.isEmpty) {
        return _getDefaultBookDetails();
      }

      final csvPath =
          '$libraryPath${Platform.pathSeparator}אוצריא${Platform.pathSeparator}אודות התוכנה${Platform.pathSeparator}SourcesBooks.csv';
      final file = File(csvPath);

      if (!await file.exists()) {
        return _getDefaultBookDetails();
      }

      final csvContent = await file.readAsString(encoding: utf8);
      final rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        return _getDefaultBookDetails();
      }

      for (final row in rows.skip(1)) {
        if (row.isNotEmpty && row[0].toString() == bookTitle) {
          final fileNameRaw = row[0].toString();
          return {
            'שם הקובץ': fileNameRaw,
            'נתיב הקובץ': row[1].toString(),
            'תיקיית המקור': row[2].toString(),
          };
        }
      }

      return _getDefaultBookDetails();
    } catch (e) {
      debugPrint('Error reading book details: $e');
      return _getDefaultBookDetails();
    }
  }

  Map<String, String> _getDefaultBookDetails() {
    return {
      'שם הקובץ': 'לא ניתן למצוא את הספר',
      'נתיב הקובץ': 'לא ניתן למצוא את הספר',
      'תיקיית המקור': 'לא ניתן למצוא את הספר',
    };
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
          Text(context.t.report.selectTextWithError),
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
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
              hintText: context.t.report.writeErrorDetails,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _isPhoneReportDisabled(),
            builder: (context, snapshot) {
              final isPhoneDisabled = snapshot.data ?? false;
              final canSubmitRegular =
                  _selectedContent != null && _selectedContent!.isNotEmpty;
              final canSubmitPhone = canSubmitRegular &&
                  !_isLoadingPhoneData &&
                  _bookId != null &&
                  _libraryVersion != 'unknown' &&
                  !isPhoneDisabled;

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    child: Text(context.t.common.cancel),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canSubmitRegular
                        ? () {
                            widget.onSubmit(
                              ReportedErrorData(
                                selectedText: _selectedContent!,
                                errorDetails: _detailsController.text.trim(),
                              ),
                            );
                          }
                        : null,
                    child: Text(context.t.report.sendEmail),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: canSubmitPhone
                        ? () async {
                            // חישוב מספר השורה
                            final lineNumber = _calculateLineNumber();

                            final phoneReportData = PhoneReportData(
                              selectedText: _selectedContent!,
                              errorId: 6, // "אחר" כברירת מחדל
                              moreInfo: _detailsController.text.trim().isEmpty
                                  ? 'more_info'
                                  : _detailsController.text.trim(),
                              libraryVersion: _libraryVersion,
                              bookId: _bookId!,
                              lineNumber: lineNumber,
                            );

                            widget.onPhoneSubmit(phoneReportData);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPhoneDisabled
                          ? Theme.of(context).disabledColor
                          : null,
                    ),
                    child: _isLoadingPhoneData
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isPhoneDisabled ? context.t.report.reportNotAvailable : context.t.report.sendReport),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// חישוב מספר השורה על בסיס הטקסט הנבחר
  int _calculateLineNumber() {
    if (_selectionStart == null) return 1;

    final textBeforeSelection =
        widget.visibleText.substring(0, _selectionStart!);
    final lineOffset = '\n'.allMatches(textBeforeSelection).length;

    // קבלת מספר השורה הנוכחי מה-state
    final positions = widget.state.positionsListener.itemPositions.value;
    final currentIndex = positions.isNotEmpty ? positions.first.index : 0;

    return currentIndex + lineOffset + 1;
  }
}

Widget _buildFullFileEditorButton(BuildContext context, TextBookLoaded state) {
  final shortcut =
      Settings.getValue<String>('key-shortcut-edit-section') ?? 'ctrl+e';
  return IconButton(
    onPressed: () => _handleFullFileEditorPress(context, state),
    icon: const Icon(FluentIcons.document_edit_24_regular),
    tooltip: 'ערוך את הספר (${shortcut.toUpperCase()})',
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
    // קריאת קיצורים מההגדרות
    final editSectionShortcut =
        Settings.getValue<String>('key-shortcut-edit-section') ?? 'ctrl+e';
    final searchInBookShortcut =
        Settings.getValue<String>('key-shortcut-search-in-book') ?? 'ctrl+f';
    final printShortcut =
        Settings.getValue<String>('key-shortcut-print') ?? 'ctrl+p';
    final addBookmarkShortcut =
        Settings.getValue<String>('key-shortcut-add-bookmark') ?? 'ctrl+b';
    final addNoteShortcut =
        Settings.getValue<String>('key-shortcut-add-note') ?? 'ctrl+n';

    switch (event.logicalKey) {
      // עריכת קטע (Ctrl+E כברירת מחדל)
      case LogicalKeyboardKey.keyE:
        if (editSectionShortcut.contains('ctrl+e')) {
          if (!state.isEditorOpen) {
            if (HardwareKeyboard.instance.isShiftPressed) {
              _handleFullFileEditorPress(context, state);
            } else {
              _handleTextEditorPress(context, state);
            }
            return true;
          }
        }
        break;

      // חיפוש בספר (Ctrl+F כברירת מחדל)
      case LogicalKeyboardKey.keyF:
        if (searchInBookShortcut.contains('ctrl+f')) {
          context.read<TextBookBloc>().add(const ToggleLeftPane(true));
          final tabController = context
              .findAncestorStateOfType<_TextBookViewerBlocState>()
              ?.tabController;
          if (tabController != null) {
            tabController.index = 1;
          }
          return true;
        }
        break;

      // הדפסה (Ctrl+P כברירת מחדל)
      case LogicalKeyboardKey.keyP:
        if (printShortcut.contains('ctrl+p')) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PrintingScreen(
                data: Future.value(state.content.join('\n')),
                startLine: state.visibleIndices.first,
                removeNikud: state.removeNikud,
              ),
            ),
          );
          return true;
        }
        break;

      // הוספת סימניה (Ctrl+B כברירת מחדל)
      case LogicalKeyboardKey.keyB:
        if (addBookmarkShortcut.contains('ctrl+b')) {
          _addBookmarkFromKeyboard(context, state);
          return true;
        }
        break;

      // הוספת הערה (Ctrl+N כברירת מחדל)
      case LogicalKeyboardKey.keyN:
        if (addNoteShortcut.contains('ctrl+n')) {
          _addNoteFromKeyboard(context, state);
          return true;
        }
        break;

      // הגדלת טקסט (Ctrl++ או Ctrl+=)
      case LogicalKeyboardKey.equal:
      case LogicalKeyboardKey.add:
        context.read<TextBookBloc>().add(
              UpdateFontSize(min(50.0, state.fontSize + 3)),
            );
        return true;

      // הקטנת טקסט (Ctrl+-)
      case LogicalKeyboardKey.minus:
        context.read<TextBookBloc>().add(
              UpdateFontSize(max(15.0, state.fontSize - 3)),
            );
        return true;

      // איפוס גודל טקסט (Ctrl+0)
      case LogicalKeyboardKey.digit0:
        context.read<TextBookBloc>().add(const UpdateFontSize(25.0));
        return true;
    }
  }

  // ניווט עם Ctrl+Home ו-Ctrl+End
  if (event is KeyDownEvent && HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      // Ctrl+Home - תחילת הספר
      case LogicalKeyboardKey.home:
        state.scrollController.scrollTo(
          index: 0,
          duration: const Duration(milliseconds: 300),
        );
        return true;

      // Ctrl+End - סוף הספר
      case LogicalKeyboardKey.end:
        state.scrollController.scrollTo(
          index: state.content.length - 1,
          duration: const Duration(milliseconds: 300),
        );
        return true;
    }
  }

  // מקשי פונקציה ללא Ctrl
  if (event is KeyDownEvent && !HardwareKeyboard.instance.isControlPressed) {
    switch (event.logicalKey) {
      // F11 - מסך מלא
      case LogicalKeyboardKey.f11:
        if (!Platform.isAndroid && !Platform.isIOS) {
          final settingsBloc = context.read<SettingsBloc>();
          final newFullscreenState = !settingsBloc.state.isFullscreen;
          settingsBloc.add(UpdateIsFullscreen(newFullscreenState));
          windowManager.setFullScreen(newFullscreenState);
          return true;
        }
        break;

      // ESC - יציאה ממסך מלא
      case LogicalKeyboardKey.escape:
        if (!Platform.isAndroid && !Platform.isIOS) {
          final settingsBloc = context.read<SettingsBloc>();
          if (settingsBloc.state.isFullscreen) {
            settingsBloc.add(const UpdateIsFullscreen(false));
            windowManager.setFullScreen(false);
            return true;
          }
        }
        break;
    }
  }

  return false;
}

/// Helper function to add bookmark from keyboard shortcut
void _addBookmarkFromKeyboard(
    BuildContext context, TextBookLoaded state) async {
  final index = state.positionsListener.itemPositions.value.first.index;
  final toc = state.book.tableOfContents;
  final bookmarkBloc = context.read<BookmarkBloc>();
  final ref = await refFromIndex(index, toc);

  if (!context.mounted) return;

  final bookmarkAdded = bookmarkBloc.addBookmark(
    ref: ref,
    book: state.book,
    index: index,
    commentatorsToShow: state.activeCommentators,
  );

  UiSnack.showQuick(
      bookmarkAdded ? 'הסימניה נוספה בהצלחה' : 'הסימניה כבר קיימת');
}

/// Helper function to add note from keyboard shortcut
Future<void> _addNoteFromKeyboard(
    BuildContext context, TextBookLoaded state) async {
  final positions = state.positionsListener.itemPositions.value;
  final currentIndex = positions.isNotEmpty ? positions.first.index : 0;
  final controller = TextEditingController(
    text: state.selectedTextForNote?.trim() ?? '',
  );
  final notesBloc = context.read<PersonalNotesBloc>();
  final textBookBloc = context.read<TextBookBloc>();

  final noteContent = await showDialog<String>(
    context: context,
    builder: (dialogContext) => PersonalNoteEditorDialog(
      title: 'הוסף הערה לקטע זה',
      controller: controller,
    ),
  );

  if (noteContent == null) {
    return;
  }

  final trimmed = noteContent.trim();
  if (trimmed.isEmpty) {
    UiSnack.show('ההערה ריקה, לא נשמרה');
    return;
  }

  if (!context.mounted) return;

  try {
    notesBloc.add(AddPersonalNote(
      bookId: state.book.title,
      lineNumber: currentIndex + 1,
      content: trimmed,
    ));
    textBookBloc.add(const ToggleSplitView(true));
    UiSnack.show('ההערה נשמרה בהצלחה');
  } catch (e) {
    UiSnack.showError('שמירת ההערה נכשלה: $e');
  }
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
