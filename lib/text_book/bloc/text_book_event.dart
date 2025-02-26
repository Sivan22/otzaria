import 'package:equatable/equatable.dart';
import 'package:otzaria/models/books.dart';

sealed class TextBookEvent extends Equatable {
  const TextBookEvent();

  @override
  List<Object?> get props => [];
}

class LoadContent extends TextBookEvent {
  final TextBook book;

  const LoadContent({
    required this.book,
  });

  @override
  List<Object?> get props => [book];
}

class UpdateFontSize extends TextBookEvent {
  final double fontSize;

  const UpdateFontSize(this.fontSize);

  @override
  List<Object?> get props => [fontSize];
}

class ToggleLeftPane extends TextBookEvent {
  final bool show;

  const ToggleLeftPane(this.show);

  @override
  List<Object?> get props => [show];
}

class ToggleSplitView extends TextBookEvent {
  final bool show;

  const ToggleSplitView(this.show);

  @override
  List<Object?> get props => [show];
}

class UpdateCommentators extends TextBookEvent {
  final List<String> commentators;

  const UpdateCommentators(this.commentators);

  @override
  List<Object?> get props => [commentators];
}

class ToggleNikud extends TextBookEvent {
  final bool remove;

  const ToggleNikud(this.remove);

  @override
  List<Object?> get props => [remove];
}

class UpdateVisibleIndecies extends TextBookEvent {
  final List<int> visibleIndecies;

  const UpdateVisibleIndecies(this.visibleIndecies);

  @override
  List<Object?> get props => [visibleIndecies];
}

class UpdateSelectedIndex extends TextBookEvent {
  final int? index;

  const UpdateSelectedIndex(this.index);

  @override
  List<Object?> get props => [index];
}

class TogglePinLeftPane extends TextBookEvent {
  final bool pin;

  const TogglePinLeftPane(this.pin);

  @override
  List<Object?> get props => [pin];
}

class UpdateSearchText extends TextBookEvent {
  final String text;

  const UpdateSearchText(this.text);

  @override
  List<Object?> get props => [text];
}
