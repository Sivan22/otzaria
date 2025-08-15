# Requirements Document

## Introduction

תכונת ההערות האישיות תאפשר למשתמשים להוסיף הערות אישיות לטקסטים בספרים השונים. ההערות יישמרו בצורה מדויקת ויוצגו במיקום הנכון גם כאשר מבנה הטקסט משתנה. התכונה תפתור את הבעיה הקיימת של קריאת ספרים בבלוקים שיכולה לגרום לאי-דיוק במיקום ההערות.

הפתרון יתבסס על מעבר ממודל "בלוקים/שורות" למודל מסמך קנוני עם מערכת עיגון מתקדמת שכוללת שמירת הקשר טקסטואלי ו-fingerprints קריפטוגרפיים לזיהוי מדויק של מיקום ההערות.

## Requirements

### Requirement 1

**User Story:** כמשתמש, אני רוצה להוסיף הערה אישית לטקסט ספציפי בספר, כדי שאוכל לשמור מחשבות ותובנות אישיות.

#### Acceptance Criteria

1. WHEN המשתמש בוחר טקסט בספר THEN המערכת SHALL להציג אפשרות להוסיף הערה
2. WHEN המשתמש לוחץ על "הוסף הערה" THEN המערכת SHALL לפתוח חלון עריכת הערה
3. WHEN המשתמש כותב הערה ושומר THEN המערכת SHALL לשמור את ההערה עם מיקום מדויק
4. IF ההערה נשמרה בהצלחה THEN המערכת SHALL להציג סימון ויזואלי על הטקסט המוערה

### Requirement 2

**User Story:** כמשתמש, אני רוצה לראות את ההערות שלי במיקום המדויק בטקסט, כדי שההקשר יישמר גם כאשר מבנה הספר משתנה.

#### Acceptance Criteria

1. WHEN המשתמש פותח ספר עם הערות קיימות THEN המערכת SHALL להציג את ההערות במיקום הנכון
2. WHEN מבנה הטקסט משתנה (הוספה/הסרה של שורות) THEN המערכת SHALL לשמור על מיקום ההערות היחסי
3. WHEN המשתמש מעביר עכבר על טקסט מוערה THEN המערכת SHALL להציג את תוכן ההערה
4. IF ההערה לא יכולה להיות ממוקמת במדויק THEN המערכת SHALL להציג התראה למשתמש

### Requirement 3

**User Story:** כמשתמש, אני רוצה לערוך ולמחוק הערות קיימות, כדי שאוכל לעדכן ולנהל את ההערות שלי.

#### Acceptance Criteria

1. WHEN המשתמש לוחץ על הערה קיימת THEN המערכת SHALL להציג אפשרויות עריכה ומחיקה
2. WHEN המשתמש בוחר "ערוך הערה" THEN המערכת SHALL לפתוח את חלון העריכה עם התוכן הקיים
3. WHEN המשתמש בוחר "מחק הערה" THEN המערכת SHALL לבקש אישור ולמחוק את ההערה
4. IF ההערה נמחקה THEN המערכת SHALL להסיר את הסימון הויזואלי מהטקסט

### Requirement 4

**User Story:** כמשתמש, אני רוצה שההערות שלי יישמרו בצורה עמידה ומדויקת, כדי שלא אאבד אותן בעת עדכונים או שינויים בתוכנה.

#### Acceptance Criteria

1. WHEN המשתמש שומר הערה THEN המערכת SHALL לשמור אותה עם מזהה ייחודי ומיקום מדויק
2. WHEN הספר נטען מחדש THEN המערכת SHALL לטעון את כל ההערות הרלוונטיות
3. WHEN התוכנה מתעדכנת THEN המערכת SHALL לשמור על תאימות עם הערות קיימות
4. IF קובץ ההערות פגום THEN המערכת SHALL לנסות לשחזר הערות או להציג הודעת שגיאה מתאימה

### Requirement 5

**User Story:** כמשתמש, אני רוצה לחפש בהערות שלי, כדי שאוכל למצוא במהירות הערות ספציפיות.

#### Acceptance Criteria

1. WHEN המשתמש פותח את תפריט ההערות THEN המערכת SHALL להציג רשימה של כל ההערות
2. WHEN המשתמש מקליד בשדה החיפוש THEN המערכת SHALL לסנן הערות לפי תוכן הטקסט
3. WHEN המשתמש לוחץ על הערה ברשימה THEN המערכת SHALL לנווט למיקום ההערה בספר
4. IF אין הערות התואמות לחיפוש THEN המערכת SHALL להציג הודעה מתאימה

### Requirement 6

**User Story:** כמשתמש, אני רוצה לייצא ולייבא הערות, כדי שאוכל לגבות אותן ולשתף אותן בין מכשירים.

#### Acceptance Criteria

