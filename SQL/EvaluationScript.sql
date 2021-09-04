USE BDKS
GO

-- Confirm if a copy of the database exists (students DDL solutions will be ran there)
if db_id(N'BDKS_COPY') is null
begin
	raiserror('A copy of the database does not exist.', 15,15)
end
	 
------------- DECLARATIONS -----------------

DECLARE @SQLString NVARCHAR(max); -- string to be executed
DECLARE @ParmDefinition NVARCHAR(500); -- parameters to be used in sp_executesql

DECLARE @Solution NVARCHAR(MAX); -- correct solution
DECLARE @Type char(3); -- type of the question
DECLARE @ID int; -- ID of the question
DECLARE @StudentID int; -- student ID
DECLARE @SolutionRuns bit; -- 0 if the query under analysis throws an error, 1 otherwise
DECLARE @Solution_Wrong int; -- 1 if the query delivers a result different than expected, 0 otherwise

DECLARE @SolutionStudent NVARCHAR(MAX); -- student answer

-- Variables used when the @Solution and/or @SolutionStudent have Order By clause:
DECLARE @DESC_Solution bit; -- 1 if @Solution has the word 'desc'
DECLARE @DESC_SolutionStudent bit; -- 1 if @SolutionStudent has the word 'desc'
DECLARE @ORDER_BY_check_Solution bit; -- 1 if @Solution has the Order By clause
DECLARE @ORDER_BY_check_SolutionStudent bit; -- 1 if @SolutionStudent has the Order By clause
DECLARE @INDEX_B_Solution int; -- index of the space before 'By' in @Solution
DECLARE @INDEX_B_SolutionStudent int; -- index of the space before 'By' in @SolutionStudent

DECLARE @Table_Name nvarchar(100); -- name of the table to be created (in questions of type 'INT' and 'INP')

DECLARE @Schema_Name NVARCHAR(MAX); -- name of the schema where the question under analysis is included
DECLARE @Username NVARCHAR(50); SET @Username = 'TeseASCJ'; -- name of the user

------------- START TESTING (iterate over the questions) -----------------

Set @ID = 1 -- this is the ID of the question to be evaluated. The value 1 is an example. When this file is called, the question ID must be given.
Set @studentID = 1 -- this is the ID of the student to be evaluated. The value 1 is an example. When this file is called, the student ID must be given.

-- get the correct solution and the type of the question
SET @SQLString = N'select @SQLOUT = solution, @SQLTYPE = question_type from BDKS.solutions.questions where questionID = @questionID';
SET @ParmDefinition = N'@questionID INT, @SQLOUT NVARCHAR(MAX) OUTPUT, @SQLTYPE char(3) OUTPUT'; 
EXECUTE sp_executesql  @SQLString, @ParmDefinition, @questionID = @ID, @SQLOUT = @Solution OUTPUT, @SQLTYPE = @Type OUTPUT; 
	
-- get the student answer for the current question
SET @SQLString = N'select @SQLOUT = answer from BDKS.solutions.answersStudents where questionID = @questionID and studentID = @studentID';
SET @ParmDefinition = N'@questionID INT, @studentID INT, @SQLOUT NVARCHAR(MAX) OUTPUT'; 
EXECUTE sp_executesql  @SQLString, @ParmDefinition, @questionID = @ID, @studentID = @StudentID, @SQLOUT = @SolutionStudent OUTPUT; 

-- set default values
SET @SolutionRuns = 1;
SET @Solution_Wrong=0;
print @Type;

------------- HANDLE QUESTIONS OF TYPE 'S' -----------------

