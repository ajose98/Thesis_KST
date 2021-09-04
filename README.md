# Thesis_KST

## 🔍 Overview

The two folders in this repository store the code created in the scope of my thesis (**"Creating a Knowledge Space for the SQL domain"**)

In the folder [Comparing two SQL queries](https://github.com/ajose98/Thesis_KST/tree/main/Comparing%20two%20SQL%20queries), four .sql documents can be found.
- In [CreateObjects&Login](), a database called BDKS and the schemas described in chapter "Direct Result Comparison Implementation" are created. Additionaly, a login user is created and is assigned roles for this specific database.
- In [Functions&StoredProcedures](), the functions and stored procedures used in [EvaluationScript]() are created and documented.
- In [Triggers](), the triggers needed for the well functioning of [EvaluationScript]() are created in the respective tables of the database.
- [EvaluationScript]() is the main script which aggregates all the others and evaluates the correctness of a student's answer. It is designed to receive one taskID and one studentID, but it can be easily updated to evaluate more tasks and students at the same time.
