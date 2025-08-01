# Frontend Development Guidelines

## Core Requirements

**Code Quality & Compilation**
- Code MUST compile without errors and pass `flutter analyze`
- All Flutter widget properties must be valid
- All imports must exist and be compatible
- Run manual testing to verify functionality

**Architecture Principles**
- Single responsibility for services and components
- Separation of UI, business logic, and data access
- Use sci_client models - NEVER create view models
- Import sci_client: `import 'package:sci_tercen_client/sci_client.dart' as sci;`

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── screens/                     # UI screens (one per file)
├── widgets/                     # Reusable UI components  
├── services/                    # Service integrations
├── utils/                       # Utility functions
├── constants/                   # Application constants
└── config/                      # Environment configuration
```

## Development Standards

**Async Operations**
- Prefix with 'fetch', 'load', 'get', or 'run'
- Place in Service singletons
- Implement error handling for all async operations
- Annotate mockup service calls with `//BACKDEV`

**State Management**
- Avoid nested StatefulBuilder - use main widget setState
- Use const constructors where possible
- Dispose controllers, focus nodes, and subscriptions properly
- Keep state management simple and predictable

**UI & UX**
- Responsive design with Container/BoxConstraints min/max sizes
- Progress indicators for operations > 1 second
- User-friendly error messages (no technical jargon)
- Tooltips for technical terms
- File organization: separate files for screens, widgets >100 lines

## Project Creation Steps

1. Create project folder
2. Copy `tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/main.dart@v2`
3. Copy `tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/pubspec.yaml@v2`
4. Copy `tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/screens/home_screen.dart@v2`
5. DO NOT copy other tercen/webapp_lib files
6. Proceed with remaining instructions

## Data Models

**Tercen Platform Models**
- Use sci_tercen_client package models directly
- DO NOT redefine Project, User, Team, etc.
- Example: `sci.Project project = sci.Project();`

**UI Utility Models**
- Use webapp_commons IdLabel, TreeNode for UI-specific data
- Connectivity to Tercen platform already implemented in main.dart

## Performance & Testing

- Pagination for list views
- Image optimization and caching
- Mock service implementations for testing
- Use hardcoded data for UI development (simulate server timing)
- Centralized error handling using sci.ServiceError