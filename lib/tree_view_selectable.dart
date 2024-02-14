import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class FileTreeViewScreen extends StatefulWidget {
  List<String> checkedItems;
  FileTreeViewScreen({Key? key, required this.checkedItems}) : super(key: key);
  @override
  _FileTreeViewScreenState createState() => _FileTreeViewScreenState();
}

class _FileTreeViewScreenState extends State<FileTreeViewScreen> {
  Directory? _selectedDirectory = Directory('.\\אוצריא');

  void _onItemChecked(FileSystemEntity item, bool isChecked) {
    setState(() {
      if (FileSystemEntity.isDirectorySync(item.path)) {
        for (FileSystemEntity file in Directory(item.path).listSync().toList()) {
          _onItemChecked(file, isChecked);
        }
      }
      if (isChecked) {
        widget.checkedItems.add(item.path);
        print('added ${item.path}');
      } else {
        widget.checkedItems.remove(item.path);
        print('removed ${item.path}');
      }
    });
  }

  Widget _buildTreeView(Directory directory, int level) {
    return ExpansionTile(
      key: Key(directory.path), // Ensure unique keys for ExpansionTiles
      title: Text(path.basename(directory.path)),      
      backgroundColor: level % 2 != 0 ? Colors.grey[200] : Colors.white,

      tilePadding:  EdgeInsets.symmetric(horizontal: 16 + level * 16),
      leading: SizedBox.fromSize(
        size: Size.fromWidth(60.0),
        child: Row(
          children: [            
          Checkbox(value: widget.checkedItems.contains(directory.path), 
          onChanged:(value) => _onItemChecked(directory, value!)),
        const Icon(Icons.folder), 
        ], // Icon(Icons.folder,
        ),
      ),
      
      children: directory.listSync().map((entity) {
        if (entity is Directory) {
          return _buildTreeView(entity, level + 1);
        } else if (entity is File && ! entity.path.endsWith('.pdf')) {
          return CheckboxListTile(            
            title: Row(
              children: [
            Text(path.basename(entity.path),
            )]
            ),
            value: widget.checkedItems.contains(entity.path),
            onChanged: (value) => _onItemChecked(entity, value!),
            controlAffinity: ListTileControlAffinity.leading,            contentPadding: EdgeInsets.symmetric(horizontal: 16 + level * 16),
          );
        } else if (entity.path.endsWith('.pdf')) {
          return const SizedBox.shrink();
        }
        else {
          return ListTile(title: Text('Unknown: ${entity.path}'));
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_selectedDirectory != null)            
          Expanded(
            child: _selectedDirectory != null
                ? SingleChildScrollView(child: _buildTreeView(_selectedDirectory!, 0))
                : Center(
                    child: Text('No directory selected. Tap the folder icon to pick one.'),
                  ),
          ),
        ],
      ),
    );
  }
}