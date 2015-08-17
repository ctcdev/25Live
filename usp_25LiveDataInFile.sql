USE [ODS]
GO

/****** Object:  StoredProcedure [dbo].[usp_25LiveDataInFile]    Script Date: 8/5/2015 8:07:50 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/****************************************************************************************************************************************************
CREATED:
02/27/2015   Smruthi Madhugiri  This stored procedure is called in order to create the datain.dat file which will feed as an input to 25Live   
MODIFIED:
04/16/2015   Smruthi Madhugiri  Updated the stored procedure to replace day values with the values UCP Interface understands.
04/20/2015   Smruthi Madhugiri  Updated the procedure to have instructor Email instead of Instructor Name.
06/05/2015   Smruthi Madhugiri  Updated the procedure to include ItemNumber to CRN to make it unique.
05/13/2015   David Schieber     Updated the procedure to remove WorkEmail from selection criteria for CTE1 while adding Catalog and RoomName.
					            And replaced WorkEmail with RoomName in CTE2 partition and order by, and CTE5 and CTE4 union order by.
05/14/2015   David Schieber     Updated the procedure to remove EndTime and FinishWeek from CTE2 partition.
06/18/2015   David Schieber     Updated procedure with comment to set NextYearQuarter to hard coded YRQ.
06/30/2015	 David Schieber		Updated procedure to accept variable DataInYearQuarter and apply that to the NextYearQuarter variable.
								Purpose of this update is to allow the DataInYearQuarter variable to be set on the Windows Task Action tab that 
								initiates the CreateDatain/CreateNewFile web application.
****************************************************************************************************************************************************/
CREATE PROCEDURE [dbo].[usp_25LiveDataInFile] @DataInYearQuarter VARCHAR(4) WITH RECOMPILE
AS 
    BEGIN
        SET NOCOUNT ON


        DECLARE @ErrMsg VARCHAR(4000)

        DECLARE @CurrentYearQuarter VARCHAR(4)
        DECLARE @NextYearQuarter VARCHAR(4)
        
        SELECT @CurrentYearQuarter = [dbo].[ufn_getETLYearQuarter]()
        SET @NextYearQuarter = @DataInYearQuarter
		--SET @NextYearQuarter =  (SELECT top 1 YearQuarterID FROM YearQuarter y WHERE y.FirstClassDay > GETDATE())
		--SET @NextYearQuarter = 'B562'
        DECLARE @TimeMarker datetime

		

        BEGIN TRY

        --set the starting to calculate time taken by copying data into HPSATransfer database
        set @TimeMarker = getdate() 
        

/***************************************************************************************************************************************
   Selects Initial Records required for 25live from Class Table in ODS eliminating few records which do not need room assignments 
   like Hospitals and sectionstatusID1 with Z or X are not actaully classes but some other items like fees etc., The arranged classes
   also do not require room assignments.
***************************************************************************************************************************************/
        
;WITH CTE AS
(SELECT replace(RoomID,' ','') as RoomName
	, replace(replace(replace(replace(D.Title, 'Th','R'),'Sa','S'), 'Su','U'), 'DAILY','MTWRF') as Days
	, ClassID
	, ClusterItemNumber
	, StartTime
	, EndTime
	, right('0' + convert(varchar,datepart(hour, StartTime)),2) as StartHours
	, right('0' + convert(varchar,datepart(minute, startTime)),2) as StartMinutes
	, right('0' + convert(varchar,datepart(hour, EndTime)),2) as FinishHours
	, right('0' + convert(varchar,datepart(minute, EndTime)),2) as FinishMinutes
	, 'H' as APDesignator
	, right('0000' + convert(varchar,ClassCapacity),4) as Enrollment
	, Department as DepartmentID
	, convert(varchar,StartDate,112 ) as StartWeek
	, convert(varchar, EndDate, 112) as FinishWeek
	, courseID+Section+ItemNumber as CRN
	, CourseTitle as CourseName
	, Section 
	, CourseNumber as Catalog
	, YearQuarterID as Term
	, E.WorkEmail
FROM vw_Class C left outer join vw_Day D ON C.DayID = D.DayID
LEFT OUTER JOIN vw_Employee E ON E.SID = C.InstructorSID
WHERE YearQuarterID = @NextYearQuarter and ((ISNULL(SectionStatusID1,'') NOT IN ('Z','X'))) and D.Title <> 'ARRANGED'  and ISNULL(RoomID,'') NOT LIKE ('HOS%')
),

