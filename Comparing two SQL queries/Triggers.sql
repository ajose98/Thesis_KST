USE BDKS 
GO

------------- Declarations -----------------

DECLARE @counter int=1; -- auxiliary variable that will increment
DECLARE @trigger nvarchar(max); -- name of the trigger


------------- Create temp table with serial identifier, all table names in the db and respective object_id and schema -----------------

select ROW_NUMBER() OVER( ORDER BY schema_name(t.schema_id) ) as idx, name, object_id,schema_name(t.schema_id) as schema_name 
into #temp3
from sys.tables  t 
where schema_name(t.schema_id) like 'ex%'


------------- Iterate over the tables in the db and create an Instead Of trigger for each -----------------

/*
The values of the Inserted table
are concatenated into a single column and saved in extraStudent. The values of the Deleted table
are concatenated into a single column and saved in extraRight. 
For the student answer the concatenated values are stored in these two tables in BDKS_COPY.
For our answer the concatenated values are stored in these two tables in BDKS.
*/
-- the trigger will be created by executing a string using sp_executesql
While @counter <= (Select max(idx) from #temp3)
	begin 
		set @trigger='create or alter trigger DDL_check'+convert(nvarchar(2),@counter)+'
		ON bdks.'+(Select schema_name from #temp3 where idx=@counter)+'.'+(Select name from #temp3 where idx=@counter)+' 
		INSTEAD OF INSERT, UPDATE, DELETE
		As
			Begin

				DECLARE @tablename sysname;
				DECLARE @schemaname sysname;
				DECLARE @col_names nvarchar(max);
				DECLARE @save_inserted nvarchar(max);
				DECLARE @save_deleted nvarchar(max);
				
				-- select the name of the table where this trigger is
				select @tablename = object_name(parent_id), @schemaname= OBJECT_SCHEMA_NAME(parent_id) 
				from sys.triggers where object_id = @@PROCID
		
				-- get the names of the columns in this table
				select @col_names =  ISNULL(@col_names+'', '','''') + c.name 
				from sys.all_columns c join sys.tables  t 
				ON  c.object_id = t.object_id 
				where t.name=@tablename and schema_name(t.schema_id) = @schemaname

				-- copy inserted and deleted to temporary tables
				-- we cannot use the originals because we want to use them inside a stored procedure
				Select *  INTO #inserted From inserted
				Select *  INTO #deleted From deleted

				IF @col_names like ''%,%''
					-- concatenate the results in the inserted table and save them into the table extraStudent
					-- concatenate the results in the deleted table and save them into the table extraRight
					-- depending on the number of columns, one of two approaches can take place
					begin
						set @save_inserted = ''Insert into solutions.extraStudent Select concat_ws('''', '''','' + @col_names + '') From #inserted''
						set @save_deleted = ''Insert into solutions.extraRight Select concat_ws('''', '''','' + @col_names + '') From #deleted''
					end
				ELSE
					begin
						set @save_inserted = ''Insert into solutions.extraStudent Select '' + @col_names + '' From #inserted''
						set @save_deleted = ''Insert into solutions.extraRight Select '' + @col_names + '' From #deleted''
					end

				exec sp_executesql @save_inserted
				exec sp_executesql @save_deleted

		END'

		exec sp_executesql @trigger
		set @counter=@counter+1
	end
