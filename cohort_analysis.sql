SHOW DATABASES;
USE online_retail;
SHOW tables;
SELECT * FROM onlineretail;
DESCRIBE onlineretail;

# CLEANING AND PREPROCESSING DATA 

-- ubah tipe data InvoiceNo, InvoiceDate, CustomerID
ALTER TABLE onlineretail MODIFY COLUMN InvoiceNo VARCHAR(50);
ALTER TABLE onlineretail MODIFY COLUMN CustomerID VARCHAR(50);

-- Memperbaiki format tanggal 
UPDATE onlineretail SET InvoiceDate = str_to_date(InvoiceDate, '%m/%d/%Y %H:%i');
ALTER TABLE onlineretail MODIFY COLUMN InvoiceDate DATE;

-- Menambah kolom bulan dan tahun
ALTER TABLE onlineretail ADD COLUMN InvoiceMonth INT;
ALTER TABLE onlineretail ADD COLUMN InvoiceYear INT;
UPDATE onlineretail SET InvoiceMonth = DATE_FORMAT(InvoiceDate, '%m');
UPDATE onlineretail SET InvoiceYear = DATE_FORMAT(InvoiceDate, '%Y');

-- ubah nama kolom
ALTER TABLE onlineretail
RENAME COLUMN InvoiceDate TO OrderDate;


-- hapus data null
DELETE FROM onlineretail WHERE InvoiceNo IS NULL; 
DELETE FROM onlineretail WHERE CustomerID IS NULL; 

-- hapus data Quantity < 0
DELETE FROM onlineretail WHERE Quantity < 0;

-- hapus data dengan harga (UnitPrice) negatif atau nol
DELETE FROM onlineretail WHERE UnitPrice <= 0;

-- Menambah kolom baru untuk total pembelian
ALTER TABLE onlineretail ADD COLUMN TotalPrice FLOAT;
UPDATE onlineretail SET TotalPrice = Quantity * UnitPrice;


# CHECK AND DELETE DUPLICATE DATA
WITH dup_check AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY OrderDate) flag_dup
	FROM onlineretail
)

-- CHECK DUPLICATE DATA
SELECT flag_dup, COUNT(*) AS c FROM dup_check GROUP BY flag_dup HAVING c > 1; -- there is 5215 duplicate records

-- DELETE DUPLICATE DATA
-- first add column id
ALTER TABLE onlineretail
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

--  delete duplicate data
DELETE FROM onlineretail USING onlineretail JOIN dup_check ON onlineretail.id = dup_check.id
WHERE flag_dup > 1;

-- check cleaned data
SELECT COUNT(*) FROM onlineretail;

	
# COHORT ANALYSIS
CREATE TABLE cohort_raw
SELECT
	CustomerID,
	MIN(OrderDate) first_purchase_date,
	DATE_FORMAT(MIN(OrderDate), '%Y-%m-01') AS cohort_date
FROM onlineretail
GROUP BY CustomerID


-- Creating the Cohort Index using sub query
CREATE TABLE cohort_retention
SELECT
	mmm.*,
	(year_diff * 12 + month_diff + 1) as cohort_index
FROM
	(
	SELECT
		mm.*,
		(invoice_year - cohort_year) as year_diff,
		(invoice_month - cohort_month) as month_diff
	FROM
		(
		SELECT
			o.*,
			c.Cohort_Date,
			year(o.OrderDate) invoice_year,
			month(o.OrderDate) invoice_month,
			year(c.Cohort_Date) cohort_year,					
			month(c.Cohort_Date) cohort_month
		FROM onlineretail_raw o
		LEFT JOIN cohort_raw c
		ON o.CustomerID = c.CustomerID
		)mm
	)mmm



-- Pivot data to see the cohort table
CREATE TABLE cohort_pivot
SELECT 
  Cohort_Date,
  COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) AS '1',
  COUNT(DISTINCT CASE WHEN cohort_index = 2 THEN CustomerID END) AS '2',
  COUNT(DISTINCT CASE WHEN cohort_index = 3 THEN CustomerID END) AS '3',
  COUNT(DISTINCT CASE WHEN cohort_index = 4 THEN CustomerID END) AS '4',
  COUNT(DISTINCT CASE WHEN cohort_index = 5 THEN CustomerID END) AS '5',
  COUNT(DISTINCT CASE WHEN cohort_index = 6 THEN CustomerID END) AS '6',
  COUNT(DISTINCT CASE WHEN cohort_index = 7 THEN CustomerID END) AS '7',
  COUNT(DISTINCT CASE WHEN cohort_index = 8 THEN CustomerID END) AS '8',
  COUNT(DISTINCT CASE WHEN cohort_index = 9 THEN CustomerID END) AS '9',
  COUNT(DISTINCT CASE WHEN cohort_index = 10 THEN CustomerID END) AS '10',
  COUNT(DISTINCT CASE WHEN cohort_index = 11 THEN CustomerID END) AS '11',
  COUNT(DISTINCT CASE WHEN cohort_index = 12 THEN CustomerID END) AS '12',
  COUNT(DISTINCT CASE WHEN cohort_index = 13 THEN CustomerID END) AS '13'
FROM cohort_retention
WHERE cohort_index BETWEEN 1 AND 13
GROUP BY 1;

SELECT * 
FROM cohort_pivot;

SELECT 
	Cohort_Date,
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2)  AS '1',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 2 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '2',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 3 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '3',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 4 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '4',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 5 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '5',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 6 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '6',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 7 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '7',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 8 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '8',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 9 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '9',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 10 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '10',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 11 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '11',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 12 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '12',
	ROUND(1.0 * COUNT(DISTINCT CASE WHEN cohort_index = 13 THEN CustomerID END) / COUNT(DISTINCT CASE WHEN cohort_index = 1 THEN CustomerID END) * 100, 2) AS '13'
FROM cohort_retention
WHERE cohort_index BETWEEN 1 AND 13
GROUP BY 1;
