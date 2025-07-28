##### UPDATE DEVELOPMENT GUIDE

**This guide is for modifying existing Flutter applications built with webapp_components library.**

## **STEP 0: ACKNOWLEDGE UPDATE TASKS AND REPORT PROGRESS**

Before starting any updates, you MUST:
- Acknowledge the specific update tasks you will complete
- List them in order of execution
- State which task you are currently working on  
- Report progress as you complete each task

Example format:
```
UPDATE TASK ACKNOWLEDGMENT:
I will complete the following update tasks in order:
1. [Update task 1 description]
2. [Update task 2 description]
3. [Update task 3 description]

CURRENT STATUS: Working on Task 1 - [brief description]
PROGRESS: 0/3 update tasks completed
```

**PROGRESS REPORTING REQUIREMENT:**
Throughout updates, provide status updates using this format:
```
CURRENT STATUS: Working on [current update task]
PROGRESS: X/Y update tasks completed
NEXT: [what you will do next]
```

## **PRE-UPDATE ANALYSIS**

### **Understand Existing Code**
✓ **Read Current Implementation**: Thoroughly understand existing code structure
✓ **Identify Dependencies**: Map out which components/files will be affected
✓ **Review Existing Patterns**: Follow established coding patterns in the codebase
✓ **Check Integration Points**: Understand how changes will affect other parts

### **Impact Assessment**
✓ **File Analysis**: List all files that need modification
✓ **Component Dependencies**: Identify which components depend on changed code
✓ **State Management**: Understand current state flow and how changes affect it
✓ **Service Integration**: Check how changes affect TercenService calls

## **CORE UPDATE REQUIREMENTS**

### **Code Quality Standards**
✓ **Compilation**: Code MUST compile without errors after changes
✓ **Existing Patterns**: Follow established patterns already in the codebase
✓ **Component Integration**: Use existing webapp_components patterns
✓ **Architecture Consistency**: Maintain consistency with current architecture

### **Change Implementation**
✓ **Minimal Impact**: Make smallest changes necessary to achieve requirements
✓ **Backward Compatibility**: Ensure existing functionality continues to work
✓ **Error Handling**: Maintain or improve existing error handling
✓ **State Consistency**: Ensure state management remains consistent

### **Testing Requirements**
✓ **Changed Functionality**: Test all modified features thoroughly
✓ **Regression Testing**: Verify existing features still work
✓ **Integration Testing**: Test interaction between new and existing code
✓ **Edge Cases**: Test edge cases that might be affected by changes

## **UPDATE-SPECIFIC PRACTICES**

### **Code Modification**
✓ **Read Before Writing**: Always read and understand existing code first
✓ **Preserve Structure**: Maintain existing file and folder structure
✓ **Consistent Styling**: Match existing code style and formatting
✓ **Comment Changes**: Document significant changes with clear comments

### **Service Integration**
✓ **TercenService Pattern**: Use existing TercenService singleton pattern
✓ **Async Conventions**: Follow existing async function naming (fetch/load/get/run)
✓ **Error Patterns**: Use existing error handling patterns
✓ **State Updates**: Follow existing state update patterns
✓ **Model Usage**: Use sci_tercen_client models (Project, ProjectDocument, User, Team, etc.) - DO NOT redefine them

### **Component Updates**
✓ **webapp_components**: Use existing component library patterns
✓ **Widget Consistency**: Maintain consistency with existing widget usage
✓ **Layout Patterns**: Follow existing layout and styling patterns
✓ **Event Handling**: Use existing event handling approaches

## **EVIDENCE REQUIREMENTS**

### **Before/After Documentation**
✓ **Current State**: Screenshot/description of current functionality
✓ **Changes Made**: Clear description of what was modified
✓ **New State**: Screenshot/description of updated functionality
✓ **Files Modified**: List of all files changed with brief explanation

### **Testing Evidence**
✓ **Functionality Test**: Evidence that new/changed features work
✓ **Regression Test**: Evidence that existing features still work
✓ **Integration Test**: Evidence that changes integrate properly
✓ **Compilation Proof**: Screenshot showing successful compilation

## **COMMON UPDATE SCENARIOS**

### **Adding New Features**
- Add new components following existing patterns
- Integrate with existing state management
- Ensure new features don't conflict with existing ones

### **Modifying Existing Features**
- Understand current implementation thoroughly
- Make minimal necessary changes
- Preserve existing behavior where not explicitly changed

### **Bug Fixes**
- Identify root cause of issue
- Fix with minimal code changes
- Verify fix doesn't introduce new issues

### **UI/Layout Updates**
- Follow existing styling patterns
- Maintain responsive design principles
- Ensure consistency with existing UI elements