### UPDATE-SPECIFIC DEVELOPMENT ROLES

This document defines the streamlined 2-role process for updating existing Flutter applications. Updates focus on modifying existing functionality, adding features, or fixing issues.

##### USER

The person providing update requirements, specifying what needs to be changed, added, or fixed in the existing application.

##### DEVELOPER

**Responsibilities:**
- Analyze existing code to understand current implementation
- Implement requested changes following established patterns
- Ensure changes don't break existing functionality
- Test modifications thoroughly
- Provide evidence of working changes

**Mandatory Requirements:**
- **Impact Analysis**: Identify all files and components affected by the change
- **Code Compatibility**: Ensure changes follow existing code patterns and architecture
- **Regression Prevention**: Verify existing functionality still works
- **Testing**: Test both new functionality and existing features that might be affected
- **Documentation**: Document what was changed and why

**Key Activities:**
- Read and understand existing codebase structure
- Implement changes using established webapp_components patterns
- Perform focused testing on changed areas
- Verify no regressions in existing functionality
- Provide clear before/after evidence

##### REVIEWER

**Responsibilities:**
- Verify changes meet requirements without breaking existing functionality
- Ensure code quality and consistency with existing codebase
- Validate that changes follow established patterns
- Test integration with existing features
- Final approval for deployment

**Mandatory Requirements:**
- **Regression Testing**: Verify existing functionality still works
- **Integration Verification**: Ensure new changes integrate properly
- **Code Consistency**: Changes follow existing architectural patterns
- **Requirements Validation**: Changes meet specified requirements
- **Quality Standards**: Code maintains established quality levels

**Key Activities:**
- Review code changes for quality and consistency
- Test both new and existing functionality
- Verify no breaking changes introduced
- Validate requirements are fully met
- Approve or reject with specific feedback

## UPDATE WORKFLOW

**Simplified 2-Role Process:**
USER → DEVELOPER → REVIEWER → USER

**Focus Areas:**
- **Change Impact**: Understanding what's affected
- **Compatibility**: Maintaining existing functionality
- **Quality**: Following established patterns
- **Testing**: Focused regression testing