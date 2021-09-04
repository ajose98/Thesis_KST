use master
go

------------- CREATE DATABASE -----------------

-- if the database already exists drop it to recreate it
if db_id(N'BDKS') is not null
begin
	alter database BDKS set single_user with rollback immediate;
	drop database BDKS;
end


create database BDKS
go

use BDKS
go

------------- CREATE QUESTIONS' SCHEMAS -----------------

create schema ex001
go

create table BDKS.ex001.EMPLOYEES( 
	EMPLOYEE_ID int identity primary key, 
	name varchar(100), 
	salary money)
go
create table BDKS.ex001.PROJECTS( 
	PROJECT_ID int identity primary key, 
	title varchar(100), 
	budget money)
go
create table BDKS.ex001.WORKS_ON( 
	EMPLOYEE_ID int references BDKS.ex001.EMPLOYEES(EMPLOYEE_ID), 
	PROJECT_ID int references BDKS.ex001.PROJECTS(PROJECT_ID), 
	year int,
	constraint PK_WORKS_ON primary key (year, EMPLOYEE_ID, PROJECT_ID))
go

--------------------------------------------------------------------------------------------
create schema ex002
go

create table BDKS.ex002.BOOKS(
	ISBN char(13) primary key,
	Author varchar(50),
	Title varchar(50),
	Publisher varchar(50),
	PublishDate Date,
	Pages int,
	Notes text)
go

create table BDKS.ex002.STORE(
	StoreID int primary key,
	StoreName varchar(50),
	Street varchar(50),
	State varchar(50),
	City varchar(50),
	Zip varchar(50))
go

create table BDKS.ex002.STOCK(
	ISBN char(13) references BDKS.ex002.BOOKS(ISBN),
	StoreID int references BDKS.ex002.STORE(StoreID),
	Price Money,
	Quantity int,
	primary key (ISBN,StoreID))
go

--------------------------------------------------------------------------------------------
create schema ex003
go

create table BDKS.ex003.PERSON(
	PersonID int primary key,
	Name varchar(50))
go

create table BDKS.ex003.RELATIONSHIP(
	PersonID1 int references BDKS.ex003.PERSON(PersonID),
	Relation varchar(20) check( relation in ('Friend', 'Enemy')),
	PersonID2 int references BDKS.ex003.PERSON(PersonID),
	primary key (PersonID1, PersonID2))
go

--------------------------------------------------------------------------------------------
create schema ex004
go

create table BDKS.ex004.teams(
	TeamID int primary key,
	Name varchar(50) )
go

create table BDKS.ex004.games(
	WinningTeam int references BDKS.ex004.teams(TeamID),
	LoosingTeam int references BDKS.ex004.teams(TeamID),
	primary key (WinningTeam, LoosingTeam))
go

create table BDKS.ex004.person(
	PersonID int primary key,
	Name varchar(50),
	Salary Money,
	Rating int)
go

create table BDKS.ex004.member(
	Player int references BDKS.ex004.person(PersonID),
	Team int references BDKS.ex004.teams(TeamID),
	primary key (Player, Team))
go

--------------------------------------------------------------------------------------------
create schema ex005
go

create table BDKS.ex005.courses(
	department varchar(50),
	number int,
	semester varchar(20),
	name varchar(50),
	primary key (department, number, semester))
go

create table BDKS.ex005.students(
	username varchar(20) primary key,
	firstName varchar(50),
	lastName varchar(50))
go

create table BDKS.ex005.enrolled(
	username varchar(20) references BDKS.ex005.students(username),
	department varchar(50),
	number int,
	semester varchar(20),
	grade numeric(4,2),
	primary key (username, department, number, semester),
	foreign key (department, number, semester) references BDKS.ex005.courses(department, number, semester))
go

--------------------------------------------------------------------------------------------
create schema ex006
go

create table BDKS.ex006.stocks(
	symbol varchar(4) primary key,
	name varchar(50))
go

create table BDKS.ex006.stock_var(
	symbol varchar(4) references BDKS.ex006.stocks(symbol),
	delta float,
	year int,
	week int,
	primary key (symbol, year, week))
go

create table BDKS.ex006.owns(
	investor varchar(50),
	symbol varchar(4) references BDKS.ex006.stocks(symbol),
	quantity int,
	primary key (investor,symbol))
go

--------------------------------------------------------------------------------------------
create schema ex007
go

create table BDKS.ex007.history (
	id int identity primary key, 
	url varchar(900), 
	access_date datetime)
go

create table BDKS.ex007.cache(
	url varchar(900) primary key,
	content text,
	size int)
go

create table BDKS.ex007.bookmark(
	name varchar(255) primary key,
	url varchar(900))
