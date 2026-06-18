
create database Superstore;
use Superstore;


 ----Ümumi Biznes KPI-ları (Satış, Gəlir, Sifariş Sayı)
SELECT 
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Gəlir],
    COUNT(DISTINCT [Order ID]) AS [Toplam Sifariş Sayı],
    ROUND(AVG(Discount) * 100, 2) AS [Ortalama Endirim %]
FROM Orders;
------------------------------------------------------------------------------------------------------------------------
                                                                                   
 ----Ən çox satılan məhsulların siyahısı (Top 10)
SELECT TOP 10
    [Product ID],
    [Product Name],
    [Category],
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Gəlir]
FROM Orders
GROUP BY [Product ID], [Product Name], [Category]
ORDER BY [Toplam Satış] DESC;

----------------------------------------------------------------------------------------------------------------    

-----Ən gəlirli bölgələr və ştatlar (Region və State/Province üzrə)
SELECT 
    [Region],
    [State/Province],
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Gəlir],
    -- Gəlir marjası % (Profit Margin)
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS [Gəlir Marjası %]
FROM Orders
GROUP BY [Region], [State/Province]
ORDER BY [Gəlir Marjası %] DESC;



-----------------------------------------------------------------------------------------------------------                                                                           
 -----Ən çox zərər edən məhsul kateqoriyaları və alt-kateqoriyalar (Category və Sub-Category üzrə)
SELECT 
    [Category],
    [Sub-Category],
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Zərər]
FROM Orders
GROUP BY [Category], [Sub-Category]
HAVING SUM(Profit) < 0
ORDER BY [Toplam Zərər] ASC;

-------------------------------------------------------------------------------------------------------------

---Sifarişlərin çatdırılma müddətinin analizi (Ship Mode üzrə)
SELECT 
    [Ship Mode],
    COUNT([Order ID]) AS [Sifariş Sayı],
    AVG(DATEDIFF(day, [Order Date], [Ship Date])) AS [Ortalama Çatdırılma Günü]
FROM Orders
GROUP BY [Ship Mode]
ORDER BY [Ortalama Çatdırılma Günü] ASC;

---------------------------------------------------------------------------------------------------------------

  -----Müştəri kateqoriyalarına görə ümumi satış və müştəri başına ortalama xərc
SELECT 
    MusteriTipi AS [Müştəri Kateqoriyası],
    COUNT([Customer ID]) AS [Müştəri Sayı],
    ROUND(SUM(ToplamXerc), 2) AS [Ümumi Satış],
    ROUND(AVG(ToplamXerc), 2) AS [Müştəri Başına Ortalama Xərc]
FROM 
(
    SELECT 
        [Customer ID],
        COUNT(DISTINCT [Order ID]) AS SifarisSayi,
        SUM(Sales) AS ToplamXerc,
        CASE 
            WHEN COUNT(DISTINCT [Order ID]) >= 13 THEN 'VIP'
            WHEN COUNT(DISTINCT [Order ID]) BETWEEN 5 AND 12 THEN 'Daimi Müşteri'
            ELSE 'Az Aktiv ya Yeni Müşteri'
        END AS MusteriTipi
    FROM Orders
    GROUP BY [Customer ID]
) AS MusteriAnalizi
GROUP BY MusteriTipi
ORDER BY [Ümumi Satış] DESC; 

---------------------------------------------------------------------------------------------------------------------------------------------------                                                                  


 ----İllik və rüblük satış və gəlir analizi
WITH QuarterDetails AS (
    SELECT 
        YEAR([Order Date]) AS [İl],
        'R' + DATENAME(quarter, [Order Date]) AS [Rüb],
        [Order ID],
        Sales,
        Profit
    FROM Orders
)
SELECT 
    [İl],
    [Rüb],
    COUNT(DISTINCT [Order ID]) AS [Toplam Sifariş],
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Gəlir]
FROM QuarterDetails
GROUP BY [İl], [Rüb]
ORDER BY [İl] ASC, [Rüb] ASC;


---------------------------------------------------------------------------------------------------------------------------

 ------Ən yüksək gəlir və marja ilə bölgə və alt-kateqoriyalar
SELECT 
    [Region],
    [Sub-Category],
    ROUND(SUM(Sales), 2) AS [Toplam Satış],
    ROUND(SUM(Profit), 2) AS [Toplam Mənfəət],
    ROUND((SUM(Profit) / SUM(Sales)) * 100, 2) AS [Profit Margin %]
FROM Orders
GROUP BY [Region], [Sub-Category]
HAVING SUM(Profit) > 0 AND (SUM(Profit) / SUM(Sales)) * 100 > 15
ORDER BY [Region] ASC, [Toplam Mənfəət] DESC;


                                                  


-----------------------------------------------------------------------------------------------------------------------------------------
 -----Aylıq satış artımını hesablamaq üçün LAG funksiyasından istifadə (Month-over-Month Growth Analysis)
WITH MonthlySales AS (
    SELECT 
        YEAR([Order Date]) AS SalesYear,
        MONTH([Order Date]) AS SalesMonth,
        SUM(Sales) AS CurrentMonthSales
    FROM Orders
    GROUP BY YEAR([Order Date]), MONTH([Order Date])
),
LaggedSales AS (
    SELECT 
        SalesYear,
        SalesMonth,
        CurrentMonthSales,
        LAG(CurrentMonthSales, 1) OVER (ORDER BY SalesYear, SalesMonth) AS PreviousMonthSales
    FROM MonthlySales
)
SELECT 
    SalesYear AS [İl],
    SalesMonth AS [Ay],
    ROUND(CurrentMonthSales, 2) AS [Cari Ay Satış],
    ROUND(PreviousMonthSales, 2) AS [Əvvəlki Ay Satış],
    ROUND(((CurrentMonthSales - PreviousMonthSales) / NULLIF(PreviousMonthSales, 0)) * 100, 2) AS [MoM Growth %]
FROM LaggedSales
ORDER BY [İl] ASC, [Ay] ASC;
                                                               
------------------------------------------------------------------------------------------------------------------------------------------------                                                                        
--------Hər regionun ən yaxşı 3 müştərisini tapmaq üçün DENSE_RANK funksiyasından istifadə
WITH CustomerRanking AS (
    SELECT 
        [Region],
        [Customer ID],
        [Customer Name],
        ROUND(SUM(Sales), 2) AS [Toplam Alış-Veriş],
        DENSE_RANK() OVER (PARTITION BY [Region] ORDER BY SUM(Sales) DESC) AS SiraNo
    FROM Orders
    GROUP BY [Region], [Customer ID], [Customer Name]
)
SELECT 
    [Region],
    SiraNo AS [Region Daxili Reytinq],
    [Customer ID],
    [Customer Name],
    [Toplam Alış-Veriş]
FROM CustomerRanking
WHERE SiraNo <= 3
ORDER BY [Region] ASC, SiraNo ASC;
                                                
-----------------------------------------------------------------------------------------------------------------------------------------------
--hər gün üçün satışların kumulyativ cəmini hesablamaq üçün SUM() OVER() funksiyasından istifadə
WITH DailySales AS (
    SELECT 
        [Order Date],
        SUM(Sales) AS DailyTotal
    FROM Orders
    WHERE YEAR([Order Date]) = 2025
    GROUP BY [Order Date]
  --ORDER BY [Order Date]
)
SELECT 
    [Order Date],
    ROUND(DailyTotal, 2) AS [Günlük Satış],
    ROUND(SUM(DailyTotal) OVER (ORDER BY [Order Date] ), 2) AS [Kumulyativ Toplam (YTD)]
FROM DailySales
ORDER BY [Order Date] ASC;


