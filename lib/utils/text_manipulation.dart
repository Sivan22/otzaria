String stripHtmlIfNeeded(String text) {
  return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
}

String removeVolwels(String s) {
  return s.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');
}
