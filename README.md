# Thesis_KST

## 🔍 Overview

The two folders in this repository store the code created in the scope of my thesis (**"Creating a Knowledge Space for the SQL domain"**)

In the folder [Comparing two SQL queries](https://github.com/ajose98/Thesis_KST/tree/main/Comparing%20two%20SQL%20queries), four .sql files can be found:
- In [CreateObjects&Login](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/CreateObjects%26Login.sql), a database called BDKS and the schemas described in chapter "Direct Result Comparison Implementation" are created. Additionaly, a login user is created and is assigned roles for this specific database.
- In [Functions&StoredProcedures](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/Functions%26StoredProcedures.sql), the functions and stored procedures used in [EvaluationScript](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/EvaluationScript.sql) are created and documented.
- In [Triggers](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/Triggers.sql), the triggers needed for the well functioning of [EvaluationScript](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/EvaluationScript.sql) are created in the respective tables of the database.
- [EvaluationScript](https://github.com/ajose98/Thesis_KST/blob/main/Comparing%20two%20SQL%20queries/EvaluationScript.sql) is the main script which aggregates all the others and evaluates the correctness of a student's answer. It is designed to receive one taskID and one studentID, but it can be easily updated to evaluate more tasks and students at the same call.


In the folder [Matrix Related Code](https://github.com/ajose98/Thesis_KST/tree/main/Matrix%20Related%20Code), two .py files can be found:
- [Get base states, nodes and edges](https://github.com/ajose98/Thesis_KST/blob/main/Matrix%20Related%20Code/Get%20base%20states%2C%20nodes%20and%20edges.py) imports an excel file (more details on it are found in the beginning of the file) and exports three essential files for the scope of the thesis. It exports an excel file with the base states of the constructed Competence Space and associated Performance states and two csv files to be imported in [Gephi](https://gephi.org/) to create a precedence graph of the base states.
- [Get precedencies from matrix](https://github.com/ajose98/Thesis_KST/blob/main/Matrix%20Related%20Code/Get%20precedencies%20from%20matrix.py) imports two excel files (more details on it are found in the beginning of the file) and outputs an excel file with the precedencies encountered in the task-competency matrix. These are the precedencies to be validated by the experts.

The full thesis is available and can be found in http://hdl.handle.net/10362/140846.
