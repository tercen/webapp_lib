##### UPDATE DEVELOPER CHECKLIST

**BEFORE SUBMITTING UPDATES, COMPLETE ALL ITEMS:**

## **PRE-UPDATE ANALYSIS**
□ Read and understood existing code structure
□ Identified all files that need modification
□ Mapped dependencies and integration points
□ Analyzed impact on existing functionality

## **IMPLEMENTATION VERIFICATION**
□ Code compiles without errors after changes
□ No new import errors or missing dependencies
□ Static analysis passes (`flutter analyze`)
□ Changes follow existing code patterns and style

## **FUNCTIONALITY TESTING**
□ New/modified features work as specified
□ All existing functionality still works (regression test)
□ Integration between new and existing code works properly
□ Error handling works correctly for changed areas

## **CODE QUALITY**
□ Changes are minimal and focused on requirements
□ Existing architectural patterns maintained
□ Uses established webapp_components patterns
□ Follows existing naming conventions

## **EVIDENCE DOCUMENTATION**
□ Before/after screenshots of changed functionality
□ List of modified files with brief explanations
□ Description of testing performed
□ Compilation success evidence

## **SUBMISSION TEMPLATE**
```
UPDATE DEVELOPER VERIFICATION COMPLETE ✅

PRE-UPDATE ANALYSIS:
- Files analyzed: [list key files reviewed]
- Impact assessment: [brief description]
- Dependencies identified: [list major dependencies]

IMPLEMENTATION:
- Files modified: [list all changed files]
- Changes made: [brief description of each change]
- Patterns followed: [existing patterns maintained]

TESTING PERFORMED:
- New functionality: [tested features]
- Regression testing: [existing features verified]
- Integration testing: [interaction points tested]

EVIDENCE PROVIDED:
- Before screenshots: [attached]
- After screenshots: [attached]
- Compilation proof: [attached]
- Testing summary: [brief description]

READY FOR REVIEWER: [YES/NO]
```

## **COMMON ISSUES TO AVOID**
- Making unnecessary changes to unrelated code
- Breaking existing functionality while adding new features
- Not following established patterns in the codebase
- Insufficient testing of integration points
- Missing documentation of what was changed