**CORE DEVELOPMENT REQUIREMENTS:**

✓ **Code Quality**: Code MUST compile without errors and pass `flutter analyze`
✓ **Widget Properties**: All Flutter widget properties must be valid (no invalid enums, properties)
✓ **Imports**: All imports must exist and be compatible
✓ **Error Handling**: Implement error handling for all async operations
✓ **Async Functions**: Prefix with 'fetch', 'load', 'get', or 'run' and place in *Service singletons, if one is not already available
✓ **Constructors**: Use const constructors where possible
✓ **Responsive Design**: Use Container with BoxConstraints, set min/max sizes
✓ **File Organization**: Each screen in separate file, widgets >100 lines separated
✓ **State Management**: Avoid nested StatefulBuilder, implement proper disposal
✓ **Component Integration**: Use  webapp_lib/webapp_commons library patterns
✓ **Model Usage**: Use sci_tercen_client as  webapp_lib/webapp_commons models. NEVER create view models.
✓ **Package Imports**: Import sci_client models with `import 'package:sci_tercen_client/sci_client.dart' as sci;`
✓ **Annotation**: Annotate/comment methods that contain mockup of Tercen service call . They should indicate exactly what is expected there. These comments MUST start with the //BACKDEV works.


**PROJECT CREATION**
When a new project must be created, follow the steps below:
1. Create the folder that will contain the project
2. Copy tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/main.dart@v2  to it
3. Copy tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/pubspec.yaml@v2 to it
4. Copy tercen/webapp_lib/webapp_commons/context/webapp_template/snippets/screens/home_screen.dart@v2 to it
5. DO NOT copy other tercen/webapp_lib files
6. Proceed with the remaining user instructions as needed.


**SCIENTIFIC USER EXPERIENCE**
✓ Provide clear feedback for long-running analysis workflows
✓ File validation must give user-friendly error messages
✓ Progress indicators for all operations > 1 second
✓ Tooltips for technical terms and scientific concepts
✓ Graceful degradation for slow network connections
✓ User-friendly error messages (avoid technical jargon)
✓ Accessibility features for users with disabilities

**STATE MANAGEMENT BEST PRACTICES**
✓ Avoid nested StatefulBuilder widgets - use main widget setState instead
✓ Ensure all interactive state changes are managed at the correct scope level
✓ Test that UI state changes (show/hide, enable/disable) work correctly
✓ Use proper widget keys for list items and dynamic content
✓ Dispose of all controllers, focus nodes, and subscriptions properly
✓ Verify that async operations don't cause setState after disposal
✓ Test all user interactions manually to ensure state flows work correctly
✓ Keep state management simple and predictable for scientific users

**MANDATORY COMPILATION & TESTING REQUIREMENTS**
✓ Code MUST compile without errors before submission
✓ All Flutter widget properties must be valid (no non-existent properties like Axis.both)
✓ Run flutter analyze to check for static analysis issues
✓ Verify all imports resolve correctly
✓ Check that all assets referenced actually exist or have proper fallbacks
✓ Ensure no runtime exceptions occur during normal operation

