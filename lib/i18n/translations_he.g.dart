///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsHe = Translations; // ignore: unused_element
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.he,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <he>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	// Translations
	String get language => 'עברית';
	late final TranslationsAppHe app = TranslationsAppHe._(_root);
	late final TranslationsCommonHe common = TranslationsCommonHe._(_root);
	late final TranslationsSearchHe search = TranslationsSearchHe._(_root);
	late final TranslationsLibraryHe library = TranslationsLibraryHe._(_root);
	late final TranslationsNavigationHe navigation = TranslationsNavigationHe._(_root);
	late final TranslationsReadingHe reading = TranslationsReadingHe._(_root);
	late final TranslationsTabsHe tabs = TranslationsTabsHe._(_root);
	late final TranslationsBookmarksHe bookmarks = TranslationsBookmarksHe._(_root);
	late final TranslationsHistoryHe history = TranslationsHistoryHe._(_root);
	late final TranslationsNotesHe notes = TranslationsNotesHe._(_root);
	late final TranslationsMoreHe more = TranslationsMoreHe._(_root);
	late final TranslationsSettingsHe settings = TranslationsSettingsHe._(_root);
	late final TranslationsCalendarHe calendar = TranslationsCalendarHe._(_root);
	late final TranslationsGematriaHe gematria = TranslationsGematriaHe._(_root);
	late final TranslationsTooltipsHe tooltips = TranslationsTooltipsHe._(_root);
	late final TranslationsTextBookHe textBook = TranslationsTextBookHe._(_root);
	late final TranslationsDialogsHe dialogs = TranslationsDialogsHe._(_root);
	late final TranslationsShortcutsHe shortcuts = TranslationsShortcutsHe._(_root);
	late final TranslationsAboutHe about = TranslationsAboutHe._(_root);
	late final TranslationsEmptyLibraryHe emptyLibrary = TranslationsEmptyLibraryHe._(_root);
	late final TranslationsFindRefHe findRef = TranslationsFindRefHe._(_root);
	late final TranslationsPrintingHe printing = TranslationsPrintingHe._(_root);
	late final TranslationsUpdateHe update = TranslationsUpdateHe._(_root);
	late final TranslationsReportHe report = TranslationsReportHe._(_root);
	late final TranslationsEditorHe editor = TranslationsEditorHe._(_root);
	late final TranslationsMessagesHe messages = TranslationsMessagesHe._(_root);
	late final TranslationsPasswordHe password = TranslationsPasswordHe._(_root);
	late final TranslationsPdfBookHe pdfBook = TranslationsPdfBookHe._(_root);
	late final TranslationsLinksHe links = TranslationsLinksHe._(_root);
	late final TranslationsPreviewHe preview = TranslationsPreviewHe._(_root);
}

// Path: app
class TranslationsAppHe {
	TranslationsAppHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'אוצריא';
}

// Path: common
class TranslationsCommonHe {
	TranslationsCommonHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noResults => 'לא נמצאו תוצאות';
	String get error => 'שגיאה';
	String get noLibraryData => 'אין נתוני ספרייה זמינים';
	String get loadingLibrary => 'טוען ספרייה';
	String get empty => 'ריק';
	String get close => 'סגור';
	String get delete => 'מחק';
	String get refresh => 'רענן';
	String get save => 'שמור';
	String get cancel => 'ביטול';
	String get confirm => 'אישור';
	String get ok => 'אישור';
	String get yes => 'כן';
	String get no => 'לא';
	String get unknown => 'לא ידוע';
	String get search => 'חיפוש';
}

// Path: search
class TranslationsSearchHe {
	TranslationsSearchHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get placeholder => 'חפש כאן..';
	String get clear => 'נקה';
	String get tryDifferent => 'נסה מילות חיפוש אחרות';
	String resultsCount({required Object count}) => 'נמצאו ${count} תוצאות';
	String get pleaseEnterText => 'נא להזין טקסט לחיפוש';
	String get byRelevance => 'לפי רלוונטיות';
	String get byCatalogue => 'לפי סדר קטלוגי';
	String get searchBook => 'חפש ספר...';
	String get gematriaPlaceholder => 'חפש גימטריה...';
	String get gematriaLabel => 'לחיפוש, הכנס אותיות או מספר של ערך החיפוש';
	String get enterValue => 'הזן ערך לחיפוש גימטריה';
	String get searchError => 'שגיאה בחיפוש';
	String limitedResults({required Object count}) => 'הוגבל ל-${count} תוצאות';
	String gematriaValue({required Object value}) => 'ערך גימטריה: ${value}';
	String get buildError => 'שגיאה בבניית תוצאות חיפוש';
	String get pdfPlaceholder => 'חפש ב-PDF...';
	String get pdfNoResults => 'לא נמצאו תוצאות ב-PDF';
	String get librarySearch => 'חיפוש בספרייה';
	String get loading => 'טוען...';
	String get noSearchQuery => 'אין מילות חיפוש';
	String get noSearchPerformed => 'לא בוצע חיפוש';
	String get startNewSearch => 'לחץ על \'חיפוש חדש\' כדי להתחיל';
	String get startNewSearchWide => 'לחץ על כפתור \'חיפוש\' בתפריט כדי להתחיל';
	String get noResultsShort => 'אין תוצאות';
	String get showingResultsFor => 'מוצגות תוצאות של חיפוש: ';
	String get showHideTree => 'הצג/הסתר עץ ספרים';
	String get indexUpdating => 'אינדקס החיפוש בתהליך עדכון. יתכן שחלק מהספרים לא יוצגו בתוצאות החיפוש.';
	String page({required Object page}) => 'עמוד ${page}';
	String get bookListForSearch => 'רשימת הספרים לחיפוש:';
	String get noBooksFound => 'לא נמצאו ספרים';
}

// Path: library
class TranslationsLibraryHe {
	TranslationsLibraryHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noItems => 'אין פריטים';
	String get noResultsFor => 'לא נמצאו תוצאות עבור';
	String get searchHint => 'חפש ב';
	String get listView => 'תצוגת רשימה';
	String get gridView => 'תצוגת רשת';
	String get showPreview => 'הצג תצוגה מקדימה';
	String get switchWorkspace => 'החלף שולחן עבודה';
	String get openLocally => 'פתח מקומית';
	String get openInWebsite => 'פתח באתר';
	String error({required Object message}) => 'שגיאה: ${message}';
	late final TranslationsLibraryCategoriesHe categories = TranslationsLibraryCategoriesHe._(_root);
}

// Path: navigation
class TranslationsNavigationHe {
	TranslationsNavigationHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get library => 'ספרייה';
	String get find => 'מצא מראה מקום';
	String get reading => 'עיון';
	String get search => 'חיפוש';
	String get settings => 'הגדרות';
	String get tools => 'כלים';
	String get newSearch => 'חיפוש חדש';
	String get more => 'עוד';
	String get about => 'אודות';
}

// Path: reading
class TranslationsReadingHe {
	TranslationsReadingHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get showHistoryTooltip => 'הצג היסטוריה ({shortcut})';
	String get showBookmarksTooltip => 'הצג סימניות ({shortcut})';
	String get switchWorkspaceTooltip => 'החלף שולחן עבודה ({shortcut})';
}

// Path: tabs
class TranslationsTabsHe {
	TranslationsTabsHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get closeOthers => 'סגור טאבים אחרים';
	String get clone => 'שכפל טאב';
	String get tabList => 'רשימת טאבים';
	String get alreadyPinned => 'כבר נשמר למסך הבית';
	String get pinnedToHome => 'נשמר למסך הבית';
}

// Path: bookmarks
class TranslationsBookmarksHe {
	TranslationsBookmarksHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'סימניות';
	String get searchHint => 'חפש סימניה...';
	String get empty => 'אין סימניות';
	String get notFound => 'לא נמצאו סימניות';
	String get clearAll => 'נקה הכל';
	String get addBookmark => 'הוסף סימניה';
	String get bookmarkDeleted => 'הסימניה נמחקה';
	String get allBookmarksDeleted => 'כל הסימניות נמחקו';
}

// Path: history
class TranslationsHistoryHe {
	TranslationsHistoryHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'היסטוריה';
	String get searchHint => 'חפש בהיסטוריה...';
	String get empty => 'אין היסטוריה';
	String get notFound => 'לא נמצאו פריטים בהיסטוריה';
	String get clearAll => 'נקה הכל';
	String get deleted => 'נמחק מההיסטוריה';
	String get allDeleted => 'כל ההיסטוריה נמחקה';
}

// Path: notes
class TranslationsNotesHe {
	TranslationsNotesHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'הערות';
	String get noNotesYet => 'אין הערות עדיין';
	String get noPersonalNotes => 'לא נמצאו הערות אישיות.';
	String get tryAgain => 'נסה שוב';
	String get missingLocationNotes => 'הערות ללא מיקום';
	String get editNote => 'ערוך הערה';
	String get deleteNote => 'מחק הערה';
	String get deleteNoteConfirm => 'האם אתה בטוח שברצונך למחוק הערה זו?';
	String get restoreNoteLocation => 'שחזר מיקום הערה';
	String get lastKnownLocation => 'מיקום אחרון ידוע';
	String get line => 'שורה';
	String get newLine => 'שורה חדשה';
	String get enterLineNumber => 'הכנס מספר שורה';
	String get noteWithoutLocation => 'הערה ללא מיקום';
	String get previousLine => 'שורה קודמת';
	String get reposition => 'מקם מחדש';
	String get edit => 'ערוך';
	String get addNote => 'הוסף הערה';
	String get addNoteToSection => 'הוסף הערה למקטע';
	String get newNote => 'הערה חדשה';
	String get writeNoteHere => 'כתוב הערה כאן...';
	String get emptyNoteNotSaved => 'הערה ריקה לא נשמרה';
	String get noteUpdated => 'ההערה עודכנה בהצלחה';
	String get noteDeleted => 'ההערה נמחקה בהצלחה';
	String get repositionNote => 'מקם הערה מחדש';
	String get newLineNumber => 'מספר שורה חדש';
}

