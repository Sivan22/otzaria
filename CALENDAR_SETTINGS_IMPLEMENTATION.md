# יישום זכירת הגדרות לוח השנה

## מה שהוסף

### 1. הגדרות חדשות ב-SettingsRepository
- נוסף מפתח חדש: `keyCalendarType = 'key-calendar-type'`
- נוסף מפתח חדש: `keySelectedCity = 'key-selected-city'`
- נוספה פונקציה `updateCalendarType(String value)` לשמירת סוג לוח השנה
- נוספה פונקציה `updateSelectedCity(String value)` לשמירת העיר הנבחרת
- נוספה טעינת ההגדרות ב-`loadSettings()` עם ברירות מחדל
- נוספה אתחול ההגדרות ב-`_writeDefaultsToStorage()`

### 2. עדכון CalendarCubit
- נוסף constructor parameter עבור `SettingsRepository`
- נוספה פונקציה `_initializeCalendar()` שטוענת את ההגדרות השמורות
- עודכנה `changeCalendarType()` כדי לשמור את הבחירה
- עודכנה `changeCity()` כדי לשמור את העיר הנבחרת
- נוספו פונקציות עזר להמרה בין String ל-CalendarType

### 3. עדכון MoreScreen
- נוסף import עבור `SettingsRepository`
- נוסף instance של `SettingsRepository`
- עודכן יצירת ה-`CalendarCubit` להעביר את ה-repository

## איך זה עובד

1. כשהמשתמש פותח את האפליקציה, ה-`CalendarCubit` טוען את ההגדרות השמורות
2. כשהמשתמש משנה את סוג לוח השנה בדיאלוג ההגדרות, הבחירה נשמרת אוטומטית
3. כשהמשתמש משנה את העיר ב-dropdown, הבחירה נשמרת אוטומטית
4. בפעם הבאה שהמשתמש יפתח את האפליקציה, לוח השנה יוצג עם ההגדרות שנבחרו

## הגדרות זמינות

### סוגי לוח השנה
- `hebrew` - לוח עברי בלבד
- `gregorian` - לוח לועזי בלבד  
- `combined` - לוח משולב (ברירת מחדל)

### ערים זמינות
- ירושלים (ברירת מחדל)
- תל אביב
- חיפה
- באר שבע
- נתניה
- אשדוד
- פתח תקווה
- בני ברק
- מודיעין עילית
- צפת
- טבריה
- אילת
- רחובות
- הרצליה
- רמת גן
- חולון
- בת ים
- רמלה
- לוד
- אשקלון

כל ההגדרות נשמרות ב-SharedPreferences ונטענות אוטומטית בכל הפעלה של האפליקציה.