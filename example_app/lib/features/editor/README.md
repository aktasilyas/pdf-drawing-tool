# Editor Feature

Drawing editor module that integrates DrawingScreen into the app.

## Architecture

```
editor/
├── domain/
│   └── usecases/
│       ├── load_document_usecase.dart    # Load document from storage
│       └── save_document_usecase.dart    # Save document to storage
├── presentation/
│   ├── providers/
│   │   └── editor_provider.dart          # Auto-save, document state
│   ├── screens/
│   │   └── editor_screen.dart            # Main editor screen
│   └── widgets/
│       └── pdf_export_dialog.dart        # PDF export dialog
└── editor.dart                           # Barrel export
```

## Features

### Document Loading
- Loads document metadata from DocumentRepository
- Deserializes drawing content from JSON
- Creates empty document for new documents

### Auto-Save
- 3-second debounce for auto-save
- Visual indicator for saving state
- Unsaved changes indicator

### Editor UI
- Full integration with DrawingScreen from drawing_ui
- Undo/Redo support
- Page navigation for multi-page documents
- Rename document
- PDF export (coming soon)
- Share (coming soon)

### Navigation
- Back button saves unsaved changes before exit
- Proper lifecycle management

## Usage

### Route
```dart
context.push('/editor/$documentId');
```

### Providers
```dart
// Load document
ref.watch(documentLoaderProvider(documentId));

// Current document state
ref.watch(currentDocumentProvider);

// Auto-save state
ref.watch(autoSaveProvider);

// Has unsaved changes
ref.watch(hasUnsavedChangesProvider);
```

## Dependencies

### Internal
- `features/documents` - Document repository and entities
- `packages/drawing_core` - Drawing document model
- `packages/drawing_ui` - DrawingScreen widget

### External
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `dartz` - Either for error handling

## Testing

Tests are located in `test/features/editor/`:
- Unit tests for use cases
- Widget tests for screens

Run tests:
```bash
flutter test test/features/editor
```

## Implementation Notes

1. **DrawingScreen Integration**: The editor uses DrawingScreen from drawing_ui package without modifications

2. **Content Storage**: Document content is stored separately from metadata in SharedPreferences with key `document_content_{id}`

3. **Auto-Save**: Uses debounce timer to avoid excessive saves during active editing

4. **Lifecycle**: Ensures unsaved changes are saved before navigation

## Future Enhancements

- [ ] PDF export integration
- [ ] Share functionality
- [ ] Collaborative editing
- [ ] Version history
- [ ] Templates support
