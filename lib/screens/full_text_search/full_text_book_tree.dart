import 'package:flutter/material.dart';
import 'package:otzaria/models/app_model.dart';
import 'package:otzaria/models/books.dart';
import 'package:otzaria/models/library.dart';
import 'package:otzaria/models/tabs.dart';
import 'package:provider/provider.dart';

class FullTextBookTree extends StatefulWidget {
  final SearchingTab tab;
  const FullTextBookTree({Key? key, required this.tab}) : super(key: key);

  @override
  State<FullTextBookTree> createState() => _FullTextBookTreeState();
}

class _FullTextBookTreeState extends State<FullTextBookTree> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: widget.tab.booksToSearch,
        builder: (context, value, child) {
          return FutureBuilder(
              future: Provider.of<AppModel>(context, listen: false).library,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return SingleChildScrollView(child: _buildTree(snapshot.data!));
              });
        });
  }

  Widget _buildTree(Category category, {int level = 0}) {
    return ExpansionTile(
      key: PageStorageKey(category), // Ensure unique keys for ExpansionTiles
      title: Text(category.title),

      tilePadding: EdgeInsets.symmetric(horizontal: 6 + (level) * 6),
      leading: SizedBox.fromSize(
        size: const Size.fromWidth(60.0),
        child: Row(
          children: [
            Checkbox(
                value: isCategoryChecked(category),
                onChanged: (value) {
                  if (value != null && value) {
                    addCategory(category);
                  } else {
                    removeCategory(category);
                  }
                  widget.tab.booksToSearch.notifyListeners();
                }),
            const Icon(Icons.folder),
          ], // Icon(Icons.folder,
        ),
      ),

      children: ([] + category.subCategories + category.books).map((entity) {
        if (entity is Category) {
          return _buildTree(entity, level: level + 1);
        } else if (entity is Book) {
          return CheckboxListTile(
            title: Row(children: [
              Text(
                entity.title,
              ),
            ]),
            value: widget.tab.booksToSearch.value.contains(entity),
            onChanged: (value) {
              widget.tab.booksToSearch.value.contains(entity)
                  ? widget.tab.booksToSearch.value.remove(entity)
                  : widget.tab.booksToSearch.value.add(entity);
              widget.tab.booksToSearch.notifyListeners();
            }, //TODO: fix
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 16 + level * 16),
          );
        } else {
          return ListTile(
            title: Text('Unknown: ${entity.path}'),
          );
        }
      }).toList(),
    );
  }

  void addCategory(Category category) {
    for (Book book in category.books) {
      widget.tab.booksToSearch.value.add(book);
    }
    for (Category subCategory in category.subCategories) {
      addCategory(subCategory);
    }
  }

  void removeCategory(Category category) {
    for (Book book in category.books) {
      widget.tab.booksToSearch.value.remove(book);
    }
    for (Category subCategory in category.subCategories) {
      removeCategory(subCategory);
    }
  }

  bool isCategoryChecked(Category category) {
    return category.books
            .every((test) => widget.tab.booksToSearch.value.contains(test)) &&
        category.subCategories.every((test) => isCategoryChecked(test));
  }
}
