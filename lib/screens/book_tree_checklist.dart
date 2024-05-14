import 'package:flutter/material.dart';
import 'package:otzaria/utils/text_manipulation.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class FileTreeViewScreen extends StatefulWidget {
  final String libraryRootPath;
  final List<String> checkedItems;

  const FileTreeViewScreen(
      {Key? key, required this.checkedItems, required this.libraryRootPath})
      : super(key: key);

  @override
  FileTreeViewScreenState createState() => FileTreeViewScreenState();
}

class FileTreeViewScreenState extends State<FileTreeViewScreen> {
  late Directory selectedDirectory;

  @override
  void initState() {
    selectedDirectory = Directory(widget.libraryRootPath);
    super.initState();
  }

  void _onItemChecked(FileSystemEntity item, bool isChecked) {
    setState(() {
      if (FileSystemEntity.isDirectorySync(item.path)) {
        for (FileSystemEntity file
            in Directory(item.path).listSync().toList()) {
          _onItemChecked(file, isChecked);
        }
      }
      if (isChecked) {
        widget.checkedItems.add(item.path);
      } else {
        widget.checkedItems.remove(item.path);
      }
    });
  }

  Widget _buildTreeView(Directory directory, int level) {
    return ExpansionTile(
      initiallyExpanded: level == 0,
      key: Key(directory.path), // Ensure unique keys for ExpansionTiles
      title: Text(path.basename(directory.path)),

      tilePadding: EdgeInsets.symmetric(horizontal: 16 + (level - 1) * 16),
      leading: SizedBox.fromSize(
        size: const Size.fromWidth(60.0),
        child: Row(
          children: [
            Checkbox(
                value: widget.checkedItems.contains(directory.path),
                onChanged: (value) => _onItemChecked(directory, value!)),
            const Icon(Icons.folder),
          ], // Icon(Icons.folder,
        ),
      ),

      children: directory.listSync().map((entity) {
        if (entity is Directory) {
          return _buildTreeView(entity, level + 1);
        } else if (entity is File && !entity.path.endsWith('.pdf')) {
          return CheckboxListTile(
            title: Row(children: [
              Text(
                getTitleFromPath(entity.path),
              ),
            ]),
            value: widget.checkedItems.contains(entity.path),
            onChanged: (value) => _onItemChecked(entity, value!),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.symmetric(horizontal: 16 + level * 16),
          );
        } else if (entity.path.endsWith('.pdf')) {
          return const SizedBox.shrink();
        } else {
          return ListTile(
            title: Text('Unknown: ${entity.path}'),
          );
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildTreeView(selectedDirectory, 0),
            ),
          )
        ],
      ),
    );
  }
}
