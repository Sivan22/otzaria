// import 'dart:isolate';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:fuzzywuzzy/fuzzywuzzy.dart';
// import 'package:otzaria/models/app_model.dart';
// import 'package:otzaria/models/books.dart';
// import 'package:otzaria/models/library.dart';
// import 'package:otzaria/widgets/daf_yomi.dart';
// import 'package:otzaria/widgets/grid_items.dart';
// import 'package:provider/provider.dart';
// import 'package:otzaria/widgets/otzar_book_dialog.dart';

// class LibraryBrowser extends StatefulWidget {
//   const LibraryBrowser({Key? key}) : super(key: key);

//   @override
//   State<LibraryBrowser> createState() => _LibraryBrowserState();
// }

// class _LibraryBrowserState extends State<LibraryBrowser> {
//   late Category currentTopCategory;
//   TextEditingController searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsFlutterBinding.ensureInitialized();
//     currentTopCategory = Provider.of<AppModel>(context, listen: false).library;
//   }

//   @override
//   void dispose() {
//     searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Align(
//               alignment: Alignment.centerRight,
//               child: IconButton(
//                 icon: const Icon(Icons.home),
//                 tooltip: 'חזרה לתיקיה הראשית',
//                 onPressed: () => setState(() {
//                   searchController.clear();
//                   currentTopCategory =
//                       Provider.of<AppModel>(context, listen: false).library;
//                 }),
//               ),
//             ),
//             Expanded(
//               child: Center(
//                   child: Text(currentTopCategory.title,
//                       style: TextStyle(
//                         color: Theme.of(context).colorScheme.secondary,
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ))),
//             ),
//             DafYomi()
//           ],
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_upward),
//           tooltip: 'חזרה לתיקיה הקודמת',
//           onPressed: () => setState(() {
//             searchController.clear();
//             currentTopCategory = currentTopCategory.parent!.parent!;
//           }),
//         ),
//       ),
//       body: Column(
//         children: [
//           buildSearchBar(),
//           Expanded(
//             child: ListView(children: [
//               currentTopCategory.title == 'ספריית אוצריא'
//                   ? MyGridView(
//                       items: currentTopCategory.subCategories.map((element) {
//                       return CategoryGridItem(
//                         category: element,
//                         onCategoryClickCallback: () {
//                           _openCategory(element);
//                         },
//                       );
//                     }).toList())
//                   : Column(
//                     children: [
//                       MyGridView(
//                           items: currentTopCategory.books.map((element) {
//                           return BookGridItem(
//                             book: element,
//                             onBookClickCallback: () {
//                               Provider.of<AppModel>(context, listen: false)
//                                   .openBook(element, 0, openLeftPane: true);
//                             },
//                           );
//                         }).toList()),
         
//   }

