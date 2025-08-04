# R Operator Development Guidelines

## Core Requirements

## Project Creation Steps

When a new project must be created, follow the steps below:
1. Create the folder that will contain the project
2. Copy all files and folders from https://github.com/tercen/template-R_operator Github into the new project
3. Change the name of the project in operator.json
4. Clone https://github.com/tercen/template-R_operator/renv from Github into the new project
5. Proceed with the remaining user instructions as needed.

### Clarifications

- Data is selected with the select function of context. Their names are in names 
- Column pojections are selected with cselect. Their names are in cnames and are identified by column .ci
- Row projections are selected with rselect. Their names are in rnames and are identified by column .ri

For further examples, fetch and analyze the following public URLs:
- https://github.com/tercen/umap_operator/blob/master/main.R
- https://github.com/tercen/scale_operator/blob/master/main.R
- https://github.com/tercen/read_csv_operator/blob/master/main.R
- https://github.com/tercen/report_table_operator/blob/main/main.R