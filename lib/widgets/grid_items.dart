import 'package:flutter/material.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/books.dart';
import 'dart:math';

class HeaderItem extends StatelessWidget {
  final Category category;

  const HeaderItem({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(category.title,
          style: TextStyle(
            fontSize: 20,
            color: Theme.of(context).colorScheme.secondary,
          )),
    );
  }
}

class CategoryGridItem extends StatelessWidget {
  final Category category;
  final VoidCallback onCategoryClickCallback;

  const CategoryGridItem({
    Key? key,
    required this.category,
    required this.onCategoryClickCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12.0),
        hoverColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
        hoverDuration: Durations.medium1,
        onTap: () => onCategoryClickCallback(),
        child: Align(
            alignment: Alignment.topRight,
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    title: Text(
                      category.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                category.shortDescription.isEmpty
                    ? SizedBox.shrink()
                    : Tooltip(
                        richMessage: WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                category.shortDescription,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                              ),
                            )),
                        child: IconButton(
                          mouseCursor: SystemMouseCursors.basic,
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline),
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.6),
                        ),
                      )
              ],
            )),
      ),
    );
  }
}

class BookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onBookClickCallback;

  const BookGridItem({
    Key? key,
    required this.book,
    required this.onBookClickCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12.0),
          hoverColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          onTap: () => onBookClickCallback(),
          hoverDuration: Durations.medium1,
          child: Align(
            alignment: Alignment.topRight,
            child: Row(
              children: [
                book is PdfBook
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: Icon(Icons.picture_as_pdf,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.6)),
                      )
                    : const SizedBox.shrink(),
                Expanded(
                  child: ListTile(
                    mouseCursor: SystemMouseCursors.click,
                    title: Text(
                      book.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        (book.author == "" || book.author == null)
                            ? ''
                            : ('${book.author!} ${book.pubDate ?? ''}'),
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                book.heShortDesc == null || book.heShortDesc == ''
                    ? const SizedBox.shrink()
                    : Tooltip(
                        richMessage: WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              constraints: const BoxConstraints(maxWidth: 250),
                              child: Text(
                                book.heShortDesc!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary),
                              ),
                            )),
                        child: IconButton(
                          mouseCursor: SystemMouseCursors.basic,
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline),
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.6),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyGridView extends StatelessWidget {
  final Future<List<Widget>> items;

  const MyGridView({Key? key, required this.items}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return FutureBuilder(
            future: items,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 45),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        //max number of items per row is 5 and min is 1
                        crossAxisCount:
                            max(1, min(constraints.maxWidth ~/ 250, 5)),
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => snapshot.data![index],
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            });
      },
    );
  }
}
