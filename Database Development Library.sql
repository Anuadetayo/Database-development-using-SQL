DROP DATABASE IF EXISTS Library;
GO

DROP SCHEMA IF EXISTS Library;
GO

--Creating database
CREATE DATABASE Library;

USE Library;
Go

--Creating schema
CREATE SCHEMA Library;
GO

--Creating Tables
CREATE TABLE Library.Member(
MemberID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL,
BirthDate date NOT NULL, 
EmailAddress nvarchar(50) UNIQUE NULL CHECK (EmailAddress LIKE '%_@_%._%'),
PhoneNumber nvarchar(20) UNIQUE NULL CHECK ( [PhoneNumber] LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' and len([PhoneNumber])=11 ),
EndDate date NULL,
Status nvarchar(20) NOT NULL CHECK (Status LIKE 'Active' OR Status LIKE 'Inactive'));
GO

CREATE TABLE Library.Login_Details(
UserID int IDENTITY(501,1) NOT NULL PRIMARY KEY,
MemberID int NOT NULL FOREIGN KEY REFERENCES Library.Member(MemberID),
UserName nvarchar(50) UNIQUE NOT NULL ,
Password BINARY(64)  NOT NULL CHECK (Password LIKE '%[A-Z]%' and Password LIKE '%[!@#$%a^&*()-_+=.,;:`~]%' and Password LIKE '%[0-9]%' and len(Password) >= 8),
Salt UNIQUEIDENTIFIER)
GO

CREATE TABLE Library.Address (
AddressID int IDENTITY(100,1)  NOT NULL PRIMARY KEY,
Address1 nvarchar(50) NOT NULL,
Address2 nvarchar(50) NULL,
City nvarchar(25) NULL,
Postcode nvarchar(10) NOT NULL,
MemberID int NOT NULL
CONSTRAINT UC_Address UNIQUE (Address1, Postcode),
CONSTRAINT fk_MemberID FOREIGN KEY(MemberID) REFERENCES Library.Member (MemberID));
GO

CREATE TABLE Library.MemberArchive(
MemberArchiveID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
MemberID int NOT NULL FOREIGN KEY REFERENCES Library.Member(MemberID),
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL,
BirthDate date NOT NULL, 
EmailAddress nvarchar(50) UNIQUE NULL CHECK (EmailAddress LIKE '%_@_%._%'),
PhoneNumber nvarchar(20) UNIQUE NULL CHECK ( [PhoneNumber] LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' and len([PhoneNumber])=11 ));
GO

CREATE TABLE Library.ItemType(
ItemTypeID int IDENTITY(11,1) NOT NULL PRIMARY KEY,
ItemType nvarchar(20) NOT NULL CHECK (ItemType LIKE 'Book' OR ItemType LIKE 'Journal' OR ItemType LIKE 'DVD' OR ItemType LIKE 'Other Media'));
GO

CREATE TABLE Library.ItemStatus(
ItemStatusID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
ItemStatus nvarchar(20) NOT NULL CHECK (ItemStatus LIKE  'On Loan' OR ItemStatus LIKE 'Overdue' OR ItemStatus LIKE 'Available' OR ItemStatus LIKE  'Lost/Removed'));
GO

CREATE TABLE Library.Item(
ItemID int IDENTITY(1001,1) NOT NULL PRIMARY KEY,
ItemTitle nvarchar(200) NOT NULL,
Publication_year int NULL,
DateAdded date NOT NULL,
DateLost date NULL,
ISBN nvarchar(20) NULL,
ItemTypeID int NOT NULL FOREIGN KEY REFERENCES Library.ItemType(ItemTypeID),
ItemStatusID int NOT NULL FOREIGN KEY REFERENCES Library.ItemStatus(ItemStatusID));
GO

CREATE TABLE Library.Author(
AuthorID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
FirstName nvarchar(50) NOT NULL,
LastName nvarchar(50) NOT NULL);
GO

CREATE TABLE Library.ItemAuthor(
AuthorID  int NOT NULL FOREIGN KEY REFERENCES Library.Author (AuthorID),
ItemID  int NOT NULL FOREIGN KEY REFERENCES Library.Item (ItemID));
GO


CREATE TABLE Library.Loan(
LoanID int IDENTITY(2001,1) NOT NULL PRIMARY KEY,
MemberID int NOT NULL FOREIGN KEY REFERENCES Library.Member (MemberID),
ItemID  int NOT NULL FOREIGN KEY REFERENCES Library.Item (ItemID),
Date_Loaned date NOT NULL,
Duedate date NOT NULL,
DateReturned date  NULL, 
DueFee money NOT NULL);
GO


CREATE TABLE Library.FinePayment(
FinePaymentID int IDENTITY(4001,1) NOT NULL Primary Key,
LoanID  int NOT NULL FOREIGN KEY REFERENCES Library.Loan (LoanID),
PaymentMethod nvarchar(4) NOT NULL CHECK (PaymentMethod LIKE 'Cash' OR PaymentMethod LIKE 'Card'),
PaymentDate datetime NOT  NULL,
AmountPaid money NOT NULL,
Balance money NOT NULL);
GO


--question 2a
DROP FUNCTION IF EXISTS Library.[MatchingCharacter];
GO
--Creating functions for matching characters
CREATE FUNCTION Library.[MatchingCharacter]
( -- Parameters for the function
@string nvarchar(200)
)
RETURNS @Results TABLE
-- Column definitions for the TABLE variable
					(ItemID int, 
					[ItemTitle] nvarchar(200), 
					[Publication_year] int, 
					DateAdded date, 
					DateLost date, 
					ISBN nvarchar(20), 
					ItemTypeID int,
					ItemStatusID int)
AS
BEGIN
	INSERT INTO @Results
	-- SELECT statement with parameter references
	SELECT  *
	FROM 
	(SELECT *
	FROM Library.Item
	WHERE ItemTitle LIKE '%' + @string + '%') AS string
	ORDER BY Publication_year DESC

	RETURN
END;
GO


--inserting into ItemStatus
INSERT INTO Library.ItemStatus
Values( 'On Loan'),( 'Overdue'), ( 'Available' ), ('Lost/Removed');

SELECT *
FROM Library.ItemStatus

--inserting into ItemType
INSERT INTO Library.ItemType
Values( 'Book'), ('Journal'), ('DVD' ),('Other Media');

SELECT *
FROM Library.ItemType

--Inserting values into Item table
INSERT INTO Library.Item
Values('A National Work', 2012, '2008-12-28', '2015-08-09', NULL,12, 3),
('English Legal System', 2010, '2012-07-27', NULL, NULL, 14, 2),
('General Maths', 2002,  '2012-11-22', NULL, '821719101', 11,  1),
('Brighter Life', 1967, '2014-03-27', '2016-04-13',NULL, 13, 4),
('Photography Scope', 2014, '2018-05-08', NULL, NULL,12, 1),
('Human Rights', 2000, '2020-01-01', NULL, NULL, 14, 1),
('General Studies', 1988,  '2014-08-10', NULL, '821719101', 11,  1);
Go

SELECT *
FROM Library.Item
GO


SELECT *
FROM Library.[MatchingCharacter]('al')
GO



--Question 2b
DROP FUNCTION IF EXISTS Library.LessFiveDays
GO

--Creating Function
CREATE FUNCTION Library.LessFiveDays ()
RETURNS TABLE
AS
RETURN
(
    SELECT i.*, t.ItemType, s.itemStatus, DATEDIFF(dd, GETDATE(), l.Duedate) AS Days
    FROM Library.Loan l
    JOIN Library.Item i           
    ON i.ItemID= l.ItemID
    JOIN Library.ItemStatus s
    ON s.ItemStatusID =i.ItemStatusID
    JOIN Library.ItemType t
    ON t.ItemTypeID =i.ItemTypeID
    WHERE  l.DateReturned IS NULL AND DATEDIFF(dd, GETDATE(), l.Duedate) <5
)
GO


--inserting values into the Member's column
INSERT INTO Library.Member
VALUES 
('Muhammed', 'Amao' , '1992-07-05', 'muhammed@gmail.com', '07361927904', NULL, 'Active'),
 ('Joshua', 'Anyang', '1995-08-03', 'joshuaanyang@gmail.com', '07177917072', '2022-08-05','Inactive'),
 ('Gbubemi', 'Erics', '1985-12-12','gbugbemierics@gmail.com', '07469532587', '2014-07-06', 'Inactive'),
 ('Yanju', 'Adegoke', '2002-08-16','yanjuadegoke@gmail.com', '07252719192','2019-05-10' , 'Inactive');
GO

--inserting values into the Login_Details's column
INSERT INTO Library.Login_Details
VALUES 
(1, 'Amao1' ,CONVERT(BINARY(64), 'Amudgwjj1/'), NEWID()),
 (2, 'josha',CONVERT(BINARY(64),'anhgdiwb1'),NEWID()),
 (3,'gbugbe',CONVERT(BINARY(64), 'jhdfhkjw/1'),NEWID()),
 (4, 'Yansade',CONVERT(BINARY(64), 'gafgahqj/3'),NEWID());
GO


SELECT *
FROM LIbrary.Member
GO


--inserting values into loans table
INSERT INTO Library.Loan
VALUES 
(4, 1003, '2022-08-25', '2023-04-25', '2023-04-26', 0),
(3, 1005, '2023-04-22', '2023-04-27', NULL, 0),
(1, 1006, '2023-04-10', '2023-04-11',NULL, 0),
(2, 1007, '2023-01-25', '2023-04-28', NULL, 0);
GO

SELECT *
FROM Library.Loan

--Question 2b

SELECT *
FROM Library.LessFiveDays();

--Question 2c

DROP PROCEDURE IF EXISTS Library.InsertMember;
GO

CREATE PROCEDURE Library.InsertMember 
-- The parameters for the stored procedure 
	(@FirstName nvarchar(50),
	@LastName nvarchar(50),
    @BirthDate date, 
	@EmailAddress nvarchar(50),
	@PhoneNumber nvarchar(25),
	@EndDate date,
	 @Status nvarchar(20))
AS
BEGIN
-- Statements for procedure 
	INSERT INTO Library.Member(
								FirstName,
							    LastName,
								BirthDate, 
								EmailAddress,
								PhoneNumber,
								EndDate,
								Status)
				Values(
							@FirstName,
							@LastName,
							@BirthDate, 
							@EmailAddress,
							@PhoneNumber,
							@EndDate,
							@Status)
END
GO

--QUESTION 2C
--Demonstrating the Library.InsertMember  function

EXEC Library.InsertMember @FirstName= 'Chisom',@LastName='Arogbade',@BirthDate='1950-07-04',
@EmailAddress= NULL, @PhoneNumber=NULL, @EndDate= NULL, @Status= 'Active'
GO


SELECT *
FROM Library.Member;

--Question2d
DROP PROCEDURE IF EXISTS Library.UpdateMember;
GO

CREATE PROCEDURE Library.UpdateMember
-- The parameters for the stored procedure 
	@MemberID int,
	@FirstName nvarchar(50) = NULL,
	@LastName nvarchar(50)=NULL,
    @BirthDate date= NULL, 
	@EmailAddress nvarchar(50)= NULL,
	@PhoneNumber nvarchar(25)= NULL,
	@EndDate date= NULL,
	@Status nvarchar(20)= NULL
AS 
BEGIN 
-- Statements for procedure
	UPDATE Library.Member
	SET
	FirstName = ISNULL(@FirstName, FirstName),
	LastName = ISNULL(@LastName, LastName),
    BirthDate =  ISNULL(@BirthDate, BirthDate),
	EmailAddress=  ISNULL(@EmailAddress, EmailAddress),
	PhoneNumber=  ISNULL(@PhoneNumber, PhoneNumber),
	EndDate = ISNULL(@EndDate, EndDate),
	Status= ISNULL(Status, @Status )
	WHERE MemberID =  @MemberID
END;
GO

--QUESTION 2D
--Demonstrating the Library.UpdateMember  function

Exec Library.UpdateMember @MemberID = 3 ,@Firstname='Francis'
GO

SELECT *
FROM Library.Member

 --Question 3
 DROP VIEW IF EXISTS Library.LoanHistory
 GO

CREATE VIEW Library.LoanHistory
AS
SELECT i.* , s.ItemStatus, t.ItemType, l.LoanID, l.Date_Loaned AS BorrowedDate, l.Duedate,l.DueFee
FROM Library.Loan l
    JOIN Library.Item i           
    ON i.ItemID= l.ItemID
    JOIN Library.ItemStatus s
    ON s.ItemStatusID =i.ItemStatusID
    JOIN Library.ItemType t
    ON t.ItemTypeID =i.ItemTypeID
GO

--Question 3

SELECT *
FROM Library.LoanHistory

SELECT *
FROM Library.Member
GO

--Question 4
DROP TRIGGER IF EXISTS Library.StatusTrigger
GO

CREATE TRIGGER Library.StatusTrigger
ON Library.Loan
AFTER UPDATE
AS 
BEGIN
	IF (SELECT DATEDIFF(dd, DateReturned,GETDATE()) FROM inserted)  >=0
	BEGIN
	UPDATE Library.Item
	SET ItemStatusID= 3
	WHERE ItemID IN (SELECT ItemID FROM inserted)
	END
END

SELECT *
FROM Library.Item


SELECT * 
FROM Library.LOAN

SELECT *
FROM Library.ItemStatus

UPDATE Library.Loan
SET DateReturned = '2023-04-26'
WHERE ItemID = 1003

--Question 5
DROP FUNCTION IF EXISTS Library.NoOfLoans
GO

CREATE FUNCTION Library.NoOfLoans (@date_loaned date)
RETURNS TABLE
AS
RETURN
(
    SELECT Date_Loaned, COUNT(*) AS LoanCount
    FROM Library.Loan
    WHERE Date_Loaned = @date_loaned
    GROUP BY Date_Loaned
)
GO

SELECT * 
FROM Library.Loan

UPDATE Library.Loan
SET DateReturned = '2023-03-26'
WHERE LoanID= 2012

SELECT *
FROM Library.NoOfLoans('2022-08-25')

--QUESTION 7a

DROP PROCEDURE IF EXISTS Library.UpdateDueFee
GO

CREATE PROCEDURE Library.UpdateDueFee
AS
BEGIN
		UPDATE Library.Loan
		SET DueFee = DATEDIFF(dd, Duedate, GETDATE()) * 0.10
		WHERE DateReturned IS NULL AND GETDATE() > Duedate
	END
GO

SELECT*
FROM Library.Loan

Execute Library.UpdateDueFee

SELECT*
FROM Library.Loan

SELECT *
FROM Library.Member


SELECT * 
FROM Library.Member
go

----QUESTION 7a
Drop trigger if exists Library.[Inactive_Member_Trigger]
go

CREATE TRIGGER Library.[Inactive_Member_Trigger]
ON Library.[Member]
AFTER UPDATE
AS
BEGIN TRANSACTION
    BEGIN TRY
  SET NOCOUNT ON;
  IF UPDATE(EndDate) AND NOT EXISTS(SELECT * FROM INSERTED WHERE Status = 'Inactive')
    UPDATE Library.[Member]
    SET Library.[Member].[Status] = 'Inactive'
    FROM Library.[Member]
    INNER JOIN [Inserted] ON Library.[Member].[MemberID] = [Inserted].[MemberID]
    WHERE Library.[Member].[EndDate] IS NOT NULL AND Library.[Member].[EndDate] < GETDATE()

	INSERT INTO Library.[MemberArchive] ([MemberID], [FirstName], [LastName], [BirthDate], [EmailAddress], [PhoneNumber])
    SELECT [Member].[MemberID], [Member].[FirstName], [Member].[LastName], [Member].[BirthDate], [Member].[EmailAddress], [Member].[PhoneNumber]
    FROM Library.[Member]
    INNER JOIN [Inserted] ON [Member].[MemberID] = [Inserted].[MemberID]
    WHERE [Member].[Status] = 'Inactive'

    DELETE FROM Library.[Login_Details]
    WHERE Library.[Login_Details].[MemberID] IN (SELECT [Inserted].[MemberID] FROM [Inserted])
  
    DELETE FROM Library.[Member]
    WHERE Library.[Member].[MemberID] IN (SELECT [Inserted].[MemberID] FROM [Inserted] WHERE [Inserted].[Status] = 'Inactive')
  COMMIT TRANSACTION
    END TRY
  BEGIN CATCH
      IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
      THROW;
    END CATCH

SELECT *
FROM Library.Member

SELECT *
FROM Library.Login_Details

SELECT *
FROM Library.MemberArchive

Update Library.Member
SET EndDate= '2023-04-27'
WHERE MemberID = 1
GO

