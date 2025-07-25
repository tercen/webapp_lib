# Update-Specific Development Framework

## Overview

This framework is designed for **updating existing Flutter applications** built with the webapp_components library. It uses a streamlined 2-role process focused on maintaining existing functionality while implementing changes.

## Key Differences from New App Development

### Update Process (2 Roles)
- **DEVELOPER** - Analyzes existing code and implements changes
- **REVIEWER** - Verifies changes work and don't break existing functionality

### New App Process (3 Roles)  
- **PROJECT_MANAGER** - Requirements analysis and coordination
- **DEVELOPER** - Full implementation from scratch
- **REVIEWER** - Comprehensive quality assurance

## Update Process Files

### Core Process
- **UPDATE_ROLES.md** - 2-role structure for updates
- **update_process.puml** - Simplified update workflow diagram

### Development Guidelines
- **UPDATE_GUIDE.md** - Update-specific development requirements
- **UPDATE_CHECKLIST.md** - Developer submission checklist
- **UPDATE_REVIEWER_GUIDE.md** - Reviewer criteria for updates

## Process Focus Areas

### For Updates
✅ **Change Impact Analysis** - Understanding what's affected  
✅ **Regression Prevention** - Ensuring existing functionality works  
✅ **Pattern Consistency** - Following established code patterns  
✅ **Minimal Changes** - Making only necessary modifications  
✅ **Integration Testing** - Verifying new code works with existing  

### For New Apps
✅ **Full Architecture** - Complete system design  
✅ **Comprehensive Testing** - Testing everything from scratch  
✅ **Complete Implementation** - Building entire screens/features  
✅ **Full Documentation** - Complete project documentation  

## When to Use This Framework

**Use Update Framework For:**
- Adding new features to existing screens
- Modifying existing functionality
- Bug fixes and improvements
- UI/UX adjustments
- Performance optimizations

**Use New App Framework For:**
- Creating entirely new applications
- Building new screens from scratch
- Major architectural changes
- Complete rewrites

## Workflow Summary

**Update Process:**
```
USER (update request) → DEVELOPER (analyze & implement) → REVIEWER (verify & approve) → USER (delivered)
```

**Key Benefits:**
- Faster iteration cycles
- Focused on change impact
- Reduced bureaucratic overhead
- Maintains quality standards
- Prevents regressions

## Important: Model Usage

**ALL Tercen platform models (Project, ProjectDocument, User, Team, etc.) MUST be imported from the `sci_tercen_client` package:**

```dart
import 'package:sci_tercen_client/sci_client.dart' as sci;
import 'package:sci_tercen_client/sci_client_service_factory.dart' as tercen;
```

**DO NOT redefine these models in your Flutter application.** Refer to `webapp_commons/lib/` foundational example for proper integration patterns.