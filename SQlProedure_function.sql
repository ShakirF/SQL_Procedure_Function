--1) Parametre olarak verilen doğum tarihi ve yaş değerlerini alarak kişi belirtilen yaşı 
--   Yıl - Ay veya Gün olarak doldurup doldurmadığını geri dönen Function.

Create FUNCTION Getbirthday(@birthday DATE, @age INT)
RETURNS NVARCHAR(100)
AS
BEGIN
DECLARE @message NVARCHAR(100)
DECLARE @num NVARCHAR(10)
DECLARE @num2 NVARCHAR (10)
SET @num2 = @age - DATEDIFF(YEAR,@birthday,GETDATE())
SET @num = DATEDIFF(YEAR,@birthday,GETDATE()) - @age
IF DATEDIFF(YEAR,@birthday,GETDATE()) > @age 
SET @message = @num + ' ' + N'il əvvəl bu yaşı tamam olmuşdur'
ElSE IF DATEDIFF(YEAR,@birthday,GETDATE()) = @age AND MONTH(@birthday) - MONTH(GETDATE()) > 0
SET @message = N'İl olaraq doldurmuş, ay olaraq doldurmamışdır'
ElSE IF DATEDIFF(YEAR,@birthday,GETDATE()) = @age AND MONTH(@birthday) - MONTH(GETDATE()) < 0
SET @message = N'İl və ay olaraq doldurmuşdur'
ELSE IF  DATEDIFF(YEAR,@birthday,GETDATE()) = @age AND MONTH(@birthday) - MONTH(GETDATE()) = 0 AND DAY(GETDATE()) - DAY(@birthday) < 0
SET @message = N'İl və ay olaraq doldurmuş, gün olaraq doldurmamışdır'
ELSE IF  DATEDIFF(YEAR,@birthday,GETDATE()) = @age AND MONTH(GETDATE()) - MONTH(@birthday) = 0 AND DAY(GETDATE()) - DAY(@birthday) >= 0
SET @message = N'İl, ay və gün olaraq doldurmuşdur'
ELSE
SET @message = N'Hələ bu yaşının tamam olmağına' + ' ' + @num2 + ' ' +  'il var'
RETURN @message
END




---1) create database -----------------------------------------------------------------------
CREATE DATABASE Exercise
CREATE TABLE Country(
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
CountryName NVARCHAR(50) NOT NULL
);
CREATE TABLE City(
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
CityName NVARCHAR(50) NOT NULL,
CountryId INT FOREIGN KEY REFERENCES Country(Id) NOT NULL
);
CREATE TABLE District(
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
DistrictName NVARCHAR(100) NOT NULL,
CityId INT FOREIGN KEY REFERENCES City(Id) NOT NULL
);
CREATE TABLE Town(
Id INT PRIMARY KEY IDENTITY(1,1) NOT NULL,
TownName NVARCHAR(50) NOT NULL,
DistrictId INT FOREIGN KEY REFERENCES District(Id) NOT NULL
);


----2)create stored procedure CountryAdd---------------------------------------------------
CREATE PROC sp_CountryAdd
	@CountryName   NVARCHAR(50),
	@CountryId     INT OUT
AS 
BEGIN
	IF NOT EXISTS (SELECT * FROM Country WHERE CountryName = @CountryName)	
	BEGIN
		PRINT (N'Ölkə olmadığından database-ə əlavə olundu')
		INSERT INTO Country(CountryName)
		VALUES (@CountryName)
		SET @CountryId =@@IDENTITY;
	END
	ELSE
	BEGIN
		PRINT (N'Ölkə mövcuddur')
		SELECT @CountryId = Id
			FROM Country
			WHERE CountryName =@CountryName
	END
END

--3)create stored procedure CityAdd-------------------------------------------------------------------------------
CREATE PROC sp_CityAdd
	@CityName     NVARCHAR(50),
	@CountryName  NVARCHAR(50),	
	@CountryId	  INT,
	@CityId       INT OUT
AS
BEGIN
	IF EXISTS (SELECT * FROM City c
		JOIN Country cy ON cy.Id  = c.CountryId AND cy.CountryName = @CountryName
		WHERE CityName = @CityName)
	BEGIN
		PRINT (N'Şəhər mövcuddur')
		SELECT @CityId = Id
			FROM City
			WHERE CityName = @CityName
	END
	ELSE
	BEGIN
		INSERT INTO City(CityName,CountryId)
		VALUES	(@CityName,@CountryId)
		SET @CityId = @@IDENTITY
		PRINT (N'Ölkəyə uyğun olaraq şəhər əlavə edildi')
	END
END 

--4)create stored procedure DistrictAdd-------------------------------------------------------------------------------
CREATE PROC sp_DistrictAdd
	@DistrictName   NVARCHAR(50),
	@CityName NVARCHAR(50),
	@CountryName  NVARCHAR(50),	
	@CityId INT,
	@DistrictId  INT OUT
AS
BEGIN
	IF EXISTS (SELECT * FROM District d
		JOIN City c ON c.Id = d.CityId AND c.CityName = @CityName
		JOIN Country cy ON cy.Id  = c.CountryId AND cy.CountryName = @CountryName
		WHERE DistrictName = @DistrictName)
	BEGIN
		PRINT (N'Bölgə mövcuddur')
		SELECT @DistrictId = Id
			FROM District
			WHERE DistrictName = @DistrictName
	END
	ELSE
	BEGIN
		INSERT INTO District (DistrictName,CityId)
		VALUES (@DistrictName,@CityId)
		SET @DistrictId = @@IDENTITY
		PRINT (N'Ölkəyə və şəhərə uyğun olaraq, bölgə əlavə edildi')
	END
END

--5)create stored procedure AdressAdd-------------------------------------------------------------------------------
CREATE PROC sp_AdressAdd
	@CountryName  NVARCHAR(50),				
	@CityName     NVARCHAR(50),				
	@DistrictName NVARCHAR(50),				
	@TownName     NVARCHAR(50)				
AS										
BEGIN 
	IF EXISTS (SELECT t.TownName FROM Town t
		JOIN District d ON  d.Id = t.DistrictId AND d.DistrictName = @DistrictName
		JOIN City c ON c.Id = d.CityId AND c.CityName = @CityName
		JOIN Country cy ON cy.Id  = c.CountryId AND cy.CountryName = @CountryName
		WHERE TownName = @TownName)
	BEGIN
		PRINT (N'Ölkə, şəhər və bölgəyə uyğun olan məhəllə mövcuddur')
	END			
		
	ELSE											
	BEGIN											
		DECLARE @CountryId  INT,					
				@CityId     INT,					
				@DistrictId INT
		EXEC sp_CountryAdd @CountryName, @CountryId OUT
		EXEC sp_CityAdd @CityName,@CountryName,@CountryId, @CityId OUT
		EXEC sp_DistrictAdd @DistrictName,@CityName,@CountryName,@CityId, @DistrictId OUT
		INSERT INTO Town (TownName,DistrictId)
		VALUES (@TownName,@DistrictId)
		PRINT (N'Ölkə, şəhər və bölgəyə uyğun olaraq, məhəllə əlavə edildi')
	END
END



