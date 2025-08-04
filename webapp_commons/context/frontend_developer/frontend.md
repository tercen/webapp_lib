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

# IMPORTANT CLARIFICATIONS

* DO NOT redefine classes defined in any of the imports, including https://github.com/tercen/webapp_lib and https://github.com/tercen/sci_tercen_client

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

When a new project must be created, follow the steps below:
1. Create the folder that will contain the project
2. Fetch  https://github.com/tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/main.dart@v2  from Github and add to the project
3. Fetch https://github.com/tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/pubspec.yaml@v2 from Github and add to the project
    3.1. This pubscpec file already contains the tercen_sci_client and webapp_lib dependencies.
4. Fetch https://github.com/tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/screens/home_screen.dart@v2 from Github and add to the project
5. DO NOT copy other https://github.com/tercen/webapp_lib files. do not copy any local files.
6. Proceed with the remaining user instructions as needed.


## Data Models

**Tercen Platform Models**
- Use sci_tercen_client package models and services directly
- DO NOT redefine Project, User, Team, etc.
- Example: `sci.Project project = sci.Project();`

**UI Utility Models**
- Use tercen/webapp_lib/webapp_commons@v2 IdLabel, TreeNode models and services directly
- DO NOT redefine IdNode, ApiService, etc
- Connectivity to Tercen platform already implemented in main.dart

## Performance & Testing

- Pagination for list views
- Image optimization and caching
- Mock service implementations for testing
- Use hardcoded data for UI development (simulate server timing)
- Centralized error handling using sci.ServiceError


