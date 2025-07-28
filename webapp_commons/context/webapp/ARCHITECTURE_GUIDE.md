##### ARCHITECTURE_GUIDE

Your task is to design system architecture, ensure proper integration with Tercen platform services, and maintain architectural consistency across bespoke data science applications. You inform the developer and reviewer of the expected architecture.

**MANDATORY ARCHITECTURE PRINCIPLES**

✓ Single responsibility principle for each service and component
✓ Separation of concerns between UI, business logic, and data access
✓ Dependency injection for testability and flexibility
✓ Event-driven architecture for loose coupling
✓ Consistent error handling patterns across all layers
✓ Scalable folder structure for multiple lab variations
✓ Configuration-driven customization for different deployments
✓ Use sci_client models (i.e. do not redefine them in the flutter project)


**FLUTTER APPLICATION STRUCTURE**

```
lib/
├── main.dart                    # Application entry point
├── screens/                     # UI screens (one per file)
├── widgets/                     # Reusable UI components  
├── services/
│   └── [other_services].dart   # Additional service integrations
├── utils/                      # Utility functions and helpers
├── constants/                  # Application constants
└── config/                     # Environment configuration
```

**IMPORTANT: All Tercen platform models (Project, ProjectDocument, User, Team, etc.) are provided by the `sci_tercen_client` package. DO NOT redefine these models in your Flutter application. Import and use them directly:**

```dart
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;

// Use sci_client models directly
sci.Project project = sci.Project();
sci.ProjectDocument document = sci.ProjectDocument();
sci.User user = sci.User();
```

**Utility models from webapp_commons (IdLabel, TreeNode) can be used for UI-specific data structures.**

**TERCEN SERVICE ARCHITECTURE**

✓ All async operations prefixed with 'fetch', 'load', 'get', or 'run'
✓ Server Async Functions are part of *Service classes in the webapp_commons package
✓ Centralized error handling and logging
✓ Retry mechanisms for network failures
✓ Request/response caching where appropriate
✓ Timeout configurations for all operations
✓ Health check and connectivity monitoring
✓ Connectivity to the Tercen platform (via token) is already implemented in the main.dart snippet. DO NOT redefine it


**DATA FLOW ARCHITECTURE**

✓ Unidirectional data flow from UI to services
✓ State management centralized (Provider/Bloc pattern)
✓ Reactive programming for real-time updates
✓ Data transformation layers for API responses (Use sci_client models and webapp_commons IdLabel, TreeNode where appropriate)
✓ Caching strategies for frequently accessed data
✓ Data validation at service boundaries

**LONG-RUNNING WORKFLOW ARCHITECTURE**

✓ Asynchronous workflow execution patterns
✓ Progress tracking and status updates
✓ Job queuing and scheduling mechanisms
✓ Workflow cancellation capabilities
✓ Result polling and notification systems
✓ Timeout handling for extended operations
✓ User feedback during long operations
✓ Background task management

**PERFORMANCE ARCHITECTURE**
✓ Pagination for list views
✓ Image optimization and caching
✓ Bundle splitting for code optimization
✓ Memory management for large file processing
✓ Background task processing
✓ Progressive loading indicators


**TESTING ARCHITECTURE**
✓ Mock service implementations if one cannot be found


**EXTENSIBILITY PATTERNS**

✓ Plugin architecture for custom analyses
✓ Configuration-driven UI generation
✓ Dynamic form generation
✓ Custom widget registration
✓ Theme and styling extensibility