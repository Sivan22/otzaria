class Bookmark {
  final String ref;
  final String path;
  final int index;

  Bookmark({required this.ref, required this.path, required this.index});

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      ref: json['ref'] as String,
      path: json['path'] as String,
      index: json['index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ref': ref,
      'path': path,
      'index': index,
    };
  }
}