// Path: more
class TranslationsMoreHe {
	TranslationsMoreHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get personalNotes => 'הערות אישיות';
	String get personalNotesShort => 'הערות';
	String get calendar => 'לוח שנה';
	String get shamorZachor => 'זכור ושמור';
	String get measurements => 'המרת מידות';
	String get measurementsShort => 'מידות';
	String get gematria => 'גימטריה';
}

// Path: settings
class TranslationsSettingsHe {
	TranslationsSettingsHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get appearance => 'מראה';
	String get fullscreen => 'מסך מלא';
	String get exitFullscreen => 'צא ממסך מלא';
	String get toggleFullscreen => 'החלף למסך מלא';
	String get nikudAndTeamim => 'הסרת ניקוד וטעמים';
	String get sidebarBehavior => 'התנהגות סרגל צד';
	String get darkMode => 'מצב כהה';
	String get enabled => 'מופעל';
	String get disabled => 'מבוטל';
	String get baseColor => 'צבע בסיס';
	String get shortcuts => 'קיצורי מקלדת';
	String get resetShortcuts => 'אפס קיצורי מקלדת';
	String get resetShortcutsSubtitle => 'החזר את קיצורי המקלדת לברירת המחדל';
	String get resetShortcutsTitle => 'אפס קיצורי מקלדת?';
	String get resetShortcutsContent => 'האם אתה בטוח שברצונך לאפס את כל קיצורי המקלדת לברירת המחדל?';
	String get shortcutsReset => 'קיצורי המקלדת אופסו בהצלחה';
	String get generalNavigation => 'ניווט כללי';
	String get newSearchWindow => 'חלון חיפוש חדש';
	String get switchWorkspace => 'החלף שולחן עבודה';
	String get bookView => 'תצוגת ספר';
	String get searchInBook => 'חפש בספר';
	String get editSection => 'ערוך קטע';
	String get print => 'הדפס';
	String get addBookmark => 'הוסף סימניה';
	String get addNote => 'הוסף הערה';
	String get closeCurrentBook => 'סגור ספר נוכחי';
	String get closeAllBooks => 'סגור את כל הספרים';
	String get interface => 'ממשק';
	String get hideHolyNames => 'הסתר שמות קדושים';
	String get hideHolyNamesEnabled => 'שמות קדושים מוסתרים';
	String get hideHolyNamesDisabled => 'שמות קדושים מוצגים';
	String get libraryScreenSettings => 'הגדרות מסך ספרייה';
	String get bookDisplaySettings => 'הגדרות תצוגת ספר';
	String get calendarSettings => 'הגדרות לוח שנה';
	String get gematriaSettings => 'הגדרות גימטריה';
	String get backup => 'גיבוי';
	String get backupWhat => 'מה לגבות:';
	String get title => 'הגדרות';
	String get backupSettingsSubtitle => 'גבה את הגדרות התוכנה';
	String get backupBookmarks => 'סימניות';
	String get backupBookmarksSubtitle => 'גבה את הסימניות';
	String get backupHistory => 'היסטוריה';
	String get backupHistorySubtitle => 'גבה את ההיסטוריה';
	String get backupNotes => 'הערות אישיות';
	String get backupNotesSubtitle => 'גבה את ההערות האישיות';
	String get backupWorkspaces => 'שולחנות עבודה';
	String get backupWorkspacesSubtitle => 'גבה את שולחנות העבודה';
	String get backupShamorZachor => 'זכור ושמור';
	String get backupShamorZachorSubtitle => 'גבה את נתוני זכור ושמור';
	String get none => 'ללא';
	String get weekly => 'שבועי';
	String get monthly => 'חודשי';
	String get createBackupNow => 'צור גיבוי עכשיו';
	String get createBackupSubtitle => 'צור קובץ גיבוי ידני';
	String get backupSaved => 'הגיבוי נשמר בהצלחה';
	String get backupPath => 'נתיב הגיבוי';
	String get backupSize => 'גודל הגיבוי';
	String get openFolder => 'פתח תיקייה';
	String get backupFileNotCreated => 'קובץ הגיבוי לא נוצר';
	String get backupError => 'שגיאה ביצירת גיבוי';
	String get restoreFromBackup => 'שחזר מגיבוי';
	String get restoreFromBackupSubtitle => 'שחזר נתונים מקובץ גיבוי';
	String get selectBackupFile => 'בחר קובץ גיבוי';
	String get restoreBackupTitle => 'שחזר גיבוי?';
	String get restoreBackupContent => 'פעולה זו תשחזר את הנתונים מהגיבוי ותדרוס את הנתונים הקיימים. האם להמשיך?';
	String get restoreCompleted => 'השחזור הושלם';
	String get restoreCompletedContent => 'יש להפעיל מחדש את האפליקציה';
	String get restoreError => 'שגיאה בשחזור גיבוי';
	String get general => 'כללי';
	String get autoSyncLibrary => 'סנכרון אוטומטי של הספרייה';
	String get autoSyncEnabled => 'הספרייה תסונכרן אוטומטית';
	String get autoSyncDisabled => 'סנכרון ידני בלבד';
	String get fastSearch => 'חיפוש מהיר';
	String get fastSearchEnabled => 'חיפוש מהיר מופעל';
	String get fastSearchDisabled => 'חיפוש רגיל';
	String get searchIndex => 'אינדקס חיפוש';
	String get indexUpdating => 'מעדכן אינדקס...';
	String get indexUpdated => 'האינדקס עודכן';
	String get stopIndexing => 'עצור אינדוקס?';
	String get stopIndexingContent => 'האם לעצור את עדכון האינדקס?';
	String get resetIndex => 'אפס אינדקס?';
	String get resetIndexContent => 'האם לאפס את כל אינדקס החיפוש?';
	String get autoUpdateIndex => 'עדכון אוטומטי של אינדקס החיפוש';
	String get autoUpdateIndexEnabled => 'האינדקס יעודכן אוטומטית';
	String get autoUpdateIndexDisabled => 'עדכון ידני בלבד';
	String get libraryLocation => 'מיקום הספרייה';
	String get backupLocation => 'מיקום גיבוי';
	String get createBackup => 'צור גיבוי';
	String get restoreBackup => 'שחזר גיבוי';
	String get autoBackup => 'גיבוי אוטומטי';
	String get notExists => 'לא קיים';
	String get hebrewBooksLocation => 'מיקום ספרים עבריים';
	String get hebrewBooksTooltip => 'מיקום הספרייה של HebrewBooks.org';
	String get devChannel => 'ערוץ פיתוח';
	String get devChannelEnabled => 'מופעל (קבל עדכונים ניסיוניים)';
	String get devChannelDisabled => 'מבוטל';
	String get resetSettings => 'אפס הגדרות';
	String get resetSettingsSubtitle => 'החזר את כל ההגדרות לברירת המחדל';
	String get resetSettingsTitle => 'אפס הגדרות?';
	String get resetSettingsContent => 'האם אתה בטוח שברצונך לאפס את כל ההגדרות?';
	String get settingsReset => 'ההגדרות אופסו';
	String get settingsResetContent => 'יש להפעיל מחדש את האפליקציה כדי שהשינויים ייכנסו לתוקף';
	String get closeApp => 'סגור אפליקציה';
	String get textMargins => 'רוחב השוליים בצידי הטקסט';
	String get showTeamim => 'הצגת טעמי המקרא';
	String get showTeamimEnabled => 'טעמים מוצגים';
	String get showTeamimDisabled => 'טעמים מוסתרים';
	String get defaultRemoveNikud => 'הסרת ניקוד כברירת מחדל';
	String get defaultRemoveNikudEnabled => 'ניקוד מוסר כברירת מחדל';
	String get defaultRemoveNikudDisabled => 'ניקוד מוצג כברירת מחדל';
	String get removeNikudFromTanach => 'הסרת ניקוד מספרי התנ"ך';
	String get removeNikudFromTanachSubtitle => 'גם ספרי התנ"ך יוצגו ללא ניקוד';
	String get pinSidebar => 'הצמדת סרגל צד';
	String get pinSidebarEnabled => 'סרגל צד מוצמד';
	String get pinSidebarDisabled => 'סרגל צד לא מוצמד';
	String get defaultSidebarOpen => 'פתיחת סרגל צד כברירת מחדל';
	String get defaultSidebarOpenEnabled => 'סרגל צד נפתח כברירת מחדל';
	String get defaultSidebarOpenDisabled => 'סרגל צד סגור כברירת מחדל';
	String get defaultShowCommentators => 'ברירת המחדל להצגת המפרשים';
	String get defaultShowCommentatorsEnabled => 'מפרשים מוצגים כברירת מחדל';
	String get defaultShowCommentatorsDisabled => 'מפרשים מוסתרים כברירת מחדל';
	String get readingSettingsTitle => 'הגדרות תצוגת הספרים';
	String get fontAndStyleSettings => 'הגדרות גופן ועיצוב';
	String get initialFontSize => 'גודל גופן התחלתי';
	String get textFont => 'גופן טקסט';
	String get commentatorFont => 'גופן מפרשים';
	String get copySettings => 'הגדרות העתקה';
	String get copyWithHeaders => 'העתקה עם כותרות';
	String get bookNameOnly => 'שם הספר בלבד';
	String get bookNameAndPath => 'שם הספר+נתיב';
	String get copyFormatting => 'עיצוב העתקה';
	String get sameLineAfterBrackets => 'אותה שורה אחרי (עם סוגריים)';
	String get sameLineAfterNoBrackets => 'אותה שורה אחרי (בלי סוגריים)';
	String get sameLineBeforeBrackets => 'אותה שורה לפני (עם סוגריים)';
	String get sameLineBeforeNoBrackets => 'אותה שורה לפני (בלי סוגריים)';
	String get separateLineAfter => 'פסקה נפרדת אחרי';
	String get separateLineBefore => 'פסקה נפרדת לפני';
	String get textEditorSettings => 'הגדרות עורך טקסטים';
	String get delayInMilliseconds => 'זמן עיכוב במילישניות';
	String get cleanOldDrafts => 'ניקוי טיוטות ישנות (ימים)';
	String get draftQuota => 'מכסת טיוטות (MB)';
}