IF @Type = 'S' -- Select
begin
	-- check if student's solution doesn't throw an error. If it does we just print a message.
	BEGIN TRY  
			EXECUTE sp_executesql @SolutionStudent;
	END TRY  
	BEGIN CATCH  
			PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct';
			Set @SolutionRuns = 0
	END CATCH
			
	IF @SolutionRuns = 1
	begin
		-- at start we don't know if there is an order by in the solutions
		set @DESC_Solution=0;
		set @DESC_SolutionStudent=0;
		set @ORDER_BY_check_Solution=0;
		set @ORDER_BY_check_SolutionStudent=0;

		------------- BEGINNING OF ORDER BY HANDLING -----------------
				
		/*
		When an answer has Order By, we will comment that clause because to check if the answer is correct we will use it
		as a subquery and Order By cannot be used in subqueries. We will do this for @Solution and @SolutionStudent.
		*/

		-- if the words 'Order' and 'By' exist, then there is a high chance that the Order By clause exists.
		-- in the function comment_order_by we validate if these words are in fact part of the Order By clause
		IF ( @Solution like '%Order%' and @Solution like '%By%') 
			begin 
				Select @Solution=solution, @DESC_Solution=descendent, @ORDER_BY_check_Solution=order_by, @INDEX_B_Solution=index_b
				From dbo.comment_order_by ((@Solution));

				IF @ORDER_BY_check_Solution=1 -- if there is in fact an Order By clause
					begin
						-- insert into extraRight (an auxiliary table) the columns/expressions used in the Order By clause
						insert into solutions.extraRight
						select *
						from dbo.columns_ordered (@Solution, @INDEX_B_Solution)
					end
			end

		IF (@SolutionStudent like '%Order%' and @SolutionStudent like '%By%')
			begin
				Select @SolutionStudent=solution, @DESC_SolutionStudent=descendent, @ORDER_BY_check_SolutionStudent=order_by, @INDEX_B_SolutionStudent=index_b
				From dbo.comment_order_by ((@SolutionStudent));
						
				IF @ORDER_BY_check_SolutionStudent=1
					begin
						-- insert into extraStudent (an auxiliary table) the columns/expressions used in the Order By clause
						insert into solutions.extraStudent
						select *
						from dbo.columns_ordered (@SolutionStudent, @INDEX_B_SolutionStudent)
					end
			end
			
		IF ((@ORDER_BY_check_SolutionStudent!=@ORDER_BY_check_Solution)
			-- if one of the solutions has Order By and the other doesn't, then the student's answer is not correct
			OR
			((@ORDER_BY_check_SolutionStudent=1 and @ORDER_BY_check_Solution=1) and (@DESC_Solution!=@DESC_SolutionStudent))) 
			-- if one of the solutions has Order By desc and the other doesn't, than the student's answer is not correct
			OR
			(@ORDER_BY_check_SolutionStudent=1 AND @ORDER_BY_check_Solution=1 AND
			((Select count(*) from solutions.extraRight)
			!=
			(Select count(*) from solutions.extraStudent)))
			-- if the ordering is not done by the same number of columns the student's answer is not correct
				begin
					set @Solution_Wrong=1;
				end

		-- let's check if the columns used in the order by are the same
		IF 	(@ORDER_BY_check_SolutionStudent=1 AND @ORDER_BY_check_Solution=1 AND @Solution_Wrong=0) 
			begin
				-- if the ordering is not done using the exact same columns, it is possible that an alias was 
				-- used and in the Order By the original expression or the alias can be called (the sp compare_ordered_columns considers both options)
				exec dbo.compare_ordered_columns @SolutionStudent, @Solution_Wrong output
			end

		Delete From solutions.extraRight;
		Delete From solutions.extraStudent;

		------------- COMPARE RESULTS FROM @SOLUTION AND @SOLUTIONSTUDENT -----------------

		IF @Solution_Wrong=0
		begin
			-- concatenate the results into one single column
			EXEC dbo.concat_table @Solution = @Solution, @Type=@Type, @Student = 0, @problems=@Solution_Wrong OUTPUT;
			EXEC dbo.concat_table @Solution = @SolutionStudent, @Type=@Type, @Student = 1, @problems=@Solution_Wrong OUTPUT

			-- compare the concatenated columns
			EXEC dbo.compare_concat_tables @Solution_Wrong output;

			IF @Solution_Wrong=0
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is correct'
			end
			ELSE
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct'	
			end
		end

		ELSE
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct'
			end
	end
