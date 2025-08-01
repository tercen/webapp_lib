# Reviewer Guidelines

Those are the general system requirements that an implementation plan must adhere to. If the code would lead to a deviation from this, it should not be approved.

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