// Path: calendar
class TranslationsCalendarHe {
	TranslationsCalendarHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'הגדרות לוח שנה';
	String get calendarType => 'סוג לוח:';
	String get hebrew => 'לוח עברי';
	String get gregorian => 'לוח לועזי';
	String get combined => 'לוח משולב';
	String get city => 'עיר:';
	String get searchCity => 'הקלד שם עיר...';
	String get noCitiesFound => 'לא נמצאו ערים';
	String get today => 'היום';
	String get goToDate => 'עבור לתאריך';
	String get jumpToDate => 'קפוץ לתאריך';
	String get cancel => 'ביטול';
	String get jump => 'קפוץ';
	String get recurringEvent => 'אירוע חוזר';
	String get repeatForever => 'חזרה ללא הגבלה (תמיד)';
	String get noMatchingEvents => 'לא נמצאו אירועים מתאימים';
	String get noEventsInSystem => 'אין אירועים במערכת';
	String get noEventsToday => 'אין אירועים ביום זה';
	String get timesOfDay => 'זמני היום';
	String get events => 'אירועים';
	String get createEvent => 'צור אירוע';
}

// Path: gematria
class TranslationsGematriaHe {
	TranslationsGematriaHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get settingsTitle => 'הגדרות חיפוש גימטריה';
	String get filterDuplicates => 'סינון תוצאות כפולות';
	String get wholeVerseOnly => 'חיפוש פסוק שלם בלבד';
	String get torahOnly => 'חיפוש בתורה בלבד';
	String get maxResults => 'מספר תוצאות מקסימלי';
	String get gematriaMethod => 'שיטת חישוב גימטריה:';
	String get regularGematria => 'גימטריה רגילה';
	String get smallGematria => 'גימטריה קטנה';
	String get finalLetters => 'אותיות סופיות שונות';
	String get withKolel => 'עם הכולל';
}

// Path: tooltips
class TranslationsTooltipsHe {
	TranslationsTooltipsHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get backToPreviousFolder => 'חזור לתיקיה קודמת';
	String get backToMainFolder => 'חזור לתיקיה ראשית';
	String get sync => 'סנכרון';
	String get reload => 'טעינה מחדש';
	String get settings => 'הגדרות';
}

// Path: textBook
class TranslationsTextBookHe {
	TranslationsTextBookHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get selectParagraph => 'בחר פסקה';
	String get copyText => 'העתק טקסט';
	String get copyWithNikud => 'העתק עם ניקוד';
	String get copyWithoutNikud => 'העתק בלי ניקוד';
	String get textCopied => 'טקסט הועתק';
	String get editText => 'ערוך טקסט';
	String get addComment => 'הוסף הערה';
	String get noCommentators => 'אין מפרשים';
	String get noCommentatorsToShow => 'לא נמצאו מפרשים להצגה';
	String errorLoadingCommentator({required Object error}) => 'שגיאה בטעינת הפרשן: ${error}';
	String get showAllCommentators => 'הצג את כל המפרשים';
	String get showAllWrittenTorah => 'הצג את כל התורה שבכתב';
	String get showAllChazal => 'הצג את כל חז"ל';
	String get showAllRishonim => 'הצג את כל הראשונים';
	String get showAllAcharonim => 'הצג את כל האחרונים';
	String get showAllModern => 'הצג את כל מחברי זמננו';
	String get showAllOthers => 'הצג את כל שאר המפרשים';
}

// Path: dialogs
class TranslationsDialogsHe {
	TranslationsDialogsHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get confirm => 'אישור';
	String get confirmAction => 'אישור פעולה';
	String get areYouSure => 'האם אתה בטוח?';
	String get cannotBeUndone => 'פעולה זו לא ניתנת לביטול';
}

// Path: shortcuts
class TranslationsShortcutsHe {
	TranslationsShortcutsHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get customShortcutTitle => 'הגדרת קיצור מקשים מותאם אישית';
	String get pressKeysInstructions => 'לחץ על "התחל הקלטה" ואז לחץ על צירוף המקשים הרצוי';
	String get pressKeys => 'לחץ על המקשים...';
	String get startRecording => 'התחל הקלטה';
	String get stopRecording => 'עצור הקלטה';
}

// Path: about
class TranslationsAboutHe {
	TranslationsAboutHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get appName => 'אוצריא';
	String get subtitle => 'מאגר תורני חינמי';
	String get description => 'מאגר תורני רחב עם ממשק מודרני ומהיר, לשימוש במחשב אישי או במכשיר הנייד, ללימוד תורה בקלות ובנוחות בכל מקום.';
	String get donors => 'תורמים';
	String get developers => 'מפתחים';
	String get technicalDetails => 'פרטים טכניים';
	String get joinDevelopment => 'הצטרף לפיתוח!';
	String get joinDevelopmentDesc => 'מפתחים מוזמנים להצטרף לפיתוח אוצריא ולתרום לקהילה התורנית.';
	String get joinNow => 'הצטרף עכשיו';
	String get joinEditing => 'הצטרף לצוות העריכה';
	String get joinEditingDesc => 'עזור לנו להוסיף ספרים חדשים לספריית אוצריא ולהרחיב את המאגר התורני.';
	String get joinEditingButton => 'הצטרף לעריכה';
	String get appVersion => 'גרסת תוכנה';
	String get libraryVersion => 'גרסת ספרייה';
	String get bookCount => 'מספר ספרים';
	String get unknown => 'לא ידוע';
	String get changelog => 'יומן שינויים';
	String get creator => 'יוצר התוכנה';
	String get developedShamorZachor => 'פיתוח "זכור ושמור"';
	String get developedGematria => 'פיתוח הגימטריות';
	String get memorialCandle => 'לע"נ ר\' משה בן יהודה ראה ז"ל';
	String get significantContribution => 'סכום משמעותי לפיתוח התוכנה';
	String get memorialSpot => 'מקום זה יכול להיות מונצח לע"נ יקירך';
	String get clickHere => 'לחץ כאן';
	String get donate => 'תרום לפרויקט';
	String get donateDesc => 'תרומתך תעזור לנו להמשיך לפתח ולשפר את אוצריא עבור כלל הציבור.';
	String get nedarimPlus => 'נדרים+';
	String get other => 'אחר';
	String get otzariaSiteNotFound => 'לא נמצאה תיקיית otzaria-site';
	String fileNotFound({required Object file}) => 'הקובץ ${file} לא נמצא';
}

// Path: emptyLibrary
class TranslationsEmptyLibraryHe {
	TranslationsEmptyLibraryHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get noLibraryFound => 'לא נמצאה ספרייה';
	String get or => 'או';
	String get chooseFolder => 'בחר תיקייה';
	String get chooseZip => 'בחר קובץ ZIP מהמכשיר';
	String get downloadLibrary => 'הורד את הספרייה מהאינטרנט (1.2GB)';
	String downloadSpeed({required Object speed}) => 'מהירות הורדה: ${speed} MB/s';
}

// Path: findRef
class TranslationsFindRefHe {
	TranslationsFindRefHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'מצא מראה מקום';
}

// Path: printing
class TranslationsPrintingHe {
	TranslationsPrintingHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'הדפסה';
	String get printRange => 'טווח הדפסה';
	String get fontSize => 'גודל גופן';
	String get margins => 'שוליים';
	String get font => 'גופן';
	String get layout => 'פריסה';
}

