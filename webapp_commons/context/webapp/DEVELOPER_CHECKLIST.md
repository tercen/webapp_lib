##### DEVELOPER SUBMISSION CHECKLIST

**BEFORE SUBMITTING CODE, COMPLETE ALL ITEMS:**

## **MANDATORY FILES (AUTOMATIC REJECTION IF MISSING)**
□ **lib/main.dart exists and is copied/modified from snippets/main.dart**
□ **pubspec.yaml exists with all required dependencies**
□ **All screen files exist as specified in requirements**

## **MANDATORY TEMPLATE USAGE (FAILURE = REJECTION)**
□ **Imports webapp_commons where necessary**
□ **Templates adapted to fulfill specific requirements while maintaining core structure**

## **COMPILATION VERIFICATION**
□ Code compiles without errors (`flutter run --debug`)
□ No import errors or missing dependencies
□ Static analysis passes (`flutter analyze`)
□ All Flutter widget properties are valid

## **FUNCTIONALITY VERIFICATION**
□ All user interactions work (buttons, inputs, dropdowns)
□ Navigation and state management function correctly
□ Loading states display properly
□ Error handling works as expected

## **DESIGN COMPLIANCE**
□ Layout matches screen specification
□ Responsive design works at different screen sizes

## **CODE QUALITY**
□ Follows naming conventions (async functions: fetch/load/get/run)
□ Uses const constructors where possible
□ Proper disposal of controllers/streams
□ Separates business logic from UI code


**SUBMISSION TEMPLATE:**
```
DEVELOPER VERIFICATION COMPLETE ✅

COMPILATION: [PASS/FAIL]
FUNCTIONALITY: [PASS/FAIL - tested: buttons, inputs, navigation]
DESIGN: [PASS/FAIL - responsive: yes/no]
CODE QUALITY: [PASS/FAIL]

READY FOR REVIEWER: [YES/NO]
```