go
	
--------------------------------------------------------------------------------------------
create schema ex008
go

create table BDKS.ex008.EMPLOYEE(
	ssn integer primary key,
	first_name varchar(50), last_name varchar(50), address varchar(50), 
	date_joined date, 
	supervisor_ssn int references BDKS.ex008.EMPLOYEE(ssn))
go

create table BDKS.ex008.DEPARTMENT(
	dept_no int primary key, 
	name varchar(50), 
	manager_ssn int references BDKS.ex008.EMPLOYEE(ssn))
go

create table BDKS.ex008.WORKS_IN(
	employee_ssn int references BDKS.ex008.EMPLOYEE(ssn), 
	dept_no int references BDKS.ex008.DEPARTMENT(dept_no),
	primary key (employee_ssn, dept_no))
go

create table BDKS.ex008.ITEMS(
	item_id int primary key, 
	item_name varchar(50), 
	type varchar(50))
go

create table BDKS.ex008.INVENTORY(
	dept_no int references BDKS.ex008.DEPARTMENT(dept_no), 
	item_id int references BDKS.ex008.ITEMS(item_id) , 
	quantity int,
	primary key (dept_no, item_id))
go

--------------------------------------------------------------------------------------------
create schema ex009
go

create table BDKS.ex009.movies(
	movieID int primary key,
	title varchar(50),
	premiereDate date,
	rating int,
	evolution varchar(50) check(evolution in ('Positive', 'Negative', 'Stable')))
go

create table BDKS.ex009.person(
	personID int primary key,
	name varchar(50),
	yearBirth int)
go

create table BDKS.ex009.roles(
	roleID int primary key,
	role varchar(50) check(role in ('Actor', 'Director')))
go

create table BDKS.ex009.part(
	movieID int references BDKS.ex009.movies(movieID),
	personID int references BDKS.ex009.person(personID),
	roleID int references BDKS.ex009.roles(roleID),
	primary key (movieID, personID, roleID))
go

--------------------------------------------------------------------------------------------
create schema ex010
go

create table BDKS.ex010.cocktails(
	cocktailName varchar(50) primary key,
	price Money)
go

create table BDKS.ex010.ingredients(
	ingredientName varchar(50) primary key,
	unitCost Money,
	alcoolPercentage float)
go

create table BDKS.ex010.recipes(
	cocktail varchar(50) references BDKS.ex010.cocktails(cocktailName),
	ingredient varchar(50) references BDKS.ex010.ingredients(ingredientName),
	units float,
	primary key (cocktail, ingredient))
go

--------------------------------------------------------------------------------------------
create schema ex011
go

create table BDKS.ex011.people(
	citizenCard varchar(30) primary key,
	name varchar(50),
	phone varchar(20),
	address varchar(50),
	postcode varchar(50))
go

create table BDKS.ex011.cars(
	plate varchar(20) primary key,
	color varchar(20),
	brand varchar(30),
	model varchar(30),
	yearProduction int)
go

create table BDKS.ex011.owns(
	plate varchar(20) references BDKS.ex011.cars(plate),
	citizenCard varchar(30) references BDKS.ex011.people(citizenCard),
	primary key (plate, citizenCard))
go

create table BDKS.ex011.fines(
	fineID int primary key,
	plate varchar(20) references BDKS.ex011.cars(plate),
	date date,
	postcodeFine varchar(50))
go

--------------------------------------------------------------------------------------------
create schema ex012
go

create table BDKS.ex012.Members (
	MemberID int primary key, 
	Name varchar(50), 
	Age int)
go
create table BDKS.ex012.Images (
	ImageID int primary key,
	year int)
go

create table BDKS.ex012.Tags (
	MemberID int references BDKS.ex012.Members (MemberID),
	ImageID int references BDKS.ex012.Images (ImageID),
	primary key (MemberID, ImageID))
go

--------------------------------------------------------------------------------------------
create schema ex013
go

create table BDKS.ex013.FLIGHTS(
	FlightNumber int primary key,
	CityOfOrigin varchar(50), 
	CityOfDestination  varchar(50))
go

create table BDKS.ex013.DEPARTURES(
	FlightNumber int references BDKS.ex013.FLIGHTS(FlightNumber), 
	Date date, 
	TypeOfAirplane varchar(50),
	primary key (FlightNumber, Date))
go

create table BDKS.ex013.PASSENGERS( 
	IDPassenger int primary key,
	Name varchar(50), 
	Address  varchar(50))
go