// Path: update
class TranslationsUpdateHe {
	TranslationsUpdateHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get available => 'עדכון זמין';
	String updateToVersion({required Object version}) => 'עדכון לגרסה ${version}';
	String get pleaseWait => 'אנא המתן...';
	String get downloading => 'מוריד...';
	String get clickToInstall => 'לחץ להתקנה';
	String get readyToInstall => 'מוכן להתקנה';
	String get updateError => 'אירעה שגיאה בעדכון. אנא נסה שוב.';
	String get errorTryAgain => 'שגיאה. נסה שוב.';
	String get downloadingUpdate => 'מוריד עדכון...';
	String downloadingVersion({required Object version}) => 'מוריד גרסה ${version}';
	String get updateReady => 'עדכון מוכן';
	String versionReadyToInstall({required Object version}) => 'גרסה ${version} מוכנה להתקנה!';
	String currentlyUsingVersion({required Object appVersion}) => 'אתה משתמש כרגע בגרסה ${appVersion}.';
	String get updateNowForFeatures => 'עדכן כעת כדי לקבל את התכונות והתיקונים החדשים.';
	String get later => 'מאוחר יותר';
	String get installNow => 'התקן כעת';
	String get newVersionAvailable => 'גרסה חדשה של האפליקציה זמינה.';
	String newVersion({required Object version}) => 'גרסה חדשה: ${version}';
	String get changelog => 'יומן שינויים:';
	String get updateNow => 'עדכן כעת';
}

// Path: report
class TranslationsReportHe {
	TranslationsReportHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get errorReportTitle => 'דיווח על שגיאה';
	String get selectedText => 'טקסט נבחר:';
	String get errorDetails => 'פירוט הטעות:';
	String get saveForLater => 'שמור לאחר כך';
	String get openEmail => 'פתח במייל';
	String get selectTextWithError => 'בחר טקסט עם שגיאה:';
	String get writeErrorDetails => 'פרט את הטעות...';
	String get loadingReportData => 'טוען נתונים לדיווח...';
	String get cannotLoadReportData => 'לא ניתן לטעון נתונים לדיווח';
	String get phoneField => 'טלפון';
	String get emailField => 'אימייל';
	String get commentsField => 'הערות';
	String get bookDetails => 'פרטי הספר';
	String get lineNumber => 'מספר שורה';
	String get context => 'הקשר';
	String get cannotOpenEmail => 'לא ניתן לפתוח אימייל';
	String get saveFailed => 'השמירה נכשלה';
	String get sendError => 'שגיאה בשליחה';
	String get reportSentSuccessfully => 'הדיווח נשלח בהצלחה';
	String get reportSentMessage => 'תודה על הדיווח!';
	String get openAnotherReport => 'פתח דיווח נוסף';
	String get sendEmail => 'שלח במייל';
	String get mustSelectText => 'יש לבחור טקסט';
	String get mustSelectErrorType => 'יש לבחור סוג שגיאה';
	String get cannotFindBook => 'לא ניתן למצוא את הספר';
	String get cannotReadLibraryVersion => 'לא ניתן לקרוא גרסת ספרייה';
	String get phoneReportInstructions => 'הוראות דיווח טלפוני';
	String get phoneReportSteps => 'שלבי הדיווח';
	String get selectErrorType => 'בחר סוג שגיאה';
	String get selectErrorTypeHint => 'בחר את סוג השגיאה';
	String get mustFixErrors => 'יש לתקן שגיאות';
	String reportSavedToFile({required Object fileName}) => 'הדיווח נשמר בהצלחה לקובץ \'${fileName}\', הנמצא בתיקייה הראשית של אוצריא.';
	String youHaveReports({required Object count}) => 'יש לך כבר ${count} דיווחים!';
	String canSendToEmail({required Object email}) => 'כעת תוכל לשלוח את הקובץ למייל: ${email}';
	String get send => 'שלח';
	String get reportNotAvailable => 'דיווח לא זמין';
	String get sendReport => 'שלח דיווח';
}

// Path: editor
class TranslationsEditorHe {
	TranslationsEditorHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'עריכת טקסט';
	String get save => 'שמור';
	String get cancel => 'ביטול';
	String get editingConflict => 'קונפליקט בעריכה';
	String get baseVersion => 'גרסת בסיס';
	String get yourVersion => 'הגרסה שלך';
	String get serverVersion => 'גרסת השרת';
	String get chooseVersion => 'בחר גרסה';
	String get useYourVersion => 'השתמש בגרסה שלך';
	String get useServerVersion => 'השתמש בגרסת השרת';
	String get mergeManually => 'מזג ידנית';
	String get searchInSection => 'חפש בקטע...';
	String get saving => 'שומר...';
	String get saveSuccess => 'השמירה הצליחה';
	String get saveError => 'שגיאה בשמירה';
	String get discardChanges => 'בטל שינויים';
	String get discardChangesConfirm => 'האם לבטל את השינויים?';
	String get saveAndExit => 'שמור וצא';
	String get searchInText => 'חפש בטקסט';
	String get enterTextToSearch => 'הכנס טקסט לחיפוש';
	String get whatToSearch => 'מה לחפש';
	String get searchHint => 'חפש...';
	String get addLink => 'הוסף קישור';
	String get linkText => 'טקסט הקישור';
	String get clickHere => 'לחץ כאן';
	String get urlAddress => 'כתובת URL';
	String get add => 'הוסף';
	String get conflictInEditing => 'קונפליקט בעריכה';
	String get conflictMessage => 'נוצר קונפליקט בעריכה';
	String get keepMyEdit => 'שמור את העריכה שלי';
	String get ignoreSourceChanges => 'התעלם משינויים במקור';
	String get useNewVersion => 'השתמש בגרסה החדשה';
	String get cancelMyEdit => 'בטל את העריכה שלי';
	String get saveSeparately => 'שמור בנפרד';
	String get saveAsSeparateVersion => 'שמור כגרסה נפרדת';
	String get resolveConflict => 'פתור קונפליקט';
	String diffTitle({required Object title}) => 'השוואה - ${title}';
	String get original => 'מקור';
	String get edited => 'נערך';
}

// Path: messages
class TranslationsMessagesHe {
	TranslationsMessagesHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get editingInProgress => 'עריכה בתהליך';
	String get saveBeforeLeaving => 'שמור לפני יציאה';
	String get checkingConflicts => 'בודק קונפליקטים...';
	String get savedSuccessfully => 'נשמר בהצלחה';
	String get formattedCopyError => 'שגיאה בהעתקה מעוצבת';
	String get cannotAccessClipboard => 'לא ניתן לגשת ללוח';
	String get formattedTextCopied => 'טקסט מעוצב הועתק';
	String get copyError => 'שגיאה בהעתקה';
	String get sectionNotFound => 'המקטע לא נמצא';
	String get bookNotFound => 'הספר לא נמצא';
}

// Path: password
class TranslationsPasswordHe {
	TranslationsPasswordHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'הזן סיסמה';
	String get enterPassword => 'הכנס סיסמה';
}

// Path: pdfBook
class TranslationsPdfBookHe {
	TranslationsPdfBookHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get navigateToUrl => 'לעבור לURL?';
	String get cancel => 'ביטול';
	String get go => 'עבור';
	String get noOutline => 'אין תוכן עניינים';
}

// Path: links
class TranslationsLinksHe {
	TranslationsLinksHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get searchInLinks => 'חפש גם בתוכן הקישורים';
	String opened({required Object ref}) => 'נפתח: ${ref}';
	String cannotOpenLink({required Object error}) => 'לא ניתן לפתוח את הקישור: ${error}';
	String linkError({required Object error}) => 'שגיאה בפתיחת הקישור: ${error}';
	String navigateTo({required Object headerName}) => 'נווט ל: ${headerName}';
	String cannotNavigateToHeader({required Object headerName}) => 'לא ניתן לנווט לכותרת: ${headerName}';
	String openBook({required Object bookTitle, required Object headerName}) => 'פתח ספר: ${bookTitle} - ${headerName}';
	String cannotOpenBook({required Object bookTitle}) => 'לא ניתן לפתוח את הספר: ${bookTitle}';
}

// Path: preview
class TranslationsPreviewHe {
	TranslationsPreviewHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get openInReader => 'פתח בעיון';
}

