SCREEN DESCRIPTION: Project setup screen where users select or create a project and choose their team before starting analysis workflows.

FILENAME screens/home_screen.dart

NAVIGATION: Home icon from material library, label "Home"

USER FLOW: User enters/selects project name → selects team → loads project to begin analysis work

INIT

When loading the page, call fetchProjects and store for later use. For now, use [{id:"1", "name":"Project 1"}, {id:"2", "name":"Project 1 v2"}, {id:"3", "name":"Project 1 v2.1"}, {id:"4", "name":"Second project"}]. Create a class named Project with these fields, if it doesn't exist. Then, call fetchTeams and store for later use. For now, the function should return [{"name":"teamA"}, {"name":"teamB"}]. Create a class named Team with these fields, if it doesn't exist.

Set currently selected team as the first of the team List.

LAYOUT
First column minimum width: 10% of Main content area, Maximum 12%, left aligned
Second column maximum width: 25% of Main content area, left aligned
Third column maximum width: Remainder

All rows center aligned

WIDGETS

Column 1, Row 1
Text label: Project. Style: labelStyle. Tooltip: If project name does not exist, a new one will be created.

Column 2, Row 1
Text input. Hint: "Project Name". When the user types in the field, show autocomplete suggestions based on the available projects. When the user clicks on a project, populate the text field with it and close the autosuggestion box.

Column 3, Row 1
Empty

Column 1, Row 2
Text label: Team. Style: labelStyle. 

Column 2, Row 2
Show a text of the currently selected team. To the right of this text, add an icon of multiple people. When clicked, display a dialog with a search box at the top and the list of teams beneath it. When the user clicks on a team, close the dialog and update the selected team field.

Column 3, Row 2
Empty

Column 1, Row 3
A button with 'Load Project' label. When the button is pressed, if the project does not exist in the available projects, open a pop up with the message "This will create a new project" and two action options, "Create" and "Cancel". If the user press Create (or the project already exists), open a popup progress dialog with the message 'Setting up Project". Once the processing is done, close the dialog and proceed to the analysis workflow. Style: buttonStyle. 

Column 2 and 3, Row 3
Empty