/********************************************************************************************************************************************
  Find the list of clustered classes (Classes with same Instructor, StartTime, StartWeek and Days but have different Sections)
*********************************************************************************************************************************************/
CTE1 AS 
(SELECT distinct a.RoomName, a.Days, a.ClassID, a.ClusterItemNumber, a.StartTime, a.EndTime, a.StartHours, a.StartMinutes, a.FinishHours, a.FinishMinutes, a.APDesignator, a.Enrollment, a.DepartmentID, a.StartWeek, a.FinishWeek, a.CRN, a.CourseName, a.Section, a.Catalog, a.Term, a.WorkEmail
FROM CTE a inner join CTE b ON a.StartTime = b.StartTime and a.StartWeek = b.StartWeek and a.Days = b.Days and (a.catalog <> b.catalog or a.section <> b.section) and a.RoomName = b.RoomName),

/***********************************************************************************************************************************************
 Created CTE2 to assign NSM, WSM, HSM, VSM values. The GroupNumber created at this step is important since the grouping and order
 of the NSM, WSM and HSM, VSM values needs to be maintained for 25Live to understand primary class and secondary classes.
***********************************************************************************************************************************************/
CTE2 AS 
(SELECT RoomName, Days, ClassID, ClusterItemNumber, StartTime, endtime, StartHours, StartMinutes, FinishHours, FinishMinutes, APDesignator, Enrollment, DepartmentID, StartWeek, FinishWeek, CRN, CourseName, Section, Catalog, term, WorkEmail, ROW_NUMBER() over (partition by RoomName, starttime, startweek, days order by RoomName, starttime, endtime, startweek, finishweek, days) as groupNumber
from CTE1),

/***********************************************************************************************************************************************
 CTE3 gives us a list of Clustered Classes with the AssignmentField populated
 **********************************************************************************************************************************************/
-- Where Clustered Items is not null 
CTE3 AS
/*(SELECT a.RoomName, a.Days, a.ClassID, a.ClusterItemNumber, a.StartTime, a.EndTime, a.StartHours, a.StartMinutes, a.FinishHours, a.FinishMinutes, a.APDesignator, a.Enrollment, a.DepartmentID, a.StartWeek, a.FinishWeek, a.CRN, a.CourseName, a.Section, a.Catalog, a.Term, a.WorkEmail
, CASE WHEN (a.RoomName IS NULL or a.RoomName = '') and (SUBSTRING(a.ClassID, 1 , 4) = a.ClusterItemNumber) THEN 'NSM'
	   WHEN (a.RoomName IS NULL or a.RoomName = '') and (SUBSTRING(a.ClassID, 1 , 4) <> a.ClusterItemNumber) THEN 'WSM'
	   WHEN (a.RoomName IS NOT NULL) and (SUBSTRING(a.ClassID, 1,4) = a.ClusterItemNumber) THEN 'HSM'
	   WHEN (a.RoomName IS NOT NULL) and (SUBSTRING(a.ClassID, 1,4) <> a.ClusterItemNumber) THEN 'VSM'
  END AS AssigmentField
FROM CTE a 
WHERE a.ClusterItemNumber is not null


UNION ALL
*/
-- Where Clustered Items is null
(SELECT RoomName, Days, ClassID, ClusterItemNumber, StartTime, endtime, StartHours, StartMinutes, FinishHours, FinishMinutes, APDesignator, Enrollment, DepartmentID, StartWeek, FinishWeek, CRN, CourseName, Section, Catalog, term, WorkEmail,
CASE WHEN RoomName IS NULL and GroupNumber = 1 THEN 'NSM'
	 WHEN RoomName IS NULL and GroupNumber <> 1 THEN 'WSM'
	 WHEN RoomName IS NOT NULL and Groupnumber = 1 THEN 'HSM'
	 WHEN RoomName IS NOT NULL AND GroupNumber <> 1 THEN 'VSM'
END AS AssigmentField
FROM CTE2
--WHERE ClusterItemNumber is null
),

