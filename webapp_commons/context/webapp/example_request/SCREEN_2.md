SCREEN DESCRIPTION: This is where the user sees the images generated in an analysis steps and can inspect them. This will replace the current api_screen.dart, if exists

FILENAME screens/result_screen.dart. 

NAVIGATION: Api icon from material library, label "Results"

USER FLOW: User select from a list of analysis -> Images are displayed -> User can click on an image for a popup zoom in.

INIT

When loading the page, call fetchProjectObjects and store for later use. For now, use [{id:"1", "name":"Analyses", parentId: null}, {id:"2", "name":"Folder 1", parentId:"1"}, {id:"3", "name":"Folder 2", parentId:"1"}, {id:"4", "name":"Analysis 1", parentId:"2"}, {id:"5", "name":"Analysis 2.1", parentId:"3"}, {id:"6", "name":"Analysis 2.2", parentId:"3"}. Create a class named ProjectObject with these fields, if it doesn't exist. 


LAYOUT
First column minimum width: 30% of Main content area, Maximum 50%, left aligned
Second column maximum width: Remainder

All rows center aligned

WIDGETS

Column 1, Row 1
Text label: Analysis List. Style: labelStyle. 

Column 2, Row 1
Empty

Column 1, Row 2
A hierarchical list of project objects (display the name, use id and parentId to build the hierarchy). Root elements have parentId == null. All levels are collapsible, with the exception of leaves. To the left of leaf elements, place a checkbox. The user can only select a single leaf element. If a different one is selected, deselect the previously selected element.

Column 2, Row 2
Empty

Column 1, Row 3
Vertical spacing (15px)

Column 2, Row 3
Empty

Column 1, Row 4
A horizontal list of images (load the ones in imgs/ folder, place them as assets if needed for now). The images will be displayed as a thumbnail (100px in width, proportional height). When the user clicks on an image, a pop up opens with the fullsized image (Add horizontal and vertical scroll bars if necessary). On top of the popup dialog, left-aligned, place a download icon so the user can download the image.

Column 1, Row 4
Empty
