import 'package:flutter/material.dart';
import 'package:otzaria/services/custom_fonts_service.dart';
import 'package:otzaria/utils/font_utils.dart';

class EnhancedFontDropdown extends StatefulWidget {
  final String title;
  final String settingKey;
  final String selected;
  final List<CustomFont> customFonts;
  final bool isLoading;
  final Icon? leading;
  final Function(String) onChange;
  final Function(String) onRemoveCustomFont;
  final VoidCallback? onAddCustomFont;
  final Function(String, String)? onRenameCustomFont;

  const EnhancedFontDropdown({
    Key? key,
    required this.title,
    required this.settingKey,
    required this.selected,
    required this.customFonts,
    required this.isLoading,
    this.leading,
    required this.onChange,
    required this.onRemoveCustomFont,
    this.onAddCustomFont,
    this.onRenameCustomFont,
  }) : super(key: key);

  @override
  State<EnhancedFontDropdown> createState() => _EnhancedFontDropdownState();
}

class _EnhancedFontDropdownState extends State<EnhancedFontDropdown> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // הוספת listener כדי לטפל במקרים שהתפריט נסגר בלי בחירה
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // התפריט נסגר - נוודא שהמצב חוזר לרגיל
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final builtInFonts = FontUtils.getBuiltInFonts();
    final allFontOptions = <String, String>{};
    
    // הוספת גופנים מובנים
    allFontOptions.addAll(builtInFonts);
    
    // הוספת מפריד אם יש גופנים אישיים
    if (widget.customFonts.isNotEmpty) {
      allFontOptions['---separator---'] = '───────────────────────────';
      allFontOptions['---custom-header---'] = 'גופנים אישיים:';
      
      // הוספת גופנים אישיים
      for (final font in widget.customFonts) {
        allFontOptions[font.id] = font.displayName;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4, left: 16, right: 16),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (widget.isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDropdown(context, allFontOptions),
                ),
                if (widget.onAddCustomFont != null) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: widget.isLoading ? null : widget.onAddCustomFont,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('הוסף גופן חדש'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        backgroundColor: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, Map<String, String> fontOptions) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 265), // בערך 7 ס"מ
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {
            // אם התפריט כבר פתוח, נסגור אותו
            if (_focusNode.hasFocus) {
              _focusNode.unfocus();
            }
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Focus(
              onKeyEvent: (node, event) {
                // טיפול בלחיצה על ESC
                if (event.logicalKey.keyLabel == 'Escape') {
                  _focusNode.unfocus();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: DropdownButtonFormField<String>(
        value: _getValidSelectedValue(fontOptions),
        focusNode: _focusNode,
        isExpanded: true,
        menuMaxHeight: 300,
        dropdownColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: Colors.transparent,
          filled: true,
        ),
        selectedItemBuilder: (context) {
          return fontOptions.entries.map((entry) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            );
          }).toList();
        },
      items: fontOptions.entries.map((entry) {
        // פריטים מיוחדים (מפרידים וכותרות)
        if (entry.key == '---separator---') {
          return DropdownMenuItem<String>(
            value: entry.key,
            enabled: false,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                entry.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }
        
        if (entry.key == '---custom-header---') {
          return DropdownMenuItem<String>(
            value: entry.key,
            enabled: false,
            child: SizedBox(
              width: double.infinity,
              child: Text(
                entry.value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        // גופנים אישיים עם אפשרות הסרה
        final isCustomFont = widget.customFonts.any((font) => font.id == entry.key);
        
        return DropdownMenuItem<String>(
          value: entry.key,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _shouldPreviewFont(entry.key) ? entry.key : null,
                      ),
                    ),
                  ),
              if (isCustomFont)
                PopupMenuButton<String>(
                  tooltip: '', // הסרת הטולטיפ
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('שנה שם'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('הסר גופן'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (action) {
                    if (action == 'remove') {
                      _showRemoveConfirmation(context, entry.key, entry.value);
                    } else if (action == 'rename') {
                      _showRenameDialog(context, entry.key, entry.value);
                    }
                  },
                ),
                ],
              ),
            ),
          ),
        );
        }).toList(),
        onChanged: (value) {
          // הסרת focus מיידית כשהתפריט נסגר
          _focusNode.unfocus();
          
          if (value != null && 
              !value.startsWith('---') && 
              value != widget.selected) {
            widget.onChange(value);
          }
        },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _getValidSelectedValue(Map<String, String> fontOptions) {
    if (fontOptions.containsKey(widget.selected)) {
      return widget.selected;
    }
    
    // אם הגופן הנבחר לא קיים (אולי נמחק), חזור לברירת מחדל
    return 'FrankRuhlCLM';
  }

  bool _shouldPreviewFont(String fontKey) {
    // הצג תצוגה מקדימה רק לגופנים מובנים ידועים
    final builtInFonts = FontUtils.getBuiltInFonts();
    return builtInFonts.containsKey(fontKey);
  }

  void _showRemoveConfirmation(BuildContext context, String fontId, String fontName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסרת גופן'),
        content: Text('האם אתה בטוח שברצונך להסיר את הגופן "$fontName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              widget.onRemoveCustomFont(fontId);
              // סגירת התפריט כדי לגרום לו להתעדכן
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('הסר'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, String fontId, String currentName) {
    final TextEditingController controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שינוי שם הגופן'),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            labelText: 'שם הגופן',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                Navigator.of(context).pop();
                widget.onRenameCustomFont?.call(fontId, newName);
                // סגירת התפריט כדי לגרום לו להתעדכן
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }
}