/***********************************************************************************************************************************************
 CTE4 gives us a list of Unclustered Classes Unioned with list of clustered classes
 ***********************************************************************************************************************************************/

CTE4 AS
(SELECT distinct a.RoomName, a.Days, a.ClassID, a.StartTime, a.EndTime, a.StartHours, a.StartMinutes, a.FinishHours, a.FinishMinutes, a.APDesignator, a.Enrollment, a.DepartmentID, a.StartWeek, a.FinishWeek, a.CRN, a.CourseName, a.Section, a.Catalog, a.Term, a.WorkEmail
, CASE WHEN a.RoomName IS NULL then 'NSM'
       WHEN a.RoomName IS NOT NULL then 'ASM'	
END AS AssignmentField
FROM CTE a 
WHERE a.ClusterItemNumber is null and a.ClassID NOT IN (select distinct ClassID from CTE3)

UNION ALL

SELECT RoomName, Days, ClassID,  StartTime, endtime, StartHours, StartMinutes, FinishHours, FinishMinutes, APDesignator, Enrollment, DepartmentID, StartWeek, FinishWeek, CRN, CourseName, Section, Catalog, term, WorkEmail,AssigmentField
FROM CTE3
),

/***************************************************************************************************************************************************
 CTE5 is used to help determine the meeting number. Meeting Numbers are required to recognize a class which is same but meet at different schedules.
 In order to determine that we are checking if they are of the same department and have the same coursenumber but different sections
*****************************************************************************************************************************************************/
CTE5 AS
(SELECT distinct a.RoomName, a.Days, a.ClassID, a.StartTime, a.EndTime, a.StartHours, a.StartMinutes, a.FinishHours, a.FinishMinutes, a.APDesignator, a.Enrollment, a.DepartmentID, a.StartWeek, a.FinishWeek, a.CRN, a.CourseName, a.Section, a.Catalog, a.Term, a.WorkEmail, a.AssignmentField FROM CTE4 a inner join CTE4 b ON a.DepartmentID = b.DepartmentID and a.Catalog = b.Catalog and a.Section <> b.Section 
)

SELECT RoomName, Days, ClassID,  StartTime, endtime, StartHours, StartMinutes, FinishHours, FinishMinutes, APDesignator, Enrollment, DepartmentID, StartWeek, FinishWeek, CRN, CourseName, Section, Catalog, term, WorkEmail,AssignmentField, ROW_NUMBER() over (Partition by departmentID+catalog order by departmentID+Catalog) as MeetingNumber
from CTE5 

UNION ALL

SELECT RoomName, Days, ClassID,  StartTime, endtime, StartHours, StartMinutes, FinishHours, FinishMinutes, APDesignator, Enrollment, DepartmentID, StartWeek, FinishWeek, CRN, CourseName, Section, Catalog, term, WorkEmail,AssignmentField, '1' as MeetingNumber
FROM CTE4
WHERE ClassID NOT IN (select distinct ClassID FROM CTE5)
ORDER BY RoomName, Days, StartTime, EndTime, StartWeek, FinishWeek, AssignmentField, DepartmentID, Catalog, MeetingNumber

        
        END TRY
        BEGIN CATCH 
            SET @ErrMsg = ERROR_MESSAGE()
              RETURN 
        END CATCH 
        
        SET NOCOUNT OFF
    END    


GO

