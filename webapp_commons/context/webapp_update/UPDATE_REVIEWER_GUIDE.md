##### UPDATE REVIEWER GUIDE

**Your role is to ensure updates are implemented correctly without breaking existing functionality.**

## **UPDATE REVIEW CHECKLIST**

### **Change Analysis**
□ Requirements clearly implemented
□ Changes are focused and minimal
□ No unnecessary modifications to unrelated code
□ All specified features/fixes are addressed

### **Code Quality Review**
□ Code compiles without errors
□ Static analysis passes cleanly
□ Changes follow existing code patterns and architecture
□ Maintains consistency with existing codebase style

### **Integration Verification**
□ New code integrates properly with existing components
□ Uses established webapp_components patterns correctly
□ Follows existing TercenService patterns
□ State management remains consistent

### **Functionality Testing**
□ New/modified features work as specified
□ All existing functionality still works (no regressions)
□ Error handling works correctly
□ User workflows complete successfully

### **Evidence Validation**
□ Developer provided adequate before/after documentation
□ Testing evidence demonstrates functionality works
□ Compilation proof provided
□ Change documentation is clear and complete

## **REGRESSION TESTING FOCUS**

### **Critical Areas to Test**
□ **Navigation**: Existing navigation still works
□ **State Management**: Data persistence and updates work
□ **Service Integration**: API calls and data fetching function
□ **User Workflows**: End-to-end processes complete successfully
□ **UI Components**: Existing UI elements display and function correctly

### **Integration Points**
□ **Component Dependencies**: Changes don't break dependent components
□ **Shared Services**: TercenService singleton still functions correctly
□ **Event Handling**: Existing event flows work properly
□ **Data Flow**: Information flows correctly between components

## **APPROVAL CRITERIA**

### **APPROVE ONLY IF:**
- Requirements are fully implemented
- No regressions in existing functionality
- Code quality meets established standards
- Changes integrate properly with existing code
- Adequate evidence provided

### **REJECT IF:**
- Any existing functionality is broken
- Changes don't meet specified requirements
- Code quality is inconsistent with existing standards
- Integration issues present
- Insufficient evidence provided

## **REVIEW TEMPLATE**

```
UPDATE REVIEWER ASSESSMENT ✅

CHANGE ANALYSIS:
- Requirements implementation: [PASS/FAIL with details]
- Change scope: [Appropriate/Too broad]
- Focus: [Targeted/Scattered]

CODE QUALITY:
- Compilation: [PASS/FAIL]
- Pattern consistency: [PASS/FAIL]
- Architecture compliance: [PASS/FAIL]

FUNCTIONALITY VERIFICATION:
- New features: [PASS/FAIL with details]
- Regression testing: [PASS/FAIL - existing features tested]
- Integration: [PASS/FAIL with details]

EVIDENCE VALIDATION:
- Documentation: [Complete/Incomplete]
- Testing proof: [Adequate/Insufficient]
- Change description: [Clear/Unclear]

REGRESSION TESTING PERFORMED:
- Navigation: [PASS/FAIL]
- State management: [PASS/FAIL]
- Service integration: [PASS/FAIL]
- User workflows: [PASS/FAIL]

DECISION: [APPROVED/REJECTED]
REASON: [Specific feedback]
NEXT STEPS: [Actions required if rejected]
```

## **COMMON REJECTION REASONS**

- **Functionality Broken**: Existing features no longer work
- **Requirements Not Met**: Changes don't address specified requirements
- **Poor Integration**: New code doesn't integrate well with existing
- **Quality Issues**: Code doesn't meet established standards
- **Insufficient Testing**: Evidence doesn't demonstrate adequate testing
- **Scope Creep**: Unnecessary changes made beyond requirements