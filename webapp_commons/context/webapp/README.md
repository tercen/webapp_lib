# Streamlined Development Framework

## Essential Files (Active)

### Core Process Files
- **ROLES.md** - Simplified 3-role development structure (PROJECT_MANAGER, DEVELOPER, REVIEWER)
- **development.puml** - Streamlined workflow diagram
- **CONTEXT.md** - Project mission and Tercen platform context

### Development Guidelines  
- **ARCHITECTURE_GUIDE.md** - Technical architecture and Flutter patterns
- **DEVELOPER_GUIDE.md** - Core development requirements and conventions
- **DEVELOPER_CHECKLIST.md** - Simple submission checklist for developers
- **REVIEWER_GUIDE.md** - Code review criteria and approval process

### UI/Layout Specifications
- **LAYOUT_DESCRIPTION.md** - App layout structure and grid system
- **STYLE_DESCRIPTION.md** - Navigation, styling, and visual guidelines
- **layout.png** / **layout.svg** - Visual layout references
- **styles.dart** - Styling implementations

### Example Specifications
- **SCREEN_1.md** - Example screen specification (project setup)
- **SCREEN_2.md** - Additional screen example
- **snippets.md** - Useful code snippets for development

### Agent Tools
- **agents/** - Helper agents and tools

## Deprecated Files (Moved to deprecated/)

### Overly Complex Verification Systems
- **DEVELOPER_VERIFICATION_CHECKLIST.md** - Replaced by simplified DEVELOPER_CHECKLIST.md
- **UIX_VERIFICATION_CHECKLIST.md** - UI/UX testing now part of REVIEWER role
- **TESTER_VERIFICATION_CHECKLIST.md** - Testing integrated into DEVELOPER/REVIEWER roles
- **VERIFICATION_ARTIFACTS_GUIDE.md** - Excessive documentation requirements
- **VERIFIER.md** - Redundant verification role

### Specialized Guides (Consolidated)
- **TESTING_GUIDE.md** - Basic testing now in DEVELOPER_GUIDE.md
- **SECURITY_GUIDE.md** - Security checks now in REVIEWER_GUIDE.md  
- **PERFORMANCE_GUIDE.md** - Performance considerations integrated
- **development.txt** - Replaced by development.puml

## Process Summary

**3 Essential Roles:**
1. **PROJECT_MANAGER** - Requirements analysis and coordination
2. **DEVELOPER** - Implementation with basic testing and compilation verification
3. **REVIEWER** - Final quality assurance and approval

**Streamlined Flow:**
USER → PROJECT_MANAGER → DEVELOPER → REVIEWER → PROJECT_MANAGER → USER

This simplified framework maintains code quality while eliminating bureaucratic overhead, ensuring consistent Flutter app generation across different LLM sessions.

## Important: Model Usage

**ALL Tercen platform models (Project, ProjectDocument, User, Team, etc.) MUST be imported from the `sci_tercen_client` package:**

```dart
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
```

**DO NOT redefine these models in your Flutter application.** Use the foundational example in `webapp_commons/lib/` as a reference for proper integration patterns.