# Python Operator Development Guidelines

A Tercen Python operator is a python script that takes its input from Tercen and save the output back to Tercen.
The script runs inside a docker container.
Except for input and output, there are no further restrictions on the python script.

## Important Concepts

##### Tercen Projection

A projection, in Tercen, is a data organization in columns, rows, axis, labels, colors and errors. 

There are 3 basic projection tables that can be used in the operator.

The main projection contains the data (.y, .x, labels, .ci, .ri) and is probed using context fields and functions like select or names.
The column projection contains data labels stored in Tercen's columns (.ci, colname1, colname2, etc) as is probed using context fields and functions like cselect or cnames. It is linked to the main table through the .ci column. 
The row projection contains data labels stored in Tercen's rows  (.ri, rowname1, rowname2, etc) as is probed using context fields and functions like rselect or rnames. It is linked to the main table through the .ri column.




## Project Creation Steps

When a new project must be created, follow the steps below:
1. Create the folder that will contain the project
2. Copy all files and folders from https://github.com/tercen/template-python-operator Github into the new project
3. Change the name of the project in operator.json
4. Proceed with the remaining user instructions as needed.

### Clarifications

- All data access will be accomplsihed with the tercen python client from https://github.com/tercen/tercen_python_client
- The tercen python client is a requirement in the requirements.txt
- Data is selected with the select function of context. Their names are in the names field. It will contain a .ci and .ri value to join with column and row projections
- Column pojections are selected with cselect. Their names are in cnames and are identified by column .ci
- Row projections are selected with rselect. Their names are in rnames and are identified by column .ri
- Data manipulation using polars is preferred over pandas.

Analyze the following python operators to understand how to code a python operator:
- https://github.com/tercen/median_python_operator
- https://github.com/tercen/demo_python_operator
- https://github.com/tercen/python_relation_example

