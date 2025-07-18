### WebApp Commons

A library containing typical functions used by WebApps, such as connecting to Tercen, handling project files and interacting with workflows.

##### File Structure

webapp_commons
│   README.md : This file
│
└── lib : Dart files
│ ..... │   file011.txt
│ ..... │
│ ..... └───subfolder1


##### Services

All functionalities are provided through Service classes. All service classes are singletons specialized in a particular group of functions. For instance, ProjectService handles project related functionality like create project, searching project files and so on.

#####