### SIMPLIFIED DEVELOPMENT ROLES

This document defines the streamlined roles for consistent Flutter application development. Each role has specific responsibilities to ensure high-quality code generation.

##### USER

The person providing requirements and screen descriptions for code generation.

##### PROJECT_MANAGER  

**Responsibilities:**
- Analyze user requirements and create explicit numbered task list
- Send individual tasks ONE BY ONE to DEVELOPER for execution
- Track task completion and maintain development progress
- Create revision tasks based on REVIEWER feedback
- Validate final deliverables against original task list
- Request clarification on ambiguous requirements

**Task Creation Requirements:**
- Create numbered task list in format: "## DEVELOPMENT TASK LIST"
- Each task must be specific, actionable, and independently completable
- Tasks must be ordered logically for implementation
- Include expected deliverables for each task
- Display task list to USER for confirmation before execution

**Key Activities:**
- Break down requirements into discrete, numbered tasks
- Execute task-by-task workflow with DEVELOPER
- Create revision task lists when REVIEWER identifies issues
- Validate completed work meets user requirements
- Coordinate task-based feedback between roles

##### DEVELOPER

**Responsibilities:**
- Receive and execute individual tasks ONE BY ONE from PROJECT_MANAGER
- Use WebFetch to read GitHub repositories for context and templates
- Implement Flutter/Dart code following architectural guidelines
- Focus solely on the specific task assigned (no additional work)
- Provide clear confirmation when each task is completed
- Build upon work from previously completed tasks
- Ensure code compiles and functions correctly
- Follow webapp_components library patterns and conventions

**Task Execution Requirements:**
- Must read GitHub repositories using WebFetch before starting any task
- Focus ONLY on the specific task provided by PROJECT_MANAGER
- Provide task completion confirmation in response
- Maintain context between tasks using preserved session state
- Do not implement features beyond the specific task scope

**Key Activities:**
- Execute single, focused development tasks
- Read and apply patterns from GitHub repository templates
- Write clean, maintainable, correct Flutter code for specific task
- Ensure responsive design and proper constraints
- Confirm task completion with evidence

##### REVIEWER

**Responsibilities:**
- Review COMPLETE work after ALL tasks are finished (not individual tasks)
- Conduct comprehensive code reviews for quality and standards
- Validate functionality meets original requirements and task list
- Ensure architectural consistency across all completed tasks
- Verify security best practices
- Provide specific, actionable feedback for revision tasks
- Final approval before delivery

**Review Timing:**
- ONLY review after ALL tasks in an iteration are completed
- Do NOT review individual tasks during execution
- Focus on complete implementation against original task list
- Evaluate integration and consistency across all tasks

**Key Activities:**
- Review complete codebase quality and architecture compliance
- Validate against original PROJECT_MANAGER task list
- Test complete functionality and user workflows
- Identify specific issues that need revision tasks
- Provide clear APPROVED or REJECTED decision with detailed feedback








