USE BDKS
GO

-- =====================================================================================
-- Author:			Sofia José
-- Create date:		20/06/2021
-- Function Name:	comment_order_by
-- Description:		Comments the Order By clause in a query, if it exists
--
-- Parameters:
--   @Solution - Query to be evaluated
--
-- Returns:	
--	@results - table with one single row and 4 columns:
--		solution - Query with the Order By clause commented, if it exists
--		descendent - 0 if the Order By is done in descendent order, 1 otherwise
--		order_by - 1 if the Order By clause was found in @Solution
--		index_b - The index in @Solution that corresponds to the space before 'By'
-- =====================================================================================

CREATE or ALTER FUNCTION comment_order_by(@Solution nvarchar(max))
	returns @results table 
	(solution nvarchar(max),
	descendent bit,
	order_by bit, 
	index_b int)
AS
BEGIN
	------------- Declarations -----------------

	declare @SolutionReady nvarchar(max); -- Corrected @Solution with the Order By clause commented, if it exists
	declare @index_o int; -- index of the white space before 'Order' in the Solution 
	declare @index_b int; -- index of the white space before 'By' in the Solution

	------------- Find index of the words 'Order' and 'By' -----------------
	/* 
	The PATINDEX function and regex are used to guarantee that the words Order By are only considered as the clause Order By when right next to
	them there are no more letters, numbers, _, ., /, #, =, <, > or ,. Meaning that by the side of these words there is at least one white space.
	The reverse function is used to look for the words Order By starting by the end of the string. As the Order By clause is always the last,
	doing this we make sure that even if the words 'Order' and 'By' exist in a different place in the string the real Order By is the one 
	detected. Still, it is important to guarantee that there is no column named 'Order' or 'By' and, being more specific, 
	guarantee they are not used in the Order By clause. This would be a problem for the implemented solution.
	PATINDEX returns 0 if the regex expression is not found.
	*/

	set @index_o = (select ((select len(@Solution))-(Select PATINDEX('%[^a-zA-Z1-9_.,/#=<>]redro[^a-zA-Z1-9_.,/#=><]%', reverse(trim(@Solution)))))-5)
	set @index_b = (select ((select len(@Solution))-(Select PATINDEX('%[^a-zA-Z1-9_.,/#=<>]yb[^a-zA-Z1-9_.,/#=><]%', reverse(trim(@Solution)))))-2)

	------------- Comment Order By clause -----------------

	-- if the words 'Order' and 'By' exist but they have other words in the middle, we do nothing (it is not the Order By clause)
	if (Select substring (@Solution, (@index_o+6), (@index_b+1-(@index_o+6)))) not like '%[A-Za-z1-9]%' 
		set @SolutionReady =  CONCAT(STUFF(@Solution, @index_o, (@index_b+3-@index_o), '/* order by'), '*/'); 
	else
		set @SolutionReady=@Solution

	------------- Return values -----------------
	/* 
	To confirm if the word 'desc' exists at the end of the Order By clause in @Solution
	we have to consider two regex expressions:	'% desc[^A-Za-z1-9]%' - if there is something like a space or a semicolon at the end
												'% desc' - if desc is the last thing in the string

	If @Solution and @SolutionReady are not the same, it means the Order By clause exists in @Solution
	*/

	Insert @results
	Select @SolutionReady, case when (((Select substring (@Solution, (@index_o+6), 10000)) like '% desc[^A-Za-z1-9]%') or 
										((select @Solution) like '% desc')) then 1 else 0 end,
		   case when @Solution!=@SolutionReady then 1 else 0 end, @index_b

	return;
END
go


-- ==========================================================================
-- Author:			Sofia José
-- Create date:		01/07/2021
-- Function Name:	RemoveSpaces
-- Description:		Removes all types of spaces from anywhere in a string 
--
-- Parameters:
--	@InputStr - String to be evaluated
--
-- Returns:	
--	@InputStr - String with all spaces removed
-- ==========================================================================

