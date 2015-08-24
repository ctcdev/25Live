USE [ODS]
GO

/****** Object:  StoredProcedure [dbo].[usp_25LiveHeadcountFile]    Script Date: 8/13/2015 4:51:47 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Batch submitted through debugger: SQLQuery3.sql|9|0|C:\Users\DSCHIE~1\AppData\Local\Temp\~vsDB94.sql


/****************************************************************************************************************************************************
CREATED:
08/24/2015   David Mielcarek    Added YearQuarter parameter value to CRN response column.
08/13/2015   David Schieber     This stored procedure is called in order to create the headcount<term>.data file which will feed as an input to 
                                25Live. The criteria is substantially copied from usp_25LiveDataInFile.
MODIFIED:

****************************************************************************************************************************************************/
CREATE PROCEDURE [dbo].[usp_25LiveHeadcountFile] @DataInYearQuarter VARCHAR(4) WITH RECOMPILE
AS 
    BEGIN
        SET NOCOUNT ON


        DECLARE @ErrMsg VARCHAR(4000)
		DECLARE @YearQuarter VARCHAR(4)
		      
		SET @YearQuarter = @DataInYearQuarter


        BEGIN TRY

/*****************************************************************************************************************************************************
   Selects and concatenates CourseID, Section, and ItemNumber (the unique class identity) and selects the StudentEnrolled (HPSA: ENR) for each from 
   the Class table in ODS.
   Selects records required for 25live from Class Table in ODS a eliminating few records which do not need room assignments 
   like Hospitals and SectionStatusID1 with Z or X, which are not actaully classes, but some other items like fees, etc. The arranged classes
   also do not require room assignments.
*****************************************************************************************************************************************************/

		SELECT @YearQuarter+CourseID+Section+ItemNumber as CRN
			, StudentsEnrolled
		FROM vw_Class C left outer join vw_Day D ON C.DayID = D.DayID
		WHERE YearQuarterID = @YearQuarter and ((ISNULL(SectionStatusID1,'') NOT IN ('Z','X'))) and D.Title <> 'ARRANGED'  and ISNULL(RoomID,'') NOT LIKE ('HOS%')

        
        END TRY
        BEGIN CATCH 
            SET @ErrMsg = ERROR_MESSAGE()
              RETURN 
        END CATCH 
        
        SET NOCOUNT OFF
    END    



GO

