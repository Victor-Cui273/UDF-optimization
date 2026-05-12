USE UDF_Optimization;
GO
-- 先备份原函数（可选）
-- 直接修改现有函数
ALTER FUNCTION [dbo].[F_WORKS_LIST] ()
RETURNS @RESULT TABLE
(
    ID_WORK INT,
    CREATE_Date DATETIME,
    MaterialNumber DECIMAL(8,2),
    IS_Complit BIT,
    FIO VARCHAR(255),
    D_DATE varchar(10),
    WorkItemsNotComplit int,
    WorkItemsComplit int,
    FULL_NAME VARCHAR(101),
    StatusId smallint,
    StatusName VARCHAR(255),
    Is_Print bit
)
AS
BEGIN
    -- 预计算每个订单的 WorkItem 计数（基于集合的聚合）
    WITH WorkItemCounts AS (
        SELECT 
            Id_Work,
            SUM(CASE WHEN Is_Complit = 0 THEN 1 ELSE 0 END) AS NotComplit,
            SUM(CASE WHEN Is_Complit = 1 THEN 1 ELSE 0 END) AS Complit
        FROM dbo.WorkItem
        GROUP BY Id_Work
    )
    INSERT INTO @RESULT
    SELECT 
        w.Id_Work,
        w.CREATE_Date,
        w.MaterialNumber,
        w.IS_Complit,
        w.FIO,
        CONVERT(varchar(10), w.CREATE_Date, 104) AS D_DATE,
        ISNULL(wic.NotComplit, 0) AS WorkItemsNotComplit,
        ISNULL(wic.Complit, 0) AS WorkItemsComplit,
        -- 直接拼接员工姓名，避免调用函数
        ISNULL(e.Surname, '') + ' ' + UPPER(LEFT(ISNULL(e.Name, ''), 1)) + '. ' + UPPER(LEFT(ISNULL(e.Patronymic, ''), 1)) + '.' AS FULL_NAME,
        w.StatusId,
        ws.StatusName,
        CASE 
            WHEN w.Print_Date IS NOT NULL 
              OR w.SendToClientDate IS NOT NULL 
              OR w.SendToDoctorDate IS NOT NULL 
              OR w.SendToOrgDate IS NOT NULL 
              OR w.SendToFax IS NOT NULL 
            THEN 1 
            ELSE 0 
        END AS Is_Print
    FROM dbo.Works w
    LEFT JOIN dbo.WorkStatus ws ON w.StatusId = ws.StatusID
    LEFT JOIN dbo.Employee e ON w.Id_Employee = e.Id_Employee
    LEFT JOIN WorkItemCounts wic ON w.Id_Work = wic.Id_Work
    WHERE w.IS_DEL <> 1
    ORDER BY w.Id_Work DESC;
    RETURN;
END;
GO