create table BDKS.ex013.RESERVATIONS( 
	IDPassenger int references BDKS.ex013.PASSENGERS(IDPassenger),
	FlightNumber int, 
	Date date, 
	SeatNumber varchar(20),
	foreign key (FlightNumber, Date) references BDKS.ex013.DEPARTURES(FlightNumber, Date),
	primary key (IDPassenger,FlightNumber,Date))
go

--------------------------------------------------------------------------------------------
create schema ex014
go

create table BDKS.ex014.animalTypes(
	animalTypeID int primary key,
	animalType varchar(30))
go

create table BDKS.ex014.persons(
	personID int primary key,
	name varchar(50),
	phoneNumber varchar(20),
	address varchar(100),
	numAnimals int)
go

create table BDKS.ex014.animals(
	animalID int primary key,
	animalTypeID int references BDKS.ex014.animalTypes(animalTypeID),
	name varchar(50),
	previousOwnerID int references BDKS.ex014.persons(personID),
	admissionDate datetime)
go

create table BDKS.ex014.adoption(
	adoptorID int references BDKS.ex014.persons(personID),
	animalID int references BDKS.ex014.animals(animalID),
	adoptionDate datetime,
	numChip varchar(20),
	primary key (adoptorID, animalID))
go
	
--------------------------------------------------------------------------------------------
create schema ex015
go

create table BDKS.ex015.locations(
	locationID int primary key,
	name varchar(50),
	city varchar(50))
go

create table BDKS.ex015.crimes(
	crimeID int primary key,
	crimeLocation int references BDKS.ex015.locations(locationID),
	crimeTime datetime,
	crimeType varchar(50),
	victimName varchar(50))
go

create table BDKS.ex015.persons(
	personID int primary key,
	name varchar(50))
go

create table BDKS.ex015.reports(
	reportID int primary key,
	wittness int references BDKS.ex015.persons(personID),
	time datetime,
	suspect int references BDKS.ex015.persons(personID),
	crimeID int references BDKS.ex015.crimes(crimeID))
go

--------------------------------------------------------------------------------------------
create schema ex016
go

create table BDKS.ex016.Person(
	PersonID int primary key,
	Name varchar(50),
	Email varchar(80),
	Date_Of_Birth datetime)
go

create table BDKS.ex016.Citizen_Shops(
	Shop_ID int primary key,
	Name varchar(50),
	Address text,
	Phone_Number nvarchar(15))
go

create table BDKS.ex016.Appointments(
	Appointment_ID int primary key,
	Person_ID int references BDKS.ex016.Person(PersonID),
	Shop_ID int references BDKS.ex016.Citizen_Shops(Shop_ID),
	Datetime datetime)
go


------------- CREATE SOLUTIONS SCHEMA -----------------
create schema solutions
go


create table BDKS.solutions.questions(
	questionID int primary key,
	parentID int references BDKS.solutions.questions(questionID), -- if parentID is null then it is a top level question
	question text not null,
	question_type char(3) check(question_type in ('S','U','D','I','INT','INP')), -- values: select, update, delete, insert, insert in new temporary table, insert in new permanent table
	solution text,
	exschema char(5))
go

create table BDKS.solutions.students(
	studentID int primary key,
	name varchar(50),
	email varchar(50))
go

create table BDKS.solutions.answersStudents(
	questionID int references BDKS.solutions.questions(questionID) on update cascade on delete cascade,
	studentID int references BDKS.solutions.students(studentID) on update cascade on delete cascade,
	answer text,
	primary key (questionID, studentID))
go

create table BDKS.solutions.altSolutions(
	solutionID int,
	questionID int references BDKS.solutions.questions(questionID), 
	solution text,
	primary key (questionID, solutionID))
go


create table BDKS.solutions.extraStudent(
	solution nvarchar(max))
go

create table BDKS.solutions.extraRight(
	solution nvarchar(max))
go

------------- CREATE LOGIN AND USER FOR BDKS -----------------
USE [master]
GO

If not Exists (select 1 from master.dbo.syslogins where name = 'TeseASCJ' )
	CREATE LOGIN [TeseASCJ] WITH PASSWORD=N'Teste123456' MUST_CHANGE, DEFAULT_DATABASE=[BDKS], CHECK_EXPIRATION=ON, CHECK_POLICY=ON
	GO 

USE [BDKS]
GO
CREATE USER [TeseASCJ] FOR LOGIN [TeseASCJ] WITH DEFAULT_SCHEMA=[solutions]
GO

USE [BDKS]
GO
ALTER ROLE [db_datareader] ADD MEMBER [TeseASCJ]
GO
ALTER ROLE [db_datawriter] ADD MEMBER [TeseASCJ]
GO

GRANT ALTER ON SCHEMA::[solutions] TO [TeseASCJ]
GO

GRANT CREATE TABLE TO [TeseASCJ]
GO
