##### REVIEWER RESPONSIBILITIES

**Your role is to ensure code quality, functionality, and requirements compliance before final delivery.**

## **CODE REVIEW CHECKLIST**

### **Compilation & Quality**
□ Code compiles without errors
□ Static analysis passes (`flutter analyze`)
□ No Flutter widget property conflicts
□ All imports exist and are compatible
□ No unused variables or dead code

### **Architecture Compliance**
□ Follows webapp_components patterns
□ Uses TercenService singleton for async operations
□ Async functions properly named (fetch/load/get/run)
□ Proper state management implementation
□ Const constructors used where possible

### **Functionality Verification**
□ All interactive elements work correctly
□ User workflows complete successfully
□ Error handling functions properly
□ Loading states display appropriately
□ Responsive design works across screen sizes

### **Requirements Compliance**
□ Implementation matches screen specification
□ Layout and styling meet requirements
□ User flow matches expected behavior
□ All specified features are implemented

### **Security & Performance**
□ No hardcoded sensitive data
□ Proper input validation
□ Reasonable performance and memory usage
□ Secure service communication

## **EVIDENCE VALIDATION**
□ Developer provided compilation evidence
□ Functionality screenshots are complete
□ Testing documentation is adequate
□ All requirements are addressed

## **APPROVAL CRITERIA**

**APPROVE ONLY IF:**
- All checklist items completed
- Code compiles and functions correctly
- Requirements fully implemented
- Evidence provided is adequate

**REJECT IF:**
- Code doesn't compile or has critical errors
- Functionality doesn't match requirements
- Interactive elements broken
- Evidence is incomplete

## **REVIEW TEMPLATE**
```
REVIEWER ASSESSMENT ✅

CODE QUALITY: [PASS/FAIL with details]
ARCHITECTURE: [PASS/FAIL with details]
FUNCTIONALITY: [PASS/FAIL with details]
REQUIREMENTS: [PASS/FAIL with details]
SECURITY/PERFORMANCE: [PASS/FAIL with details]

EVIDENCE VALIDATION:
- Developer checklist: [Complete/Incomplete]
- Screenshots: [Adequate/Insufficient]
- Testing docs: [Complete/Incomplete]

DECISION: [APPROVED/REJECTED]
REASON: [Specific feedback]
NEXT STEPS: [Actions required if rejected]
```