Create or alter Function RemoveSpaces (@InputStr varchar(1000))
Returns varchar(1000)
AS
Begin
	------------- Declarations -----------------

    Declare @ValuesToDrop as varchar(50) -- regex expression that includes all kind of spaces

	------------- Remove spaces -----------------

    Set @ValuesToDrop = '%[^a-z1-9.()_]%'
    While PatIndex(@ValuesToDrop, @InputStr) > 0
        Set @InputStr = Stuff(@InputStr, PatIndex(@ValuesToDrop, @InputStr), 1, '')

    Return @InputStr
End
Go


-- ==================================================================================================
-- Author:			Sofia José
-- Create date:		01/07/2021
-- Function Name:	columns_ordered
-- Description:		Finds the columns/expressions used in the Order By clause
--
-- Parameters:
--	@Solution - Query containing the Order By clause
--	@index_b - The index in @Solution that corresponds to the space before 'By'
--
-- Returns:	
--	@results - table with one single column and as many rows as columns/expressions used in Order By
--		words - name of column/expression used in the Order By clause
-- ==================================================================================================

CREATE or ALTER FUNCTION columns_ordered(@Solution nvarchar(max), @index_b int)
	returns @results table 
	(words nvarchar(max)) 
AS
BEGIN

	------------- Find columns/expressions and apply cleaning process -----------------

	Insert @results
	-- we want to remove the '.' when it is used to address a table because the table alias used by the student might be different from ours
	Select (case when PATINDEX('%.%', solution3) != 0 and solution3 not like '%(%' then substring(solution3, PATINDEX('%.%', solution3)+1, 1000)
				when PATINDEX('%.%', solution3) != 0 and solution3 like '%(%' then SUBSTRING(solution3,1,PATINDEX('%(%', solution3))+SUBSTRING(solution3,PATINDEX('%.%', solution3)+1,1000)
				else solution3 end) as final_words
	From (
		-- remove spaces from anywhere in the string and lower all letters
		Select lower(dbo.RemoveSpaces(tabela2.solution2)) as solution3
		From ( 
			-- when there is a blank space but not parenthesis we cut the string until the blank space
			-- when there is a blank space and parenthesis we cut the string in the closing parenthesis
			Select (case when PATINDEX('% %', tabela.solution) != 0 and tabela.solution not like '%(%' then substring(solution, 0, PATINDEX('% %', tabela.solution))
						when PATINDEX('% %', tabela.solution) != 0 and tabela.solution like '%(%' then substring(solution, 0, (PATINDEX('%)%', tabela.solution)+1)) 
							else solution end) as solution2
			From ( 
				-- split the string after the Order By when a ',' is found and trim the results (results in a table)
				Select trim(cast(value as nvarchar(max))) as solution
				From STRING_SPLIT(trim(substring (@Solution,
												@index_b+5, 1000)),',') -- @index_b+5 is the index of the space after the y of By
				) tabela )
		tabela2 )
	tabela3;

return
end
go


-- ======================================================================================================
-- Author:					Sofia José
-- Create date:				01/07/2021
-- Stored Procedure Name:	compare_ordered_columns
-- Description:				Compares the values in tables extraRight and extraStudent and checks if
--							they are equal in syntax or meaning
--
-- Parameters:
--	@SolutionStu - Query under analysis (used only if the values are not the exact same)
--
-- Returns:	
--	@Columns_wrong - 0 if the two tables match, 1 otherwise
-- =======================================================================================================

CREATE or ALTER PROCEDURE compare_ordered_columns
	@SolutionStu nvarchar(max),
	@Columns_wrong int OUTPUT  
