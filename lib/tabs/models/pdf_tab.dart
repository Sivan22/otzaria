import 'package:otzaria/pdf_book/bloc/pdf_book_bloc.dart';
import 'package:otzaria/pdf_book/bloc/pdf_book_event.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/tabs/models/tab.dart';
import 'package:otzaria/utils/text_manipulation.dart';

/// Represents a tab with a PDF book.
///
/// The [PdfBookTab] class contains:
/// - The book itself ([book])
/// - The initial page number ([pageNumber])
/// - A [PdfBookBloc] instance to manage the viewer state
class PdfBookTab extends OpenedTab {
  /// The PDF book.
  final PdfBook book;

  /// The initial page number.
  int pageNumber;

  /// The bloc that manages this tab's PDF viewer state.
  final PdfBookBloc bloc;

  /// Creates a new instance of [PdfBookTab].
  ///
  /// [book] The PDF book to display
  /// [pageNumber] The initial page number to show (defaults to 1)
  PdfBookTab({
    required this.book,
    this.pageNumber = 1,
  })  : bloc = PdfBookBloc(pageNumber),
        super(book.title) {
    // Initialize the bloc with the book
  }

  /// Creates a copy of this tab with optional parameter overrides
  PdfBookTab copyWith({
    PdfBook? book,
    int? pageNumber,
  }) {
    return PdfBookTab(
      book: book ?? this.book,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  /// Creates a new instance of [PdfBookTab] from a JSON map.
  factory PdfBookTab.fromJson(Map<String, dynamic> json) {
    return PdfBookTab(
      book: PdfBook(
        title: getTitleFromPath(json['path']),
        path: json['path'],
      ),
      pageNumber: json['pageNumber'] ?? 1,
    );
  }

  /// Converts the [PdfBookTab] instance into a JSON map.
  @override
  Map<String, dynamic> toJson() {
    return {
      'path': book.path,
      'pageNumber': pageNumber,
      'type': 'PdfBookTab',
    };
  }

  List<Object?> get props => [book, pageNumber];
}
