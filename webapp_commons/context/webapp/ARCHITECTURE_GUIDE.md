##### ARCHITECTURE_GUIDE

Your task is to design system architecture, ensure proper integration with Tercen platform services, and maintain architectural consistency across bespoke data science applications.

**MANDATORY ARCHITECTURE PRINCIPLES**

✓ Single responsibility principle for each service and component
✓ Separation of concerns between UI, business logic, and data access
✓ Dependency injection for testability and flexibility
✓ Event-driven architecture for loose coupling
✓ Consistent error handling patterns across all layers
✓ Scalable folder structure for multiple lab variations
✓ Configuration-driven customization for different deployments

**FLUTTER APPLICATION STRUCTURE**

```
lib/
├── main.dart                    # Application entry point
├── models/                      # Data models and entities
├── screens/                     # UI screens (one per file)
├── widgets/                     # Reusable UI components
├── services/
│   ├── tercen_service.dart     # gRPC/MCP communication layer
│   └── [other_services].dart   # Additional service integrations
├── utils/                      # Utility functions and helpers
├── constants/                  # Application constants
└── config/                     # Environment configuration
```

**TERCEN SERVICE ARCHITECTURE**

✓ Singleton pattern for TercenService class
✓ All async operations prefixed with 'fetch', 'load', 'get', or 'run'
✓ Centralized error handling and logging
✓ Service layer abstraction over platform communication (gRPC, REST, etc.)
✓ Connection pooling and resource management
✓ Retry mechanisms for network failures
✓ Request/response caching where appropriate
✓ Timeout configurations for all operations
✓ Health check and connectivity monitoring

**TERCEN PLATFORM INTEGRATION PATTERNS**

✓ Service discovery and endpoint configuration
✓ Authentication token management
✓ Request/response serialization handling
✓ Stream processing for large data transfers
✓ Connection lifecycle management
✓ Error mapping from platform services to Flutter exceptions
✓ Metadata handling for tracing and monitoring
✓ Load balancing and failover configuration

**TERCEN PLATFORM SERVICE INTEGRATION**

✓ Service interface definitions maintained
✓ Method call abstraction in TercenService
✓ API capability discovery and versioning
✓ Resource management for platform connections
✓ Event handling for server-side notifications
✓ Version compatibility checking
✓ Graceful fallback mechanisms for connectivity issues

**DATA FLOW ARCHITECTURE**

✓ Unidirectional data flow from UI to services
✓ State management centralized (Provider/Bloc pattern)
✓ Reactive programming for real-time updates
✓ Data transformation layers for API responses
✓ Caching strategies for frequently accessed data
✓ Offline capability considerations
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

✓ Lazy loading for large datasets
✓ Pagination for list views
✓ Image optimization and caching
✓ Bundle splitting for code optimization
✓ Memory management for large file processing
✓ Background task processing
✓ Progressive loading indicators

**SECURITY ARCHITECTURE**

✓ Authentication flow design
✓ Authorization pattern implementation
✓ Secure token storage and refresh
✓ API key management
✓ Data encryption at rest and in transit
✓ Input validation architecture
✓ Audit logging integration

**TESTING ARCHITECTURE**

✓ Mock service implementations
✓ Test data management strategies
✓ Integration test patterns
✓ Performance testing framework
✓ Security testing integration
✓ Automated testing pipeline design
✓ Test environment provisioning

**DEPLOYMENT ARCHITECTURE**

✓ Containerization strategy
✓ Environment configuration management
✓ CI/CD pipeline design
✓ Monitoring and observability setup
✓ Logging aggregation patterns
✓ Health check implementations
✓ Rollback procedures

**EXTENSIBILITY PATTERNS**

✓ Plugin architecture for custom analyses
✓ Hook system for workflow customization
✓ Configuration-driven UI generation
✓ Dynamic form generation
✓ Custom widget registration
✓ Theme and styling extensibility