# Project Context: CheckListApp

## Overview

CheckListApp is a Flutter-based shopping list application developed as an MVP (Minimum Viable Product). The app allows users to create categorized shopping lists with collapsible sections, featuring smart item ordering and local persistence. While the initial planning document outlines ambitious AI-powered features for generating lists from nutritional plans, the current implementation is a focused checklist app without AI integration.

The project serves as an educational demonstration of Flutter development best practices, including clean architecture, state management with Provider, and local data persistence.

## Features

### Core Functionality
- **Categorized Shopping Lists**: Organize items into custom categories (e.g., "Mercearia", "Hortifruti") with a default "Sem categoria" section
- **Collapsible Categories**: Categories can be expanded/collapsed with animated chevron icons
- **Smart Item Ordering**: Unchecked items appear first (sorted by creation date), checked items move to the bottom (sorted by check date)
- **Visual Feedback**: Checked items display with strikethrough text, gray background, and green checkboxes
- **Local Persistence**: All data saved locally using SharedPreferences, persisting between app sessions

### User Interactions
- Add/remove categories and items via dialog forms
- Toggle item completion with automatic reordering
- Delete confirmation dialogs for safety
- Input validation preventing empty names
- Snackbar notifications for user feedback

### Technical Features
- Asynchronous data loading with loading indicators
- Error handling for data deserialization
- Immutable data models with copyWith methods
- Animated UI transitions for category collapse/expand

## Code Structure

The application follows a feature-based clean architecture pattern:

```
lib/
├── main.dart                          # App entry point, Provider setup
└── features/
    └── shopping_list/
        ├── models/                    # Data models
        │   ├── category.dart          # Category model (id, name, collapsed state)
        │   └── shopping_item.dart     # Item model (id, name, checked state, timestamps)
        │
        ├── data/                      # Data layer
        │   └── shopping_repository.dart  # SharedPreferences persistence
        │
        ├── state/                     # State management
        │   └── shopping_list_controller.dart  # Provider ChangeNotifier
        │
        ├── widgets/                   # Reusable UI components
        │   ├── category_header.dart   # Category header with collapse button
        │   ├── category_section.dart  # Complete category section with items
        │   └── shopping_item_tile.dart # Individual item tile with checkbox
        │
        └── screens/                   # Screen widgets
            └── shopping_list_screen.dart  # Main screen with list view
```

### Architecture Decisions
- **Provider Pattern**: Simple and native Flutter state management suitable for MVP scope
- **Repository Pattern**: Abstraction over SharedPreferences for data persistence
- **Feature-Based Organization**: Code organized by feature rather than technical layers
- **Immutable Models**: Data classes with proper equality and JSON serialization

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  shared_preferences: ^2.2.2 # Local data persistence
  cupertino_icons: ^1.0.8   # iOS-style icons

dev_dependencies:
  flutter_test: sdk: flutter
  flutter_lints: ^6.0.0     # Code linting
```

## Notable Implementations

### Smart Sorting Logic
The app implements intelligent item ordering in `ShoppingListController._sortItems()`:
- Unchecked items sorted by `createdAt` (chronological)
- Checked items sorted by `checkedAt` (order of completion)
- Combined list: `[unchecked..., checked...]`

### Timestamp-Based IDs
Uses `DateTime.now().millisecondsSinceEpoch.toString()` for unique IDs, suitable for MVP but noted for potential UUID replacement in production.

### Persistence Strategy
- JSON serialization of models for SharedPreferences storage
- Graceful error handling for corrupted data (returns empty lists)
- Automatic save on all state changes

### UI Animations
- `AnimatedRotation` for category collapse chevron
- `AnimatedSize` for smooth category expansion/collapse
- `AnimatedContainer` for item check state transitions

### Validation and UX
- Empty string validation with user feedback
- Confirmation dialogs for destructive actions
- Loading states during data initialization

## Future Roadmap (from Planning Document)

The planning document outlines advanced features not yet implemented:
- **AI Integration**: LLM processing of uploaded nutritional plans to auto-generate shopping lists
- **Inventory Management**: Track purchased items and calculate consumption
- **Voice Input**: Add items via speech recognition
- **Quantity Calculation**: Compute required amounts based on diet duration
- **Web Sharing**: Generate shareable links for collaborative shopping
- **Monetization**: Freemium model with credits for AI usage

## Development Notes

- **Testing**: Includes comprehensive unit tests for the controller focusing on sorting logic
- **Best Practices**: Follows Flutter guidelines with const constructors, proper key usage, and separation of concerns
- **Platform Support**: Cross-platform Flutter app supporting Android, iOS, Web, Linux, macOS, and Windows
- **Localization**: Currently Portuguese (Brazil), with potential for internationalization

This MVP demonstrates solid Flutter fundamentals while providing a foundation for the more complex AI-powered features outlined in the planning document.