1. WHEN המשתמש בוחר "ייצא הערות" THEN המערכת SHALL ליצור קובץ עם כל ההערות
2. WHEN המשתמש בוחר "ייבא הערות" THEN המערכת SHALL לטעון הערות מקובץ חיצוני
3. WHEN מתבצע ייבוא THEN המערכת SHALL לבדוק תאימות ולמזג עם הערות קיימות
4. IF יש התנגשות בין הערות THEN המערכת SHALL לבקש מהמשתמש כיצד לפתור את ההתנגשות

### Requirement 7

**User Story:** כמפתח, אני רוצה שהמערכת תשמור הערות עם מערכת עיגון מתקדמת, כדי שההערות יישארו מדויקות גם כאשר מבנה הטקסט משתנה.

#### Acceptance Criteria

1. WHEN הערה נשמרת THEN המערכת SHALL לשמור מזהה ספר, גרסת מסמך, אופסטים של תווים, וטקסט מנורמל
2. WHEN הערה נשמרת THEN המערכת SHALL לשמור חלון הקשר לפני ואחרי (prefix/suffix) בגודל N תווים
3. WHEN הערה נשמרת THEN המערכת SHALL לחשב ולשמור fingerprints קריפטוגרפיים (SHA-256) של הטקסט המסומן והקשר
4. WHEN הערה נשמרת THEN המערכת SHALL לשמור rolling hash (Rabin-Karp) לחלון הקשר להאצת חיפוש

### Requirement 8

**User Story:** כמפתח, אני רוצה שהמערכת תיישם אלגוריתם re-anchoring מתקדם, כדי לאתר הערות גם לאחר שינויים במסמך.

#### Acceptance Criteria

1. WHEN מסמך נטען עם גרסה זהה THEN המערכת SHALL למקם הערות לפי אופסטים (O(1))
2. WHEN גרסת מסמך שונה THEN המערכת SHALL לחפש text_hash מדויק במסמך הקנוני
3. IF חיפוש מדויק נכשל THEN המערכת SHALL לחפש הקשר (prefix/suffix) במרחק ≤ K תווים
4. IF חיפוש הקשר נכשל THEN המערכת SHALL להשתמש בחיפוש דמיון מטושטש (Levenshtein/Cosine)
5. IF נמצאו מספר מועמדים THEN המערכת SHALL לבקש הכרעת משתמש
6. IF לא נמצא מיקום מתאים THEN המערכת SHALL לסמן הערה כ"יתומה"

### Requirement 9

**User Story:** כמפתח, אני רוצה שהמערכת תשתמש במסמך קנוני אחיד, כדי להבטיח עקביות במיקום ההערות.

#### Acceptance Criteria

1. WHEN ספר נטען THEN המערכת SHALL ליצור ייצוג מסמך קנוני רציף
2. WHEN מסמך קנוני נוצר THEN המערכת SHALL לחשב גרסת מסמך (checksum)
3. WHEN טקסט מנורמל THEN המערכת SHALL להחליף רווחים מרובים ולאחד סימני פיסוק
4. IF קיימת היררכיה פנימית THEN המערכת SHALL לשמור נתיב לוגי (פרקים/פסקאות)

### Requirement 10

**User Story:** כמשתמש, אני רוצה לראות סטטוס עיגון ההערות, כדי לדעת עד כמה המיקום מדויק.

#### Acceptance Criteria

1. WHEN הערה מוצגת THEN המערכת SHALL להציג סטטוס עיגון: "מדויק", "מוזז אך אותר", או "נדרש אימות ידני"
2. WHEN יש הערות יתומות THEN המערכת SHALL להציג מסך "הערות יתומות" עם אשף התאמה
3. WHEN מוצגים מועמדי התאמה THEN המערכת SHALL להציג 1-3 מועמדים קרובים עם ציון דמיון
4. IF משתמש בוחר מועמד THEN המערכת SHALL לעדכן את העיגון ולסמן כ"מדויק"

### Requirement 11

**User Story:** כמפתח, אני רוצה שהמערכת תהיה יעילה בביצועים, כדי שהוספת הערות לא תשפיע על חוויית המשתמש.

#### Acceptance Criteria

1. WHEN מתבצע עיגון/רה-עיגון THEN המערכת SHALL להשלים את התהליך ב≤ 50ms להערה בממוצע
2. WHEN עמוד נטען עם הערות THEN המערכת SHALL לא לעכב טעינה > 16ms (ביצוע ברקע)
3. WHEN נשמר אינדקס הקשר THEN המערכת SHALL להשתמש בדחיסה (n-grams בגודל 3-5)
4. IF יש מעל 1000 הערות בספר THEN המערכת SHALL להשתמש באינדקס מהיר (rolling-hash)

### Requirement 12

**User Story:** כמשתמש, אני רוצה שההערות שלי יהיו מוגנות ופרטיות, כדי שרק אני אוכל לגשת אליהן.

#### Acceptance Criteria

1. WHEN הערה נשמרת THEN המערכת SHALL להצפין את תוכן ההערה מקומית
2. WHEN הערות מיוצאות THEN המערכת SHALL לאפשר הצפנה בפורמט AES-GCM במפתח משתמש
3. WHEN הערות משותפות THEN המערכת SHALL לנהל הרשאות גישה לפי משתמש
4. IF קובץ הערות פגום THEN המערכת SHALL לבדוק שלמות ולנסות שחזור

