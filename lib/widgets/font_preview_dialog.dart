import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FontPreviewDialog extends StatefulWidget {
  final String fontFilePath;
  final Function(String displayName) onConfirm;
  final VoidCallback onCancel;

  const FontPreviewDialog({
    Key? key,
    required this.fontFilePath,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<FontPreviewDialog> createState() => _FontPreviewDialogState();
}

class _FontPreviewDialogState extends State<FontPreviewDialog> {
  final TextEditingController _nameController = TextEditingController();
  FontLoader? _fontLoader;
  String? _tempFontFamily;
  bool _isLoading = true;
  String? _errorMessage;

  final String _sampleText = '''
בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ׃
וְהָאָרֶץ הָיְתָה תֹהוּ וָבֹהוּ וְחֹשֶׁךְ עַל־פְּנֵי תְהוֹם
וְרוּחַ אֱלֹהִים מְרַחֶפֶת עַל־פְּנֵי הַמָּיִם׃

אַשְׁרֵי הָאִישׁ אֲשֶׁר לֹא הָלַךְ בַּעֲצַת רְשָׁעִים
וּבְדֶרֶךְ חַטָּאִים לֹא עָמָד וּבְמוֹשַׁב לֵצִים לֹא יָשָׁב׃
כִּי אִם בְּתוֹרַת יְהוָה חֶפְצוֹ וּבְתוֹרָתוֹ יֶהְגֶּה יוֹמָם וָלָיְלָה׃
''';

  @override
  void initState() {
    super.initState();
    _loadFontPreview();
    
    // הגדרת שם ברירת מחדל מתוך שם הקובץ
    final fileName = widget.fontFilePath.split(Platform.pathSeparator).last;
    final nameWithoutExtension = fileName.split('.').first;
    _nameController.text = nameWithoutExtension;
  }

  Future<void> _loadFontPreview() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final file = File(widget.fontFilePath);
      if (!await file.exists()) {
        throw Exception('קובץ הגופן לא נמצא');
      }

      final fontData = await file.readAsBytes();
      _tempFontFamily = 'preview_font_${DateTime.now().millisecondsSinceEpoch}';
      
      _fontLoader = FontLoader(_tempFontFamily!);
      _fontLoader!.addFont(Future.value(ByteData.view(fontData.buffer)));
      await _fontLoader!.load();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'שגיאה בטעינת הגופן: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'תצוגה מקדימה של הגופן',
        textAlign: TextAlign.right,
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // שדה שם הגופן
            TextField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'שם הגופן',
                hintText: 'הכנס שם לגופן',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // תצוגה מקדימה
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildPreviewContent(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _canConfirm() ? _handleConfirm : null,
          child: const Text('הוסף גופן'),
        ),
      ],
    );
  }

  Widget _buildPreviewContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('טוען גופן...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // כותרת
          Text(
            'תצוגה מקדימה:',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          
          // טקסט לדוגמה בגופן החדש
          Text(
            _sampleText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: _tempFontFamily,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // השוואה עם גופן ברירת מחדל
          Text(
            'השוואה עם גופן ברירת מחדל:',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 8),
          
          Text(
            _sampleText.split('\n').first,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'FrankRuhlCLM',
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  bool _canConfirm() {
    return _nameController.text.trim().isNotEmpty && 
           !_isLoading && 
           _errorMessage == null;
  }

  void _handleConfirm() {
    final displayName = _nameController.text.trim();
    if (displayName.isNotEmpty) {
      widget.onConfirm(displayName);
    }
  }
}