end

------------- HANDLE QUESTIONS OF TYPE 'INT' AND 'INP' -----------------

IF @Type in ('INT', 'INP')  -- Questions implying an insert in a new temporary or permanent table
begin

	-- if type = 'INP' turn the answer into an 'INT' answer by adding '#' before the table name
	IF @Type='INP'
	begin
		EXEC dbo.transform_INP @solution_original=@SolutionStudent, @solution_use=@SolutionStudent output, @problems=@Solution_Wrong output;
		EXEC dbo.transform_INP @solution_original=@Solution, @solution_use=@Solution output, @problems=@Solution_Wrong output;
	end

	-- a check is made to see if the words 'select' and 'into' exist in solution, if they don't it is incorrect
	IF @Solution_Wrong=1
		PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct';
	ELSE
	begin
		-- check if @SolutionStudent throws an error (the temporary table will disapear right after the procedure is executed)
		BEGIN TRY  
			EXECUTE sp_executesql  @SolutionStudent; 
		END TRY  
		BEGIN CATCH  
			PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct';
			Set @SolutionRuns = 0
		END CATCH

		IF @SolutionRuns = 1
		begin
			-- get the name of the temporary table that will be created by our solution
			Set @table_name = trim(SUBSTRING(@Solution, PATINDEX('%[^a-zA-Z1-9_.,()/=#<>]into[^a-zA-Z1-9_.,()/=#<>]%',@Solution)+5,1000)) -- PATINDEX+5 returns the index for the space after 'into'
			-- cut the string on the first space (keep the first part)
			Set @table_name = SUBSTRING(@table_name, 1, PATINDEX('%[^a-zA-Z1-9_.,()/=#<>]%',@table_name)-1)

			-- because the temporary table cease to exist when the procedure which created it ends, a stored procedure will be created where
			-- the @Solution is ran and immediately after the concatenated results are saved in a permanent table.
			SELECT @SQLString = 
							@Solution + '  
							EXEC dbo.concat_table @Solution = @Solution, @Type=@Type, @table_name=@table_name, @Student = @Student, @problems = @problems OUTPUT;
							';
					
			SET @ParmDefinition = N'@Solution nvarchar(max), @Type char(3), @table_name nvarchar(max), @Student bit, @problems bit OUTPUT';
			EXEC sp_executesql @SQLString, @ParmDefinition, @Solution=@Solution, @Type=@Type, @table_name=@table_name, @Student=0, @problems=@Solution_Wrong OUTPUT;

			-- get the name of the temporary table created by the student solution (same as ours but doesn't have the last character)
			set @table_name = LEFT(@table_name, LEN(@table_name) - 1)

			-- now, besides running the query and concatenating the results, a verification is made to check if the 
			-- expected temporary table was created by the student's query. If not, the answer is incorrect
			SELECT @SQLString = 
							@SolutionStudent + '  
							IF exists (SELECT 1 FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE ('''+@table_name+'''+''%''))
								begin
									set @problems = 0
								end
							ELSE
								set @problems=1
									
							IF @problems = 0
							begin
								EXEC dbo.concat_table @Solution = @Solution, @Type=@Type, @table_name=@table_name, @Student = @Student, @problems = @problems OUTPUT;
							end';  

			SET @ParmDefinition = N'@Solution nvarchar(max), @Type char(3), @table_name nvarchar(max), @Student bit, @problems bit OUTPUT';
			EXEC sp_executesql @SQLString, @ParmDefinition, @Solution=@Solution, @Type=@Type, @table_name=@table_name, @Student=1, @problems=@Solution_Wrong OUTPUT;

			------------- COMPARE RESULTS FROM @SOLUTION AND @SOLUTIONSTUDENT -----------------

			IF @Solution_Wrong = 0
				EXEC dbo.compare_concat_tables @Solution_Wrong output;

			IF @Solution_Wrong=0
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is correct'
			end
			ELSE
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct'	

				-- delete the records in auxiliary tables
				Delete from solutions.extraRight
				Delete from solutions.extraStudent
			end
		end
	end
end 

------------- HANDLE QUESTIONS OF TYPE 'I', 'U' and 'D' -----------------
/*
For these types of questions, the students' answer will be ran in the copy of the original database,
to allow the comparison between the effects of our query and the student's query in the database.
Our query will be ran in the original database.
However, none of the queries will have a real impact in any database, because of the existing Instead Of triggers.

There is a trigger in each table that reacts when a DDL operation is executed. The values of the Inserted table
are concatenated into a single column and saved in extraStudent. The values of the Deleted table
are concatenated into a single column and saved in extraRight. 
For the student answer the concatenated values are stored in these two tables in BDKS_COPY.
For our answer the concatenated values are stored in these two tables in BDKS.
*/

IF @Type in ('I','U','D') 
begin
	-- change to BDKS_COPY to run the student's answer
	USE BDKS_COPY
	-- set default schema
	SET @SQLString = N'ALTER USER ' + @Username + ' WITH DEFAULT_SCHEMA = ' + @Schema_Name;
	EXECUTE sp_executesql  @SQLString;

	-- to avoid unexpected errors use TRY and CATCH
	BEGIN TRY  
			EXECUTE sp_executesql @SolutionStudent;
	END TRY  
	BEGIN CATCH  
			PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct';
			Set @SolutionRuns = 0
	END CATCH

	IF @SolutionRuns = 1
	begin
		-- go back to BDKS and run our solution
		USE BDKS
		-- set default schema
		SET @SQLString = N'ALTER USER ' + @Username + ' WITH DEFAULT_SCHEMA = ' + @Schema_Name;
		EXECUTE sp_executesql  @SQLString;
		EXECUTE sp_executesql @Solution

		-- we have to replace the NULL for string 'null' to avoid problems in the queries below 
		update bdks_copy.solutions.extraRight
		set solution='null'
		where solution is null

		update bdks_copy.solutions.extraStudent
		set solution='null'
		where solution is null

		update bdks.solutions.extraRight
		set solution='null'
		where solution is null

		update bdks.solutions.extraStudent
		set solution='null'
		where solution is null

		IF -- check if the deleted table is in the same state in both databases
			(select count(*)
				from 	(Select solution, count(solution) as count
					from bdks.solutions.extraRight
					group by solution) a
					inner join
					(Select solution, count(solution) as count
					from bdks_copy.solutions.extraRight
					group by solution) b
					on a.solution=b.solution and a.count=b.count)
			=
			(Select count(*)
				From (Select solution, count(solution) as count
					from bdks.solutions.extraRight
					group by solution) c) 
					AND
			-- check if the inserted table is in the same state in both databases
			(select count(*)
				from 	(Select solution, count(solution) as count
					from bdks.solutions.extraStudent
					group by solution) a
					inner join
					(Select solution, count(solution) as count
					from bdks_copy.solutions.extraStudent
					group by solution) b
					on a.solution=b.solution and a.count=b.count)
			=
			(Select count(*)
				From (Select solution, count(solution) as count
					from bdks.solutions.extraStudent
					group by solution) c)
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is correct'
			end

		ELSE
			begin
				PRINT 'Student result for question ' + cast(@ID as char(3)) + ' is not correct'
			end
	end

	-- clean the auxiliary tables
	Delete From bdks_copy.solutions.extraRight;
	Delete From bdks_copy.solutions.extraStudent;
	Delete From bdks.solutions.extraRight;
	Delete From bdks.solutions.extraStudent;

end

	