AS   
	SET NOCOUNT ON;

	------------- Notes -----------------
	/*
	Both tables have a single column.
	Table extraRight has as many rows as columns/expressions used in the Order By in our solution.
	Table extraStudent has as many rows as columns/expressions used in the Order By in the student's solution (@SolutionStu).

	This stored procedure should be executed only if the number of rows is identical in both tables.

	If the columns or expressions have alias in the Select statement, in the Order By we
	can use the name of the new column or the old name/expression, so when a value of extraStudent does not have a match
	the sp will confirm if that value has an alias and if it does, if the alias is in table extraRight then a match exists.
	Most of this stored procedure deals with this case.
	It was assumed that in our solutions the alias names are the ones used in the Order By, when they exist.
	*/

	------------- Declarations -----------------

	DECLARE @counter int = 1; -- counter (auxiliary variable)
	DECLARE @nr_cols_as int = 0; -- number of rows that at first didn't have a match but after a 2nd check do (have alias)
	DECLARE @word_on_check nvarchar(max); -- value of extraRight to look for in @SolutionStu as an alias
	DECLARE @word_on_check_student nvarchar(max); -- part of @SolutionStu under analysis (at the end, it should exist in extraStudent)
	DECLARE @nr_cols int = (Select count(*) from solutions.extraRight); -- number of rows in table extraRight
	SET @Columns_wrong = 0;

	------------- Compare values in the two tables -----------------

	-- if all the values in extraRight are in extraStudent, then all values have a match and nothing else is done
	-- if not, a temporary table is created to store the values of extraRight that don't have a match in extraStudent
	IF EXISTS (Select 1 From solutions.extraRight s Where s.solution not in (Select solution From solutions.extraStudent))
		begin
			Select ROW_NUMBER() OVER( ORDER BY convert(nvarchar(max), solution) ) as idx, s.solution as expression
			Into #aux
			From solutions.extraRight s
			Where s.solution not in (Select solution From solutions.extraStudent)

			-- we are only interested in the words that come in the Select statement (before the From)
			Set @SolutionStu = (substring(@SolutionStu, 0, PATINDEX('%[^a-zA-Z1-9_.,/=<>]from[^a-zA-Z1-9_.,/=<>]%', @SolutionStu))+' ')

			-- this loop will iterate over all the rows of #aux
			-- all the values have a match if all values in #aux exist in @SolutionStu as an alias of the value in extraStudent
			-- if one value does not have a match, @Columns_wrong is set to 1 and nothing else is done
			While @counter <= (Select max(idx) from #aux) and @Columns_wrong = 0
				begin
					-- get the word to look for in @SolutionStu
					set @word_on_check = (Select expression From #aux Where idx = @counter)
					-- increment @counter
					set @counter = @counter+1
			
					-- check if the alias word we are looking for exists in @SolutionStu 
					-- if not, then there is not a match and @Columns_Wrong is set to 1
					If (@SolutionStu like '%[^a-zA-Z1-9_,./=<>]'+@word_on_check+'[^a-zA-Z1-9_./=<>]%')
						begin
							-- @word_on_check_student will be manipulated as a part of @SolutionStu
							SET @word_on_check_student = reverse(@SolutionStu)
							SET @word_on_check = reverse(@word_on_check)

							-- keep only the part of @word_on_check_student until @word_on_check is found (@word_on_check is the alias value)
							SET @word_on_check_student = SUBSTRING(@word_on_check_student, PATINDEX('%'+@word_on_check+'%', @word_on_check_student), 1000)

							-- drop the beginning of @word_on_check_student, which contains the keyword 'Select' and possibly other select columns
							IF @word_on_check_student like '%,%'
								begin
									-- when after the Select there are other expressions before the one under analysis 
									SET @word_on_check_student = reverse(SUBSTRING(@word_on_check_student, 1, PATINDEX('%,%', @word_on_check_student)-1))
								end
							ELSE
								begin
									-- when the expression under analysis is the first after the Select
									SET @word_on_check_student = reverse(SUBSTRING(@word_on_check_student, 1, PATINDEX('%tcele%', @word_on_check_student)-1))
								end
							
							SET @word_on_check = reverse(@word_on_check)
							-- drop from @word_on_check_student the @word_on_check, that comes last in the string
							SET @word_on_check_student = trim(SUBSTRING(@word_on_check_student, 1, PATINDEX('%[^a-zA-Z1-9_.,/()=<>]'+@word_on_check+'%', @word_on_check_student+' ')-1))

							-- drop the AS if it exists, lower case all characters and remove all spaces
							IF @word_on_check_student like '%[^a-zA-Z1-9_.,/=<>]as'
								begin 
									SET @word_on_check_student = dbo.RemoveSpaces(lower(LEFT(@word_on_check_student, len(@word_on_check_student)-2)))
								end

							-- Do the same cleaning as the one done in the columns_ordered function
							IF PATINDEX('%.%', @word_on_check_student) != 0 and @word_on_check_student not like '%(%' 
								begin
									SET @word_on_check_student = substring(@word_on_check_student, PATINDEX('%.%', @word_on_check_student)+1, 1000)
								end

							IF PATINDEX('%.%', @word_on_check_student) != 0 and @word_on_check_student like '%(%' 
								begin
									SET @word_on_check_student = SUBSTRING(@word_on_check_student,1,PATINDEX('%(%', @word_on_check_student))+SUBSTRING(@word_on_check_student,PATINDEX('%.%', @word_on_check_student)+1,1000)
								end
					
							-- At this phase, @word_on_check_student must be a "synonym" of @word_on_check. Let's see if that is the case. If not, the answer is wrong.
							-- That is the case if @word_on_check_student is one of the values that exists in extraStudent, but not in extraRight
							IF @word_on_check_student IN ((Select solution From solutions.extraStudent) EXCEPT (Select solution From solutions.extraRight))
								begin
									SET @nr_cols_as = @nr_cols_as+1

									-- Delete the matched records, they were already taken care of
									Delete TOP (1) From solutions.extraStudent -- TOP 1, because if there are duplicates I want to delete only 1 row
									Where solution=@word_on_check_student

									Delete TOP (1) From solutions.extraRight 
									Where solution=@word_on_check
								end
						end
					ELSE
						begin
							SET @Columns_wrong=1
							break;
						end
				end

				-- for each match found, @nr_cols_as was incremented, so it has to be equal to the number of rows in #aux
				-- if not @Columns_wrong is set to 1
				IF @nr_cols_as != (Select max(idx) from #aux)
					SET @Columns_wrong=1;
		end

RETURN
GO  

-- give user TeseASCJ the capacity to execute the above stored procedure
GRANT EXEC ON dbo.compare_ordered_columns TO [TeseASCJ];
GO


-- ======================================================================================================
-- Author:					Sofia José
-- Create date:				01/07/2021
-- Stored Procedure Name:	concat_table
-- Description:				Concatenates the records resulting from a query into one single column 
--							with all attributes splitted by a comma and saves them into a table
--
-- Parameters:
--	@Solution - Query to be ran (used only when the type of question is 'S')
--	@type - Type of the question under analysis 
--	@table_name - Name of the table where the records to concatenate are in
--	@Student - 1 if the @Solution is the student's answer, 0 if it is our answer
--
-- Returns:	
--	@problems - 1 if some problem is found, 0 otherwise
-- =======================================================================================================

CREATE or ALTER PROCEDURE concat_table
    @Solution nvarchar(max), 
	@type char(3),
	@table_name nvarchar(50)=NULL, -- when @type = 'S', @table_name will be filled in the function
	@Student bit,
	@problems bit OUTPUT
AS   
	SET NOCOUNT ON;

	------------- Declarations -----------------

	declare @to_run nvarchar(max); -- string to be executed
	declare @col_names nvarchar(max); -- column names of the query result
	declare @concat_table nvarchar(max); -- name of the table where the concatenated results will be saved
	set @problems = 0;

	------------- Set @concat_table value according to @Student -----------------

	IF @Student=1
		set @concat_table = 'bdks.solutions.extraStudent'
	ELSE
		set @concat_table = 'bdks.solutions.extraRight'

	------------- Get @col_names -----------------

	IF @type IN ('INT','INP')
	begin
		select @col_names =  ISNULL(@col_names+', ','') + name from Tempdb.Sys.Columns 
								 where Object_ID = Object_ID('tempdb..'+@table_name);
	end

	IF @type='S'
	begin
		set @table_name='solutions.aux'
		-- create an auxiliary table to store the results of @Solution
		set @to_run = 'select * into solutions.aux from ('+ @Solution + ') as t'
		exec sp_executesql @to_run

		-- get the column names of the auxiliary table
		select @col_names =  ISNULL(@col_names+', ','') + c.name from sys.all_columns c join sys.tables  t 
							ON  c.object_id = t.object_id where t.name='aux'
	end
		
	------------- Insert concatenated results into @concat_table -----------------
	IF @problems=0
	begin
		-- depending on the number of columns, one of two approaches will be taken
		IF @col_names like '%,%'
			set @to_run = 'Insert into '+@concat_table+' Select concat_ws('', '',' + @col_names + ') From '+@table_name
		ELSE
			set @to_run = 'Insert into '+@concat_table+' Select ' + @col_names + ' From '+@table_name

		exec sp_executesql @to_run
	end

	------------- Drop auxiliary table -----------------
	IF @type='S'
	begin
		drop table solutions.aux
	end
GO  

-- give user TeseASCJ the capacity to execute the above stored procedure
GRANT EXEC ON dbo.concat_table TO [TeseASCJ];
GO


-- ======================================================================================================
-- Author:					Sofia José
-- Create date:				01/07/2021
-- Stored Procedure Name:	compare_concat_tables
-- Description:				Verifies if the column from extraRight and the column from extraStudent
--							have the exact same results
--
-- Returns:	
--	@solution_wrong - 1 if the two columns have different results, 0 otherwise
-- =======================================================================================================

CREATE or ALTER PROCEDURE compare_concat_tables
	@solution_wrong bit OUTPUT
AS   
	SET NOCOUNT ON;

	------------- Compare the two tables -----------------

	-- we have to replace the NULL for string 'null' to avoid problems in the queries below 
	update solutions.extraRight
	set solution='null'
	where solution is null

	update solutions.extraStudent
	set solution='null'
	where solution is null

	-- check if the count of common rows between the two tables is equal to the count of rows using the solution
	-- Group By is used in all queries below to make sure duplicate records are not a problem
	IF 
		(select count(*)
			from 	(Select solution, count(solution) as count
				from solutions.extraRight
				group by solution) a
				inner join
				(Select solution, count(solution) as count
				from solutions.extraStudent
				group by solution) b
				on a.solution=b.solution and a.count=b.count)
		=
		(Select count(*)
			From (Select solution, count(solution) as count
				from solutions.extraRight
				group by solution) c)
		begin
			set @solution_wrong=0;
		end
	ELSE
		begin
			set @solution_wrong=1;
		end

	------------- Delete all records from auxiliary tables -----------------

	Delete From solutions.extraRight;
	Delete From solutions.extraStudent;

GO  

-- give user TeseASCJ the capacity to execute the above stored procedure
GRANT EXEC ON dbo.compare_concat_tables TO [TeseASCJ];
GO


-- ======================================================================================================
-- Author:					Sofia José
-- Create date:				06/07/2021
-- Stored Procedure Name:	transform_INP
-- Description:				Transforms queries of the type Select... Into table_name From... to
--							queries of the type Select... Into #table_name From...
--
-- Parameters:
--	@solution_original - Query to be transformed
--
-- Returns:	
--	@solution_use - Transformed query
--	@problems - 1 if some problem is found, 0 otherwise
-- =======================================================================================================

CREATE or ALTER PROCEDURE transform_INP
	@solution_original nvarchar(max),
	@solution_use nvarchar(max) OUTPUT,
	@problems bit OUTPUT
AS   
	SET NOCOUNT ON;

	------------- Declarations -----------------

	declare @table nvarchar(1000); -- name of the table to add the # before
	declare @idx_into int = PATINDEX('%[^a-zA-Z1-9_.,()/=#<>]into[^a-zA-Z1-9_.,()/=#<>]%', @solution_original) --index of space before 'into'
	declare @idx_from int = PATINDEX('%[^a-zA-Z1-9_.,()/=#<>]from[^a-zA-Z1-9_.,()/=#<>]%', @solution_original) -- index of space before 'from'
	set @problems=0;

	------------- Check for problems -----------------

	-- the syntax for this question to be correct must include INTO and FROM, if not it is wrong
	IF @idx_into = 0 or @idx_from = 0 
		set @problems = 1;

	------------- Get the transformed query -----------------

	IF @problems = 0
	begin
		-- @idx_into+5 is the space after into 
		-- @idx_from-(@idx_into+5) is the nr of characters between the end of 'into' and the beginning of 'from'
		set @table = trim(SUBSTRING(@solution_original, @idx_into+5, @idx_from-(@idx_into+5))) 
		set @solution_use = SUBSTRING(@solution_original, 1, @idx_into)+'into #'+@table+(SUBSTRING(@solution_original, @idx_from, 10000))
	end 
GO  

-- give user TeseASCJ the capacity to execute the above stored procedure
GRANT EXEC ON dbo.transform_INP TO [TeseASCJ];
GO

