NAVIGATION MENU

Minimum height: 8% of SafeArea
Maximum height: 10% of SafeArea
Background color: white
Each element in the menu should have and padding of (10,10,10,10) - (left, bottom, right, top)

Icons must be 38px x 38px in size.

Selected icon color (selected icon = current screen) is foreground --white and background --purple.

Below each icon, there will be label in font size 11, following the same color scheme as the icons.

Navigation menu is separated from the main content area by a 1px light gray horizontal line.

MAIN CONTENT AREA

Background color: white
Vertically scrollable to acommodate all widgets. Scrollbar must always be visible.

TOOLTIP

Whenever a tooltip is mentioned, a small ? icon with a circle around must be placed to the right of the widget and the tooltip is displayed when the mouse hover over the icon. Tooltips must use simple, non-technical language accessible to data scientists and biologists with medium technological savviness.

LOADING & PROGRESS INDICATORS

Use the provided 'assets/img/wait.webp' for loading states (35px x 35px).
For long-running operations (>3 seconds), provide progress bars or percentage indicators.
For file uploads, show progress with file name and size information.
All progress indicators must be clearly visible and informative.

ACCESSIBILITY FEATURES

Ensure sufficient color contrast for users with visual impairments.
Provide keyboard navigation support for all interactive elements.
Use semantic HTML elements and proper ARIA labels.
Error messages must be clearly visible and screen reader accessible.
Focus indicators must be clearly visible for keyboard navigation.


FOOTER

Maximum height: 6% of SafeArea
Background color: white
Text Style: footTextStyle

The footer contain a Row of Text, all left aligned: APP_NAME (APP_VERSION) SPACE PROJECT SPACE USER (TEAM)
1) APP_NAME and APP_VERSION are the corresponding name and version from pubspec.yaml
2) SPACE is a 20px space
3) PROJECT : get this information from a fetchProject method in tercen_service.dart (return project_name, for now)
4) USER : get this information from a fetchUser method in tercen_service.dart (return user_name, for now)
5) TEAM : get this information from a fetchTeam method in tercen_service.dart (return team_name, for now)

ERROR HANDLING DISPLAY

Error messages must be user-friendly and avoid technical jargon.
Use clear, actionable language (e.g., "Please select a PDF file" instead of "File type validation failed").
Network errors should suggest retry actions or checking internet connection.
File upload errors should specify size limits and supported formats.
Long-running operation failures should preserve user work and offer recovery options.