//   Widget buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//                 focusNode: Provider.of<AppModel>(context).bookLocatorFocusNode,
//                 autofocus: true,
//                 controller: searchController,
//                 decoration: InputDecoration(
//                   constraints: const BoxConstraints(maxWidth: 400),
//                   prefixIcon: const Icon(Icons.search),
//                   suffixIcon: IconButton(
//                       onPressed: () => searchController.clear(),
//                       icon: const Icon(Icons.cancel)),
//                   border: const OutlineInputBorder(
//                       borderRadius: BorderRadius.all(Radius.circular(8.0))),
//                   hintText: 'איתור ספר ב${currentTopCategory.title}',
//                 ),
//                 onChanged: (value) {}),
//           ),
//           IconButton(
//             icon: Icon(Icons.filter_list),
//             onPressed: () => _showFilterDialog(),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return StatefulBuilder(builder: (context, setState) {
//           return AlertDialog(
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CheckboxListTile(
//                   title: Text('הצג ספרים מאוצר החכמה'),
//                   value:
//                       Provider.of<AppModel>(context).showOtzarHachochma.value,
//                   onChanged: (bool? value) {
//                     setState(() {
//                       Provider.of<AppModel>(context, listen: false)
//                           .showOtzarHachochma
//                           .value = value ?? false;
//                     });
//                   },
//                 ),
//                 CheckboxListTile(
//                   title: Text('הצג ספרים מהיברובוקס'),
//                   value: Provider.of<AppModel>(context).showHebrewBooks.value,
//                   onChanged: (bool? value) {
//                     setState(() {
//                       Provider.of<AppModel>(context, listen: false)
//                           .showHebrewBooks
//                           .value = value ?? false;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           );
//         });
//       },
//     );
//   }

//   Future<List<Widget>> getFilteredBooks() async {
//     final query = searchController.text.trim().toLowerCase();
//     final queryWords = query.split(RegExp(r'\s+'));

//     List<dynamic> localEntries =
//         currentTopCategory.getAllBooksAndCategories().where((element) {
//       final title = element.title.toLowerCase();
//       return queryWords.every((word) => title.contains(word));
//     }).toList();

//     List<ExternalBook> otzarEntries = [];
//     if (Provider.of<AppModel>(context, listen: false)
//         .showOtzarHachochma
//         .value) {
//       final otzarBooksfinal =
//           await Provider.of<AppModel>(context, listen: false).otzarBooks;
//       otzarEntries = otzarBooksfinal.where((book) {
//         final title = book.title.toLowerCase();
//         return queryWords.every((word) => title.contains(word));
//       }).toList();
//     }

//     List<dynamic> allEntries = [...localEntries, ...otzarEntries];
//     allEntries = await sortEntries(allEntries, query);

//     List<Widget> items = [];

//     for (final entry in allEntries.take(50)) {
//       if (entry is Category) {
//         items.add(
//           CategoryGridItem(
//             category: entry,
//             onCategoryClickCallback: () => _openCategory(entry),
//           ),
//         );
//       } else if (entry is Book) {
//         if (entry is ExternalBook) {
//           items.add(
//             BookGridItem(
//               book: entry,
//               onBookClickCallback: () => _openOtzarBook(entry),
//             ),
//           );
//         } else {
//           items.add(
//             BookGridItem(
//               book: entry,
//               showTopics: true,
//               onBookClickCallback: () {
//                 Provider.of<AppModel>(context, listen: false)
//                     .openBook(entry, 0, openLeftPane: true);
//               },
//             ),
//           );
//         }
//       }
//     }
//     return items;
//   }

//   Future<List<dynamic>> sortEntries(List<dynamic> entries, String query) async {
//     return await Isolate.run(() {
//       entries.sort((a, b) {
//         final titleA = a is Book ? a.title : '';
//         final titleB = b is Book ? b.title : '';
//         final scoreA = ratio(query, titleA.toLowerCase());
//         final scoreB = ratio(query, titleB.toLowerCase());
//         return scoreB.compareTo(scoreA);
//       });
//       return entries;
//     });
//   }

//   void _openOtzarBook(ExternalBook book) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return OtzarBookDialog(book: book);
//       },
//     );
//   }

//   // Future<List<Widget>> getGrids(Category category) async {
//   //   List<Widget> items = [];
//   //   category.books.sort(
//   //     (a, b) => a.order.compareTo(b.order),
//   //   );
//   //   category.subCategories.sort(
//   //     (a, b) => a.order.compareTo(b.order),
//   //   );
//   //   if (true) {
//   //     Future<List<Widget>> books = () async {
//   //       List<Widget> books = [];
//   //       for (Book book in category.books) {
//   //         books.add(
//   //           BookGridItem(
//   //               book: book,
//   //               onBookClickCallback: () {
//   //                 Provider.of<AppModel>(context, listen: false)
//   //                     .openBook(book, 0, openLeftPane: true);
//   //               }),
//   //         );
//   //       }
//   //       return books;
//   //     }();
//   //     items.add(MyGridView(items: books));

//   //     for (Category subCategory in category.subCategories) {
//   //       subCategory.books.sort((a, b) => a.order.compareTo(b.order));
//   //       subCategory.subCategories.sort((a, b) => a.order.compareTo(b.order));

//   //       items.add(Center(child: HeaderItem(category: subCategory)));
//   //       items.add(MyGridView(items: _getGridItems(subCategory)));
//   //     }
//   //   } else {
//   //     items.add(MyGridView(
//   //       items: _getGridItems(currentTopCategory),
//   //     ));
//   //   }

//   //   return items;
//   // }

//   // Future<List<Widget>> _getGridItems(Category category) async {
//   //   List<Widget> items = [];
//   //   for (Book book in category.books) {
//   //     items.add(
//   //       BookGridItem(
//   //           book: book,
//   //           onBookClickCallback: () {
//   //             Provider.of<AppModel>(context, listen: false)
//   //                 .openBook(book, 0, openLeftPane: true);
//   //           }),
//   //     );
//   //   }
//   //   for (Category subCategory in category.subCategories) {
//   //     items.add(
//   //       CategoryGridItem(
//   //         category: subCategory,
//   //         onCategoryClickCallback: () => _openCategory(subCategory),
//   //       ),
//   //     );
//   //   }

//   //   return items;
//   // }

//   void _openCategory(Category category) {
//     currentTopCategory = category;
//     setState(() {});
//   }
// }
