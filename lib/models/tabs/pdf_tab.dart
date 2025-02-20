import 'package:otzaria/bloc/pdf_book/pdf_book_bloc.dart';
import 'package:otzaria/bloc/pdf_book/pdf_book_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/tabs/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart';

/// Represents a tab with a PDF book.
///
/// The [PdfBookTab] class contains:
/// - The book itself ([book])
/// - The initial page number ([initialPage])
/// - A [PdfBookBloc] instance to manage the viewer state
class PdfBookTab extends OpenedTab {
  /// The PDF book.
  final PdfBook book;

  /// The initial page number.
  final int initialPage;

  /// The bloc that manages this tab's PDF viewer state.
  final PdfBookBloc bloc;

  /// Creates a new instance of [PdfBookTab].
  ///
  /// [book] The PDF book to display
  /// [initialPage] The initial page number to show (defaults to 1)
  PdfBookTab({
    required this.book,
    this.initialPage = 1,
  })  : bloc = PdfBookBloc(),
        super(book.title) {
    // Initialize the bloc with the book
    bloc.add(LoadPdfBook(
      path: book.path,
      initialPage: initialPage,
    ));
  }

  /// Creates a copy of this tab with optional parameter overrides
  PdfBookTab copyWith({
    PdfBook? book,
    int? initialPage,
  }) {
    return PdfBookTab(
      book: book ?? this.book,
      initialPage: initialPage ?? this.initialPage,
    );
  }

  /// Creates a new instance of [PdfBookTab] from a JSON map.
  factory PdfBookTab.fromJson(Map<String, dynamic> json) {
    return PdfBookTab(
      book: PdfBook(
        title: getTitleFromPath(json['path']),
        path: json['path'],
      ),
      initialPage: json['pageNumber'] ?? 1,
    );
  }

  /// Converts the [PdfBookTab] instance into a JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'path': book.path,
      'pageNumber': initialPage,
      'type': 'PdfBookTab',
    };
  }

  @override
  List<Object?> get props => [book, initialPage];

  /// Clean up resources when the tab is closed
  void dispose() {
    bloc.close();
  }
}
