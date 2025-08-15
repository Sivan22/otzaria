# Personal Notes System - User Guide

## Introduction

The Personal Notes System allows you to create, manage, and organize personal notes attached to specific text locations in your books. Your notes automatically stay connected to the text even when the book content changes.

## Getting Started

### Creating Your First Note

1. **Select Text**: Highlight any text in a book by clicking and dragging
2. **Add Note**: Right-click and select "הוסף הערה" (Add Note) from the context menu
3. **Write Content**: Enter your note content in the dialog that appears
4. **Add Tags** (optional): Add tags to organize your notes
5. **Set Privacy** (optional): Choose between Private or Shared
6. **Save**: Click "שמור" (Save) to create your note

### Viewing Your Notes

#### Notes Sidebar
- Click the notes icon in the toolbar to open the notes sidebar
- View all notes for the current book
- Search through your notes using the search box
- Sort notes by date, status, or relevance
- Filter notes by status (anchored, shifted, orphan)

#### Text Highlights
- Notes appear as colored highlights in the text
- **Green**: Anchored notes (exact original location)
- **Orange**: Shifted notes (moved due to text changes)
- **Red**: Orphan notes (cannot find suitable location)

### Managing Notes

#### Editing Notes
1. Click on a note in the sidebar or right-click a highlighted note
2. Select "ערוך" (Edit) from the menu
3. Modify the content, tags, or privacy settings
4. Click "שמור" (Save) to update the note

#### Deleting Notes
1. Right-click on a note or use the menu in the sidebar
2. Select "מחק" (Delete)
3. Confirm the deletion in the dialog

#### Organizing with Tags
- Add tags when creating or editing notes
- Use tags to categorize your notes (e.g., "חשוב", "לימוד", "שאלות")
- Search by tags using the format `#tag-name`

## Advanced Features

### Searching Notes

#### Basic Search
- Type your search query in the sidebar search box
- Search works in both Hebrew and English
- Results are ranked by relevance

#### Advanced Search Syntax
- **Exact phrases**: Use quotes `"exact phrase"`
- **Tags**: Use hashtag `#important`
- **Exclude terms**: Use minus `-unwanted`
- **Filters**: Use `status:orphan` or `privacy:private`

#### Search Examples
- `תורה` - Find notes containing "תורה"
- `"פרק ראשון"` - Find exact phrase "פרק ראשון"
- `#חשוב` - Find notes tagged with "חשוב"
- `לימוד -בחינה` - Find "לימוד" but exclude "בחינה"

### Handling Text Changes

#### Note Status Types
- **Anchored (מעוגן)**: Note is at its exact original location
- **Shifted (זז)**: Note moved to a new location due to text changes
- **Orphan (יתום)**: Note cannot find a suitable location

#### Orphan Notes Management
1. Open the Orphan Manager from the sidebar menu
2. Select an orphan note from the list
3. Review suggested anchor locations
4. Choose the best match or delete the note

### Import and Export

#### Exporting Notes
1. Go to Settings → Notes → Export
2. Choose which notes to export:
   - All notes or specific book
   - Include/exclude private notes
   - Include/exclude orphan notes
3. Select export location
4. Click "ייצא" (Export)

#### Importing Notes
1. Go to Settings → Notes → Import
2. Select the JSON file to import
3. Choose import options:
   - Overwrite existing notes
   - Target book (optional)
4. Click "ייבא" (Import)

## Tips and Best Practices

### Creating Effective Notes

1. **Select Meaningful Text**: Choose text that clearly identifies the location
2. **Write Clear Content**: Make your notes understandable for future reference
3. **Use Consistent Tags**: Develop a tagging system that works for you
4. **Keep Notes Focused**: One main idea per note works best

### Organizing Your Notes

1. **Use Descriptive Tags**: Tags like "שאלות", "חשוב", "לחזור" help organization
2. **Regular Cleanup**: Periodically review and delete outdated notes
3. **Export Regularly**: Create backups of important notes

### Performance Tips

1. **Limit Notes per Book**: Keep under 1000 notes per book for best performance
2. **Use Visible Range**: The system only processes notes in the visible area
3. **Clear Cache**: If performance degrades, clear the cache in settings
4. **Monitor Health**: Check the performance dashboard occasionally

## Troubleshooting

### Common Issues

#### Notes Not Appearing
- **Check Book ID**: Ensure you're viewing the correct book
- **Refresh**: Try closing and reopening the book
- **Clear Cache**: Go to Settings → Notes → Clear Cache

#### Slow Performance
- **Too Many Notes**: Consider archiving old notes
- **Clear Telemetry**: Go to Performance Dashboard → Clear Metrics
- **Run Optimization**: Use the automatic optimization feature

#### Orphan Notes
- **Use Orphan Manager**: Access via sidebar menu
- **Review Candidates**: Check suggested anchor locations
- **Consider Deletion**: Remove notes that are no longer relevant

#### Search Not Working
- **Check Spelling**: Verify search terms are correct
- **Try Different Terms**: Use synonyms or related words
- **Rebuild Index**: Run performance optimization

### Getting Help

1. **Performance Dashboard**: Check system health and metrics
2. **Telemetry Data**: Review performance statistics
3. **Error Messages**: Read error messages carefully for guidance
4. **Cache Statistics**: Monitor memory usage and cache efficiency

## Keyboard Shortcuts

### General
- `Ctrl+N`: Create new note (when text is selected)
- `Ctrl+F`: Focus search box in sidebar
- `Ctrl+E`: Edit selected note
- `Ctrl+D`: Delete selected note

### Orphan Manager
- `↑/↓`: Navigate between candidates
- `Enter`: Accept selected candidate
- `Esc`: Cancel and return to list

### Sidebar
- `Ctrl+1`: Sort by date (newest first)
- `Ctrl+2`: Sort by date (oldest first)  
- `Ctrl+3`: Sort by status
- `Ctrl+4`: Sort by relevance

## Privacy and Data

### Data Storage
- All notes are stored locally in SQLite database
- No data is sent to external servers
- Notes are not encrypted (by design for simplicity)

### Privacy Levels
- **Private**: Only visible to you
- **Shared**: Can be shared with others (future feature)

### Data Export
- Export creates JSON files with all note data
- Exported files are not encrypted
- Include only the data you choose to export

## Advanced Configuration

### Performance Tuning

```dart
// Adjust batch sizes for your system
SmartBatchProcessor.instance.setBatchSizeLimits(
  minSize: 10,
  maxSize: 100,
);

// Enable/disable features
NotesConfig.fuzzyMatchingEnabled = true;
NotesConfig.telemetryEnabled = false;
```

### Text Normalization

```dart
// Configure text normalization
final config = NormalizationConfig(
  removeNikud: false,  // Keep Hebrew vowel points
  quoteStyle: 'ascii', // Normalize quotes to ASCII
  unicodeForm: 'NFKC', // Unicode normalization form
);
```

This user guide covers all the essential features and functionality of the Personal Notes System. For technical details and API documentation, see the API Reference.