// Path: library.categories
class TranslationsLibraryCategoriesHe {
	TranslationsLibraryCategoriesHe._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get tanach => 'תנ"ך';
	String get midrash => 'מדרש';
	String get mishna => 'משנה';
	String get talmudBavli => 'תלמוד בבלי';
	String get talmudYerushalmi => 'תלמוד ירושלמי';
	String get halacha => 'הלכה';
	String get mishneTorah => 'משנה תורה';
	String get shulchanAruch => 'שולחן ערוך';
	String get chasidut => 'חסידות';
	String get kabbalah => 'קבלה';
	String get musar => 'מוסר';
	String get shut => 'שו"ת';
	String get rishonim => 'ראשונים';
	String get acharonim => 'אחרונים';
	String get modern => 'מודרני';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.
extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'language': return 'עברית';
			case 'app.title': return 'אוצריא';
			case 'common.noResults': return 'לא נמצאו תוצאות';
			case 'common.error': return 'שגיאה';
			case 'common.noLibraryData': return 'אין נתוני ספרייה זמינים';
			case 'common.loadingLibrary': return 'טוען ספרייה';
			case 'common.empty': return 'ריק';
			case 'common.close': return 'סגור';
			case 'common.delete': return 'מחק';
			case 'common.refresh': return 'רענן';
			case 'common.save': return 'שמור';
			case 'common.cancel': return 'ביטול';
			case 'common.confirm': return 'אישור';
			case 'common.ok': return 'אישור';
			case 'common.yes': return 'כן';
			case 'common.no': return 'לא';
			case 'common.unknown': return 'לא ידוע';
			case 'common.search': return 'חיפוש';
			case 'search.placeholder': return 'חפש כאן..';
			case 'search.clear': return 'נקה';
			case 'search.tryDifferent': return 'נסה מילות חיפוש אחרות';
			case 'search.resultsCount': return ({required Object count}) => 'נמצאו ${count} תוצאות';
			case 'search.pleaseEnterText': return 'נא להזין טקסט לחיפוש';
			case 'search.byRelevance': return 'לפי רלוונטיות';
			case 'search.byCatalogue': return 'לפי סדר קטלוגי';
			case 'search.searchBook': return 'חפש ספר...';
			case 'search.gematriaPlaceholder': return 'חפש גימטריה...';
			case 'search.gematriaLabel': return 'לחיפוש, הכנס אותיות או מספר של ערך החיפוש';
			case 'search.enterValue': return 'הזן ערך לחיפוש גימטריה';
			case 'search.searchError': return 'שגיאה בחיפוש';
			case 'search.limitedResults': return ({required Object count}) => 'הוגבל ל-${count} תוצאות';
			case 'search.gematriaValue': return ({required Object value}) => 'ערך גימטריה: ${value}';
			case 'search.buildError': return 'שגיאה בבניית תוצאות חיפוש';
			case 'search.pdfPlaceholder': return 'חפש ב-PDF...';
			case 'search.pdfNoResults': return 'לא נמצאו תוצאות ב-PDF';
			case 'search.librarySearch': return 'חיפוש בספרייה';
			case 'search.loading': return 'טוען...';
			case 'search.noSearchQuery': return 'אין מילות חיפוש';
			case 'search.noSearchPerformed': return 'לא בוצע חיפוש';
			case 'search.startNewSearch': return 'לחץ על \'חיפוש חדש\' כדי להתחיל';
			case 'search.startNewSearchWide': return 'לחץ על כפתור \'חיפוש\' בתפריט כדי להתחיל';
			case 'search.noResultsShort': return 'אין תוצאות';
			case 'search.showingResultsFor': return 'מוצגות תוצאות של חיפוש: ';
			case 'search.showHideTree': return 'הצג/הסתר עץ ספרים';
			case 'search.indexUpdating': return 'אינדקס החיפוש בתהליך עדכון. יתכן שחלק מהספרים לא יוצגו בתוצאות החיפוש.';
			case 'search.page': return ({required Object page}) => 'עמוד ${page}';
			case 'search.bookListForSearch': return 'רשימת הספרים לחיפוש:';
			case 'search.noBooksFound': return 'לא נמצאו ספרים';
			case 'library.noItems': return 'אין פריטים';
			case 'library.noResultsFor': return 'לא נמצאו תוצאות עבור';
			case 'library.searchHint': return 'חפש ב';
			case 'library.listView': return 'תצוגת רשימה';
			case 'library.gridView': return 'תצוגת רשת';
			case 'library.showPreview': return 'הצג תצוגה מקדימה';
			case 'library.switchWorkspace': return 'החלף שולחן עבודה';
			case 'library.openLocally': return 'פתח מקומית';
			case 'library.openInWebsite': return 'פתח באתר';
			case 'library.error': return ({required Object message}) => 'שגיאה: ${message}';
			case 'library.categories.tanach': return 'תנ"ך';
			case 'library.categories.midrash': return 'מדרש';
			case 'library.categories.mishna': return 'משנה';
			case 'library.categories.talmudBavli': return 'תלמוד בבלי';
			case 'library.categories.talmudYerushalmi': return 'תלמוד ירושלמי';
			case 'library.categories.halacha': return 'הלכה';
			case 'library.categories.mishneTorah': return 'משנה תורה';
			case 'library.categories.shulchanAruch': return 'שולחן ערוך';
			case 'library.categories.chasidut': return 'חסידות';
			case 'library.categories.kabbalah': return 'קבלה';
			case 'library.categories.musar': return 'מוסר';
			case 'library.categories.shut': return 'שו"ת';
			case 'library.categories.rishonim': return 'ראשונים';
			case 'library.categories.acharonim': return 'אחרונים';
			case 'library.categories.modern': return 'מודרני';
			case 'navigation.library': return 'ספרייה';
			case 'navigation.find': return 'מצא מראה מקום';
			case 'navigation.reading': return 'עיון';
			case 'navigation.search': return 'חיפוש';
			case 'navigation.settings': return 'הגדרות';
			case 'navigation.tools': return 'כלים';
			case 'navigation.newSearch': return 'חיפוש חדש';
			case 'navigation.more': return 'עוד';
			case 'navigation.about': return 'אודות';
			case 'reading.showHistoryTooltip': return 'הצג היסטוריה ({shortcut})';
			case 'reading.showBookmarksTooltip': return 'הצג סימניות ({shortcut})';
			case 'reading.switchWorkspaceTooltip': return 'החלף שולחן עבודה ({shortcut})';
			case 'tabs.closeOthers': return 'סגור טאבים אחרים';
			case 'tabs.clone': return 'שכפל טאב';
			case 'tabs.tabList': return 'רשימת טאבים';
			case 'tabs.alreadyPinned': return 'כבר נשמר למסך הבית';
			case 'tabs.pinnedToHome': return 'נשמר למסך הבית';
			case 'bookmarks.title': return 'סימניות';
			case 'bookmarks.searchHint': return 'חפש סימניה...';
			case 'bookmarks.empty': return 'אין סימניות';
			case 'bookmarks.notFound': return 'לא נמצאו סימניות';
			case 'bookmarks.clearAll': return 'נקה הכל';
			case 'bookmarks.addBookmark': return 'הוסף סימניה';
			case 'bookmarks.bookmarkDeleted': return 'הסימניה נמחקה';
			case 'bookmarks.allBookmarksDeleted': return 'כל הסימניות נמחקו';
			case 'history.title': return 'היסטוריה';
			case 'history.searchHint': return 'חפש בהיסטוריה...';
			case 'history.empty': return 'אין היסטוריה';
			case 'history.notFound': return 'לא נמצאו פריטים בהיסטוריה';
			case 'history.clearAll': return 'נקה הכל';
			case 'history.deleted': return 'נמחק מההיסטוריה';
			case 'history.allDeleted': return 'כל ההיסטוריה נמחקה';
			case 'notes.title': return 'הערות';
			case 'notes.noNotesYet': return 'אין הערות עדיין';
			case 'notes.noPersonalNotes': return 'לא נמצאו הערות אישיות.';
			case 'notes.tryAgain': return 'נסה שוב';
			case 'notes.missingLocationNotes': return 'הערות ללא מיקום';
			case 'notes.editNote': return 'ערוך הערה';
			case 'notes.deleteNote': return 'מחק הערה';
			case 'notes.deleteNoteConfirm': return 'האם אתה בטוח שברצונך למחוק הערה זו?';
			case 'notes.restoreNoteLocation': return 'שחזר מיקום הערה';
			case 'notes.lastKnownLocation': return 'מיקום אחרון ידוע';
			case 'notes.line': return 'שורה';
			case 'notes.newLine': return 'שורה חדשה';
			case 'notes.enterLineNumber': return 'הכנס מספר שורה';
			case 'notes.noteWithoutLocation': return 'הערה ללא מיקום';
			case 'notes.previousLine': return 'שורה קודמת';
			case 'notes.reposition': return 'מקם מחדש';
			case 'notes.edit': return 'ערוך';
			case 'notes.addNote': return 'הוסף הערה';
			case 'notes.addNoteToSection': return 'הוסף הערה למקטע';
			case 'notes.newNote': return 'הערה חדשה';
			case 'notes.writeNoteHere': return 'כתוב הערה כאן...';
			case 'notes.emptyNoteNotSaved': return 'הערה ריקה לא נשמרה';
			case 'notes.noteUpdated': return 'ההערה עודכנה בהצלחה';
			case 'notes.noteDeleted': return 'ההערה נמחקה בהצלחה';
			case 'notes.repositionNote': return 'מקם הערה מחדש';
			case 'notes.newLineNumber': return 'מספר שורה חדש';
			case 'more.personalNotes': return 'הערות אישיות';
			case 'more.personalNotesShort': return 'הערות';
			case 'more.calendar': return 'לוח שנה';
			case 'more.shamorZachor': return 'זכור ושמור';
			case 'more.measurements': return 'המרת מידות';
			case 'more.measurementsShort': return 'מידות';
			case 'more.gematria': return 'גימטריה';
			case 'settings.appearance': return 'מראה';
			case 'settings.fullscreen': return 'מסך מלא';
			case 'settings.exitFullscreen': return 'צא ממסך מלא';
			case 'settings.toggleFullscreen': return 'החלף למסך מלא';
			case 'settings.nikudAndTeamim': return 'הסרת ניקוד וטעמים';
			case 'settings.sidebarBehavior': return 'התנהגות סרגל צד';
			case 'settings.darkMode': return 'מצב כהה';
			case 'settings.enabled': return 'מופעל';
			case 'settings.disabled': return 'מבוטל';
			case 'settings.baseColor': return 'צבע בסיס';
			case 'settings.shortcuts': return 'קיצורי מקלדת';
			case 'settings.resetShortcuts': return 'אפס קיצורי מקלדת';
			case 'settings.resetShortcutsSubtitle': return 'החזר את קיצורי המקלדת לברירת המחדל';
			case 'settings.resetShortcutsTitle': return 'אפס קיצורי מקלדת?';
			case 'settings.resetShortcutsContent': return 'האם אתה בטוח שברצונך לאפס את כל קיצורי המקלדת לברירת המחדל?';
			case 'settings.shortcutsReset': return 'קיצורי המקלדת אופסו בהצלחה';
			case 'settings.generalNavigation': return 'ניווט כללי';
			case 'settings.newSearchWindow': return 'חלון חיפוש חדש';
			case 'settings.switchWorkspace': return 'החלף שולחן עבודה';
			case 'settings.bookView': return 'תצוגת ספר';
			case 'settings.searchInBook': return 'חפש בספר';
			case 'settings.editSection': return 'ערוך קטע';
			case 'settings.print': return 'הדפס';
			case 'settings.addBookmark': return 'הוסף סימניה';
			case 'settings.addNote': return 'הוסף הערה';
			case 'settings.closeCurrentBook': return 'סגור ספר נוכחי';
			case 'settings.closeAllBooks': return 'סגור את כל הספרים';
			case 'settings.interface': return 'ממשק';
			case 'settings.hideHolyNames': return 'הסתר שמות קדושים';
			case 'settings.hideHolyNamesEnabled': return 'שמות קדושים מוסתרים';
			case 'settings.hideHolyNamesDisabled': return 'שמות קדושים מוצגים';
			case 'settings.libraryScreenSettings': return 'הגדרות מסך ספרייה';
			case 'settings.bookDisplaySettings': return 'הגדרות תצוגת ספר';
			case 'settings.calendarSettings': return 'הגדרות לוח שנה';
			case 'settings.gematriaSettings': return 'הגדרות גימטריה';
			case 'settings.backup': return 'גיבוי';
			case 'settings.backupWhat': return 'מה לגבות:';
			case 'settings.title': return 'הגדרות';
			case 'settings.backupSettingsSubtitle': return 'גבה את הגדרות התוכנה';
			case 'settings.backupBookmarks': return 'סימניות';
			case 'settings.backupBookmarksSubtitle': return 'גבה את הסימניות';
			case 'settings.backupHistory': return 'היסטוריה';
			case 'settings.backupHistorySubtitle': return 'גבה את ההיסטוריה';
			case 'settings.backupNotes': return 'הערות אישיות';
			case 'settings.backupNotesSubtitle': return 'גבה את ההערות האישיות';
			case 'settings.backupWorkspaces': return 'שולחנות עבודה';
			case 'settings.backupWorkspacesSubtitle': return 'גבה את שולחנות העבודה';
			case 'settings.backupShamorZachor': return 'זכור ושמור';
			case 'settings.backupShamorZachorSubtitle': return 'גבה את נתוני זכור ושמור';
			case 'settings.none': return 'ללא';
			case 'settings.weekly': return 'שבועי';
			case 'settings.monthly': return 'חודשי';
			case 'settings.createBackupNow': return 'צור גיבוי עכשיו';
			case 'settings.createBackupSubtitle': return 'צור קובץ גיבוי ידני';
			case 'settings.backupSaved': return 'הגיבוי נשמר בהצלחה';
			case 'settings.backupPath': return 'נתיב הגיבוי';
			case 'settings.backupSize': return 'גודל הגיבוי';
			case 'settings.openFolder': return 'פתח תיקייה';
			case 'settings.backupFileNotCreated': return 'קובץ הגיבוי לא נוצר';
			case 'settings.backupError': return 'שגיאה ביצירת גיבוי';
			case 'settings.restoreFromBackup': return 'שחזר מגיבוי';
			case 'settings.restoreFromBackupSubtitle': return 'שחזר נתונים מקובץ גיבוי';
			case 'settings.selectBackupFile': return 'בחר קובץ גיבוי';
			case 'settings.restoreBackupTitle': return 'שחזר גיבוי?';
			case 'settings.restoreBackupContent': return 'פעולה זו תשחזר את הנתונים מהגיבוי ותדרוס את הנתונים הקיימים. האם להמשיך?';
			case 'settings.restoreCompleted': return 'השחזור הושלם';
			case 'settings.restoreCompletedContent': return 'יש להפעיל מחדש את האפליקציה';
			case 'settings.restoreError': return 'שגיאה בשחזור גיבוי';
			case 'settings.general': return 'כללי';
			case 'settings.autoSyncLibrary': return 'סנכרון אוטומטי של הספרייה';
			case 'settings.autoSyncEnabled': return 'הספרייה תסונכרן אוטומטית';
			case 'settings.autoSyncDisabled': return 'סנכרון ידני בלבד';
			case 'settings.fastSearch': return 'חיפוש מהיר';
			case 'settings.fastSearchEnabled': return 'חיפוש מהיר מופעל';
			case 'settings.fastSearchDisabled': return 'חיפוש רגיל';
			case 'settings.searchIndex': return 'אינדקס חיפוש';
			case 'settings.indexUpdating': return 'מעדכן אינדקס...';
			case 'settings.indexUpdated': return 'האינדקס עודכן';
			case 'settings.stopIndexing': return 'עצור אינדוקס?';
			case 'settings.stopIndexingContent': return 'האם לעצור את עדכון האינדקס?';
			case 'settings.resetIndex': return 'אפס אינדקס?';
			case 'settings.resetIndexContent': return 'האם לאפס את כל אינדקס החיפוש?';
			case 'settings.autoUpdateIndex': return 'עדכון אוטומטי של אינדקס החיפוש';
			case 'settings.autoUpdateIndexEnabled': return 'האינדקס יעודכן אוטומטית';
			case 'settings.autoUpdateIndexDisabled': return 'עדכון ידני בלבד';
			case 'settings.libraryLocation': return 'מיקום הספרייה';
			case 'settings.backupLocation': return 'מיקום גיבוי';
			case 'settings.createBackup': return 'צור גיבוי';
			case 'settings.restoreBackup': return 'שחזר גיבוי';
			case 'settings.autoBackup': return 'גיבוי אוטומטי';
			case 'settings.notExists': return 'לא קיים';
			case 'settings.hebrewBooksLocation': return 'מיקום ספרים עבריים';
			case 'settings.hebrewBooksTooltip': return 'מיקום הספרייה של HebrewBooks.org';
			case 'settings.devChannel': return 'ערוץ פיתוח';
			case 'settings.devChannelEnabled': return 'מופעל (קבל עדכונים ניסיוניים)';
			case 'settings.devChannelDisabled': return 'מבוטל';
			case 'settings.resetSettings': return 'אפס הגדרות';
			case 'settings.resetSettingsSubtitle': return 'החזר את כל ההגדרות לברירת המחדל';
			case 'settings.resetSettingsTitle': return 'אפס הגדרות?';
			case 'settings.resetSettingsContent': return 'האם אתה בטוח שברצונך לאפס את כל ההגדרות?';
			case 'settings.settingsReset': return 'ההגדרות אופסו';
			case 'settings.settingsResetContent': return 'יש להפעיל מחדש את האפליקציה כדי שהשינויים ייכנסו לתוקף';
			case 'settings.closeApp': return 'סגור אפליקציה';
			case 'settings.textMargins': return 'רוחב השוליים בצידי הטקסט';
			case 'settings.showTeamim': return 'הצגת טעמי המקרא';
			case 'settings.showTeamimEnabled': return 'טעמים מוצגים';
			case 'settings.showTeamimDisabled': return 'טעמים מוסתרים';
			case 'settings.defaultRemoveNikud': return 'הסרת ניקוד כברירת מחדל';
			case 'settings.defaultRemoveNikudEnabled': return 'ניקוד מוסר כברירת מחדל';
			case 'settings.defaultRemoveNikudDisabled': return 'ניקוד מוצג כברירת מחדל';
			case 'settings.removeNikudFromTanach': return 'הסרת ניקוד מספרי התנ"ך';
			case 'settings.removeNikudFromTanachSubtitle': return 'גם ספרי התנ"ך יוצגו ללא ניקוד';
			case 'settings.pinSidebar': return 'הצמדת סרגל צד';
			case 'settings.pinSidebarEnabled': return 'סרגל צד מוצמד';
			case 'settings.pinSidebarDisabled': return 'סרגל צד לא מוצמד';
			case 'settings.defaultSidebarOpen': return 'פתיחת סרגל צד כברירת מחדל';
			case 'settings.defaultSidebarOpenEnabled': return 'סרגל צד נפתח כברירת מחדל';
			case 'settings.defaultSidebarOpenDisabled': return 'סרגל צד סגור כברירת מחדל';
			case 'settings.defaultShowCommentators': return 'ברירת המחדל להצגת המפרשים';
			case 'settings.defaultShowCommentatorsEnabled': return 'מפרשים מוצגים כברירת מחדל';
			case 'settings.defaultShowCommentatorsDisabled': return 'מפרשים מוסתרים כברירת מחדל';
			case 'settings.readingSettingsTitle': return 'הגדרות תצוגת הספרים';
			case 'settings.fontAndStyleSettings': return 'הגדרות גופן ועיצוב';
			case 'settings.initialFontSize': return 'גודל גופן התחלתי';
			case 'settings.textFont': return 'גופן טקסט';
			case 'settings.commentatorFont': return 'גופן מפרשים';
			case 'settings.copySettings': return 'הגדרות העתקה';
			case 'settings.copyWithHeaders': return 'העתקה עם כותרות';
			case 'settings.bookNameOnly': return 'שם הספר בלבד';
			case 'settings.bookNameAndPath': return 'שם הספר+נתיב';
			case 'settings.copyFormatting': return 'עיצוב העתקה';
			case 'settings.sameLineAfterBrackets': return 'אותה שורה אחרי (עם סוגריים)';
			case 'settings.sameLineAfterNoBrackets': return 'אותה שורה אחרי (בלי סוגריים)';
			case 'settings.sameLineBeforeBrackets': return 'אותה שורה לפני (עם סוגריים)';
			case 'settings.sameLineBeforeNoBrackets': return 'אותה שורה לפני (בלי סוגריים)';
			case 'settings.separateLineAfter': return 'פסקה נפרדת אחרי';
			case 'settings.separateLineBefore': return 'פסקה נפרדת לפני';
			case 'settings.textEditorSettings': return 'הגדרות עורך טקסטים';
			case 'settings.delayInMilliseconds': return 'זמן עיכוב במילישניות';
			case 'settings.cleanOldDrafts': return 'ניקוי טיוטות ישנות (ימים)';
			case 'settings.draftQuota': return 'מכסת טיוטות (MB)';
			case 'calendar.title': return 'הגדרות לוח שנה';
			case 'calendar.calendarType': return 'סוג לוח:';
			case 'calendar.hebrew': return 'לוח עברי';
			case 'calendar.gregorian': return 'לוח לועזי';
			case 'calendar.combined': return 'לוח משולב';
			case 'calendar.city': return 'עיר:';
			case 'calendar.searchCity': return 'הקלד שם עיר...';
			case 'calendar.noCitiesFound': return 'לא נמצאו ערים';
			case 'calendar.today': return 'היום';
			case 'calendar.goToDate': return 'עבור לתאריך';
			case 'calendar.jumpToDate': return 'קפוץ לתאריך';
			case 'calendar.cancel': return 'ביטול';
			case 'calendar.jump': return 'קפוץ';
			case 'calendar.recurringEvent': return 'אירוע חוזר';
			case 'calendar.repeatForever': return 'חזרה ללא הגבלה (תמיד)';
			case 'calendar.noMatchingEvents': return 'לא נמצאו אירועים מתאימים';
			case 'calendar.noEventsInSystem': return 'אין אירועים במערכת';
			case 'calendar.noEventsToday': return 'אין אירועים ביום זה';
			case 'calendar.timesOfDay': return 'זמני היום';
			case 'calendar.events': return 'אירועים';
			case 'calendar.createEvent': return 'צור אירוע';
			case 'gematria.settingsTitle': return 'הגדרות חיפוש גימטריה';
			case 'gematria.filterDuplicates': return 'סינון תוצאות כפולות';
			case 'gematria.wholeVerseOnly': return 'חיפוש פסוק שלם בלבד';
			case 'gematria.torahOnly': return 'חיפוש בתורה בלבד';
			case 'gematria.maxResults': return 'מספר תוצאות מקסימלי';
			case 'gematria.gematriaMethod': return 'שיטת חישוב גימטריה:';
			case 'gematria.regularGematria': return 'גימטריה רגילה';
			case 'gematria.smallGematria': return 'גימטריה קטנה';
			case 'gematria.finalLetters': return 'אותיות סופיות שונות';
			case 'gematria.withKolel': return 'עם הכולל';
			case 'tooltips.backToPreviousFolder': return 'חזור לתיקיה קודמת';
			case 'tooltips.backToMainFolder': return 'חזור לתיקיה ראשית';
			case 'tooltips.sync': return 'סנכרון';
			case 'tooltips.reload': return 'טעינה מחדש';
			case 'tooltips.settings': return 'הגדרות';
			case 'textBook.selectParagraph': return 'בחר פסקה';
			case 'textBook.copyText': return 'העתק טקסט';
			case 'textBook.copyWithNikud': return 'העתק עם ניקוד';
			case 'textBook.copyWithoutNikud': return 'העתק בלי ניקוד';
			case 'textBook.textCopied': return 'טקסט הועתק';
			case 'textBook.editText': return 'ערוך טקסט';
			case 'textBook.addComment': return 'הוסף הערה';
			case 'textBook.noCommentators': return 'אין מפרשים';
			case 'textBook.noCommentatorsToShow': return 'לא נמצאו מפרשים להצגה';
			case 'textBook.errorLoadingCommentator': return ({required Object error}) => 'שגיאה בטעינת הפרשן: ${error}';
			case 'textBook.showAllCommentators': return 'הצג את כל המפרשים';
			case 'textBook.showAllWrittenTorah': return 'הצג את כל התורה שבכתב';
			case 'textBook.showAllChazal': return 'הצג את כל חז"ל';
			case 'textBook.showAllRishonim': return 'הצג את כל הראשונים';
			case 'textBook.showAllAcharonim': return 'הצג את כל האחרונים';
			case 'textBook.showAllModern': return 'הצג את כל מחברי זמננו';
			case 'textBook.showAllOthers': return 'הצג את כל שאר המפרשים';
			case 'dialogs.confirm': return 'אישור';
			case 'dialogs.confirmAction': return 'אישור פעולה';
			case 'dialogs.areYouSure': return 'האם אתה בטוח?';
			case 'dialogs.cannotBeUndone': return 'פעולה זו לא ניתנת לביטול';
			case 'shortcuts.customShortcutTitle': return 'הגדרת קיצור מקשים מותאם אישית';
			case 'shortcuts.pressKeysInstructions': return 'לחץ על "התחל הקלטה" ואז לחץ על צירוף המקשים הרצוי';
			case 'shortcuts.pressKeys': return 'לחץ על המקשים...';
			case 'shortcuts.startRecording': return 'התחל הקלטה';
			case 'shortcuts.stopRecording': return 'עצור הקלטה';
			case 'about.appName': return 'אוצריא';
			case 'about.subtitle': return 'מאגר תורני חינמי';
			case 'about.description': return 'מאגר תורני רחב עם ממשק מודרני ומהיר, לשימוש במחשב אישי או במכשיר הנייד, ללימוד תורה בקלות ובנוחות בכל מקום.';
			case 'about.donors': return 'תורמים';
			case 'about.developers': return 'מפתחים';
			case 'about.technicalDetails': return 'פרטים טכניים';
			case 'about.joinDevelopment': return 'הצטרף לפיתוח!';
			case 'about.joinDevelopmentDesc': return 'מפתחים מוזמנים להצטרף לפיתוח אוצריא ולתרום לקהילה התורנית.';
			case 'about.joinNow': return 'הצטרף עכשיו';
			case 'about.joinEditing': return 'הצטרף לצוות העריכה';
			case 'about.joinEditingDesc': return 'עזור לנו להוסיף ספרים חדשים לספריית אוצריא ולהרחיב את המאגר התורני.';
			case 'about.joinEditingButton': return 'הצטרף לעריכה';
			case 'about.appVersion': return 'גרסת תוכנה';
			case 'about.libraryVersion': return 'גרסת ספרייה';
			case 'about.bookCount': return 'מספר ספרים';
			case 'about.unknown': return 'לא ידוע';
			case 'about.changelog': return 'יומן שינויים';
			case 'about.creator': return 'יוצר התוכנה';
			case 'about.developedShamorZachor': return 'פיתוח "זכור ושמור"';
			case 'about.developedGematria': return 'פיתוח הגימטריות';
			case 'about.memorialCandle': return 'לע"נ ר\' משה בן יהודה ראה ז"ל';
			case 'about.significantContribution': return 'סכום משמעותי לפיתוח התוכנה';
			case 'about.memorialSpot': return 'מקום זה יכול להיות מונצח לע"נ יקירך';
			case 'about.clickHere': return 'לחץ כאן';
			case 'about.donate': return 'תרום לפרויקט';
			case 'about.donateDesc': return 'תרומתך תעזור לנו להמשיך לפתח ולשפר את אוצריא עבור כלל הציבור.';
			case 'about.nedarimPlus': return 'נדרים+';
			case 'about.other': return 'אחר';
			case 'about.otzariaSiteNotFound': return 'לא נמצאה תיקיית otzaria-site';
			case 'about.fileNotFound': return ({required Object file}) => 'הקובץ ${file} לא נמצא';
			case 'emptyLibrary.noLibraryFound': return 'לא נמצאה ספרייה';
			case 'emptyLibrary.or': return 'או';
			case 'emptyLibrary.chooseFolder': return 'בחר תיקייה';
			case 'emptyLibrary.chooseZip': return 'בחר קובץ ZIP מהמכשיר';
			case 'emptyLibrary.downloadLibrary': return 'הורד את הספרייה מהאינטרנט (1.2GB)';
			case 'emptyLibrary.downloadSpeed': return ({required Object speed}) => 'מהירות הורדה: ${speed} MB/s';
			case 'findRef.title': return 'מצא מראה מקום';
			case 'printing.title': return 'הדפסה';
			case 'printing.printRange': return 'טווח הדפסה';
			case 'printing.fontSize': return 'גודל גופן';
			case 'printing.margins': return 'שוליים';
			case 'printing.font': return 'גופן';
			case 'printing.layout': return 'פריסה';
			case 'update.available': return 'עדכון זמין';
			case 'update.updateToVersion': return ({required Object version}) => 'עדכון לגרסה ${version}';
			case 'update.pleaseWait': return 'אנא המתן...';
			case 'update.downloading': return 'מוריד...';
			case 'update.clickToInstall': return 'לחץ להתקנה';
			case 'update.readyToInstall': return 'מוכן להתקנה';
			case 'update.updateError': return 'אירעה שגיאה בעדכון. אנא נסה שוב.';
			case 'update.errorTryAgain': return 'שגיאה. נסה שוב.';
			case 'update.downloadingUpdate': return 'מוריד עדכון...';
			case 'update.downloadingVersion': return ({required Object version}) => 'מוריד גרסה ${version}';
			case 'update.updateReady': return 'עדכון מוכן';
			case 'update.versionReadyToInstall': return ({required Object version}) => 'גרסה ${version} מוכנה להתקנה!';
			case 'update.currentlyUsingVersion': return ({required Object appVersion}) => 'אתה משתמש כרגע בגרסה ${appVersion}.';
			case 'update.updateNowForFeatures': return 'עדכן כעת כדי לקבל את התכונות והתיקונים החדשים.';
			case 'update.later': return 'מאוחר יותר';
			case 'update.installNow': return 'התקן כעת';
			case 'update.newVersionAvailable': return 'גרסה חדשה של האפליקציה זמינה.';
			case 'update.newVersion': return ({required Object version}) => 'גרסה חדשה: ${version}';
			case 'update.changelog': return 'יומן שינויים:';
			case 'update.updateNow': return 'עדכן כעת';
			case 'report.errorReportTitle': return 'דיווח על שגיאה';
			case 'report.selectedText': return 'טקסט נבחר:';
			case 'report.errorDetails': return 'פירוט הטעות:';
			case 'report.saveForLater': return 'שמור לאחר כך';
			case 'report.openEmail': return 'פתח במייל';
			case 'report.selectTextWithError': return 'בחר טקסט עם שגיאה:';
			case 'report.writeErrorDetails': return 'פרט את הטעות...';
			case 'report.loadingReportData': return 'טוען נתונים לדיווח...';
			case 'report.cannotLoadReportData': return 'לא ניתן לטעון נתונים לדיווח';
			case 'report.phoneField': return 'טלפון';
			case 'report.emailField': return 'אימייל';
			case 'report.commentsField': return 'הערות';
			case 'report.bookDetails': return 'פרטי הספר';
			case 'report.lineNumber': return 'מספר שורה';
			case 'report.context': return 'הקשר';
			case 'report.cannotOpenEmail': return 'לא ניתן לפתוח אימייל';
			case 'report.saveFailed': return 'השמירה נכשלה';
			case 'report.sendError': return 'שגיאה בשליחה';
			case 'report.reportSentSuccessfully': return 'הדיווח נשלח בהצלחה';
			case 'report.reportSentMessage': return 'תודה על הדיווח!';
			case 'report.openAnotherReport': return 'פתח דיווח נוסף';
			case 'report.sendEmail': return 'שלח במייל';
			case 'report.mustSelectText': return 'יש לבחור טקסט';
			case 'report.mustSelectErrorType': return 'יש לבחור סוג שגיאה';
			case 'report.cannotFindBook': return 'לא ניתן למצוא את הספר';
			case 'report.cannotReadLibraryVersion': return 'לא ניתן לקרוא גרסת ספרייה';
			case 'report.phoneReportInstructions': return 'הוראות דיווח טלפוני';
			case 'report.phoneReportSteps': return 'שלבי הדיווח';
			case 'report.selectErrorType': return 'בחר סוג שגיאה';
			case 'report.selectErrorTypeHint': return 'בחר את סוג השגיאה';
			case 'report.mustFixErrors': return 'יש לתקן שגיאות';
			case 'report.reportSavedToFile': return ({required Object fileName}) => 'הדיווח נשמר בהצלחה לקובץ \'${fileName}\', הנמצא בתיקייה הראשית של אוצריא.';
			case 'report.youHaveReports': return ({required Object count}) => 'יש לך כבר ${count} דיווחים!';
			case 'report.canSendToEmail': return ({required Object email}) => 'כעת תוכל לשלוח את הקובץ למייל: ${email}';
			case 'report.send': return 'שלח';
			case 'report.reportNotAvailable': return 'דיווח לא זמין';
			case 'report.sendReport': return 'שלח דיווח';
			case 'editor.title': return 'עריכת טקסט';
			case 'editor.save': return 'שמור';
			case 'editor.cancel': return 'ביטול';
			case 'editor.editingConflict': return 'קונפליקט בעריכה';
			case 'editor.baseVersion': return 'גרסת בסיס';
			case 'editor.yourVersion': return 'הגרסה שלך';
			case 'editor.serverVersion': return 'גרסת השרת';
			case 'editor.chooseVersion': return 'בחר גרסה';
			case 'editor.useYourVersion': return 'השתמש בגרסה שלך';
			case 'editor.useServerVersion': return 'השתמש בגרסת השרת';
			case 'editor.mergeManually': return 'מזג ידנית';
			case 'editor.searchInSection': return 'חפש בקטע...';
			case 'editor.saving': return 'שומר...';
			case 'editor.saveSuccess': return 'השמירה הצליחה';
			case 'editor.saveError': return 'שגיאה בשמירה';
			case 'editor.discardChanges': return 'בטל שינויים';
			case 'editor.discardChangesConfirm': return 'האם לבטל את השינויים?';
			case 'editor.saveAndExit': return 'שמור וצא';
			case 'editor.searchInText': return 'חפש בטקסט';
			case 'editor.enterTextToSearch': return 'הכנס טקסט לחיפוש';
			case 'editor.whatToSearch': return 'מה לחפש';
			case 'editor.searchHint': return 'חפש...';
			case 'editor.addLink': return 'הוסף קישור';
			case 'editor.linkText': return 'טקסט הקישור';
			case 'editor.clickHere': return 'לחץ כאן';
			case 'editor.urlAddress': return 'כתובת URL';
			case 'editor.add': return 'הוסף';
			case 'editor.conflictInEditing': return 'קונפליקט בעריכה';
			case 'editor.conflictMessage': return 'נוצר קונפליקט בעריכה';
			case 'editor.keepMyEdit': return 'שמור את העריכה שלי';
			case 'editor.ignoreSourceChanges': return 'התעלם משינויים במקור';
			case 'editor.useNewVersion': return 'השתמש בגרסה החדשה';
			case 'editor.cancelMyEdit': return 'בטל את העריכה שלי';
			case 'editor.saveSeparately': return 'שמור בנפרד';
			case 'editor.saveAsSeparateVersion': return 'שמור כגרסה נפרדת';
			case 'editor.resolveConflict': return 'פתור קונפליקט';
			case 'editor.diffTitle': return ({required Object title}) => 'השוואה - ${title}';
			case 'editor.original': return 'מקור';
			case 'editor.edited': return 'נערך';
			case 'messages.editingInProgress': return 'עריכה בתהליך';
			case 'messages.saveBeforeLeaving': return 'שמור לפני יציאה';
			case 'messages.checkingConflicts': return 'בודק קונפליקטים...';
			case 'messages.savedSuccessfully': return 'נשמר בהצלחה';
			case 'messages.formattedCopyError': return 'שגיאה בהעתקה מעוצבת';
			case 'messages.cannotAccessClipboard': return 'לא ניתן לגשת ללוח';
			case 'messages.formattedTextCopied': return 'טקסט מעוצב הועתק';
			case 'messages.copyError': return 'שגיאה בהעתקה';
			case 'messages.sectionNotFound': return 'המקטע לא נמצא';
			case 'messages.bookNotFound': return 'הספר לא נמצא';
			case 'password.title': return 'הזן סיסמה';
			case 'password.enterPassword': return 'הכנס סיסמה';
			case 'pdfBook.navigateToUrl': return 'לעבור לURL?';
			case 'pdfBook.cancel': return 'ביטול';
			case 'pdfBook.go': return 'עבור';
			case 'pdfBook.noOutline': return 'אין תוכן עניינים';
			case 'links.searchInLinks': return 'חפש גם בתוכן הקישורים';
			case 'links.opened': return ({required Object ref}) => 'נפתח: ${ref}';
			case 'links.cannotOpenLink': return ({required Object error}) => 'לא ניתן לפתוח את הקישור: ${error}';
			case 'links.linkError': return ({required Object error}) => 'שגיאה בפתיחת הקישור: ${error}';
			case 'links.navigateTo': return ({required Object headerName}) => 'נווט ל: ${headerName}';
			case 'links.cannotNavigateToHeader': return ({required Object headerName}) => 'לא ניתן לנווט לכותרת: ${headerName}';
			case 'links.openBook': return ({required Object bookTitle, required Object headerName}) => 'פתח ספר: ${bookTitle} - ${headerName}';
			case 'links.cannotOpenBook': return ({required Object bookTitle}) => 'לא ניתן לפתוח את הספר: ${bookTitle}';
			case 'preview.openInReader': return 'פתח בעיון';
			default: return null;
		}
	}
}