### Requirement 13

**User Story:** כמפתח, אני רוצה שהמערכת תעבור מהמודל הקיים בצורה חלקה, כדי שלא יאבדו הערות קיימות.

#### Acceptance Criteria

1. WHEN מתבצעת מיגרציה THEN המערכת SHALL לבנות מסמך קנוני מכל ספר קיים
2. WHEN הערות קיימות מומרות THEN המערכת SHALL להפיק hash-ים וחלונות הקשר
3. WHEN מיגרציה מושלמת THEN המערכת SHALL להריץ re-anchoring ראשונית
4. IF יש בעיות במיגרציה THEN המערכת SHALL לסמן חריגות ולאפשר תיקון ידני

### Requirement 14

**User Story:** כמפתח, אני רוצה שהמערכת תעמוד בבדיקות קבלה מחמירות, כדי להבטיח איכות ואמינות.

#### Acceptance Criteria

1. WHEN נוספות 100 הערות ומשתנות 5% שורות THEN המערכת SHALL לשמור ≥ 98% הערות כ"מדויק"
2. WHEN משתנים רק ריווח ושבירת שורות THEN המערכת SHALL לשמור 100% הערות כ"מדויק"
3. WHEN נמחק קטע מסומן לחלוטין THEN המערכת SHALL לסמן הערה כ"יתומה"
4. WHEN מתבצע ייבוא/ייצוא THEN המערכת SHALL לשמור זהות מספר הערות, תוכן ומצב עיגון## T
echnical Specifications

### Default Values and Constants

- **N (חלון הקשר):** 40 תווים לפני ואחרי הטקסט המסומן
- **K (מרחק מקסימלי בין prefix/suffix):** 300 תווים
- **ספי דמיון:**
  - Levenshtein: ≤ 0.18 מהאורך המקורי
  - Cosine n-grams: ≥ 0.82
- **גודל n-grams לאינדקס:** 3-5 תווים
- **מגבלת זמן re-anchoring:** 50ms להערה בממוצע
- **מגבלת עיכוב טעינת עמוד:** 16ms

### Text Normalization Standard

הנירמול יכלול:
1. החלפת רווחים מרובים ברווח יחיד
2. הסרת סימני כיווניות לא מודפסים (LTR/RTL marks)
3. יוניפיקציה של גרשיים ומירכאות לסוג אחיד
4. שמירה על ניקוד עברי (אופציונלי לפי הגדרות משתמש)
5. trim של רווחים בתחילת וסוף הטקסט

### Data Schema (SQLite/Database)

```sql
CREATE TABLE notes (
    note_id TEXT PRIMARY KEY,  -- UUID
    book_id TEXT NOT NULL,
    doc_version_id TEXT NOT NULL,
    logical_path TEXT,  -- JSON array: ["chapter:3", "para:12"]
    char_start INTEGER NOT NULL,
    char_end INTEGER NOT NULL,
    selected_text_normalized TEXT NOT NULL,
    text_hash TEXT NOT NULL,  -- SHA-256
    ctx_before TEXT NOT NULL,
    ctx_after TEXT NOT NULL,
    ctx_before_hash TEXT NOT NULL,  -- SHA-256
    ctx_after_hash TEXT NOT NULL,   -- SHA-256
    rolling_before INTEGER NOT NULL,  -- Rabin-Karp hash
    rolling_after INTEGER NOT NULL,   -- Rabin-Karp hash
    status TEXT NOT NULL CHECK (status IN ('anchored', 'shifted', 'orphan')),
    content_markdown TEXT NOT NULL,
    author_user_id TEXT NOT NULL,
    privacy TEXT NOT NULL CHECK (privacy IN ('private', 'shared')),
    tags TEXT,  -- JSON array
    created_at TEXT NOT NULL,  -- ISO8601
    updated_at TEXT NOT NULL   -- ISO8601
);

CREATE INDEX idx_notes_book_id ON notes(book_id);
CREATE INDEX idx_notes_doc_version ON notes(doc_version_id);
CREATE INDEX idx_notes_text_hash ON notes(text_hash);
CREATE INDEX idx_notes_ctx_hashes ON notes(ctx_before_hash, ctx_after_hash);
CREATE INDEX idx_notes_author ON notes(author_user_id);
```

### API Endpoints Structure

- `POST /api/notes` - יצירת הערה חדשה
- `GET /api/notes?book_id={id}` - שליפת הערות לספר
- `PATCH /api/notes/{id}` - עדכון תוכן הערה
- `DELETE /api/notes/{id}` - מחיקה רכה של הערה
- `POST /api/notes/reanchor` - הפעלת re-anchoring ידני
- `GET /api/notes/orphans` - שליפת הערות יתומות
- `POST /api/notes/export` - ייצוא הערות
- `POST /api/notes/import` - ייבוא הערות