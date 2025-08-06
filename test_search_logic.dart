// בדיקה מהירה של הלוגיקה החדשה

void main() {
  // סימולציה של הבדיקה
  print('Testing search logic...');

  // בדיקה 1: מחיקת אות אחת
  List<String> oldWords1 = ['בראשית', 'ברא'];
  List<String> newWords1 = ['בראשי', 'ברא']; // מחקנו ת' מהמילה הראשונה
  bool isMinor1 = isMinorTextChange(oldWords1, newWords1);
  print('Test 1 - Delete one letter: $isMinor1 (should be true)');

  // בדיקה 2: מחיקת מילה שלמה
  List<String> oldWords2 = ['בראשית', 'ברא'];
  List<String> newWords2 = ['ברא']; // מחקנו את המילה הראשונה
  bool isMinor2 = isMinorTextChange(oldWords2, newWords2);
  print('Test 2 - Delete whole word: $isMinor2 (should be false)');

  // בדיקה 3: הוספת אות אחת
  List<String> oldWords3 = ['בראשי', 'ברא'];
  List<String> newWords3 = ['בראשית', 'ברא']; // הוספנו ת' למילה הראשונה
  bool isMinor3 = isMinorTextChange(oldWords3, newWords3);
  print('Test 3 - Add one letter: $isMinor3 (should be true)');

  // בדיקה 4: שינוי מילה לחלוטין
  List<String> oldWords4 = ['בראשית', 'ברא'];
  List<String> newWords4 = ['שלום', 'ברא']; // שינינו את המילה הראשונה לחלוטין
  bool isMinor4 = isMinorTextChange(oldWords4, newWords4);
  print('Test 4 - Complete word change: $isMinor4 (should be false)');
}

bool isMinorTextChange(List<String> oldWords, List<String> newWords) {
  // אם מספר המילים השתנה, זה תמיד שינוי גדול
  // (מחיקת או הוספת מילה שלמה)
  if (oldWords.length != newWords.length) {
    return false;
  }

  // אם מספר המילים זהה, בדוק שינויים בתוך המילים
  for (int i = 0; i < oldWords.length && i < newWords.length; i++) {
    final oldWord = oldWords[i];
    final newWord = newWords[i];

    // אם המילים זהות, זה בסדר
    if (oldWord == newWord) continue;

    // בדיקה אם זה שינוי קטן (הוספה/הסרה של אות אחת או שתיים)
    final lengthDiff = (oldWord.length - newWord.length).abs();
    if (lengthDiff > 2) {
      return false; // שינוי גדול מדי
    }

    // בדיקה אם המילה החדשה מכילה את רוב האותיות של המילה הישנה
    final similarity = calculateWordSimilarity(oldWord, newWord);
    if (similarity < 0.7) {
      return false; // המילים שונות מדי
    }
  }

  return true;
}

bool areWordsSubset(List<String> smaller, List<String> larger) {
  if (smaller.length > larger.length) return false;

  int smallerIndex = 0;
  for (int largerIndex = 0;
      largerIndex < larger.length && smallerIndex < smaller.length;
      largerIndex++) {
    if (smaller[smallerIndex] == larger[largerIndex]) {
      smallerIndex++;
    }
  }

  return smallerIndex == smaller.length;
}

double calculateWordSimilarity(String word1, String word2) {
  if (word1.isEmpty && word2.isEmpty) return 1.0;
  if (word1.isEmpty || word2.isEmpty) return 0.0;
  if (word1 == word2) return 1.0;

  // חישוב מרחק עריכה פשוט
  final maxLength = word1.length > word2.length ? word1.length : word2.length;
  int distance = (word1.length - word2.length).abs();

  // ספירת תווים שונים באותו מיקום
  final minLength = word1.length < word2.length ? word1.length : word2.length;
  for (int i = 0; i < minLength; i++) {
    if (word1[i] != word2[i]) {
      distance++;
    }
  }

  // החזרת ציון דמיון (1.0 = זהות מלאה, 0.0 = שונות מלאה)
  return 1.0 - (distance / maxLength);
}
