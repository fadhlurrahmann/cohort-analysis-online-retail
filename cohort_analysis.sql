show databases;
use online_retail;
show tables;
select * from onlineretail;
-- drop table onlineretail;
describe onlineretail;

# CLEANING AND PREPROCESSING 

-- ubah tipe data InvoiceNo, InvoiceDate, CustomerID
alter table onlineretail modify column InvoiceNo VARCHAR(50);
alter table onlineretail modify column CustomerID VARCHAR(50);

-- Memperbaiki format tanggal 
update onlineretail set InvoiceDate = str_to_date(InvoiceDate, '%m/%d/%Y %H:%i');
alter table onlineretail modify column InvoiceDate Date;

-- hapus data null
delete from onlineretail where InvoiceNo is null; 
delete from onlineretail where CustomerID is null;

-- hapus data Quantity < 0
delete from onlineretail where Quantity < 0;

-- hapus data dengan harga (UnitPrice) negatif atau nol
delete from onlineretail where UnitPrice <= 0;

-- Menambah kolom baru untuk total pembelian
alter table onlineretail add column TotalPrice FLOAT;
update onlineretail set TotalPrice = Quantity * UnitPrice;



# CHECK AND DELETE DUPLICATE ROW
with dup_check as(
	select *, row_number() over(partition by InvoiceNo, StockCode, Quantity order by OrderDate) flag_dup
	from onlineretail
)
-- CHECK DUPLICATE ROW
select flag_dup, count(*) as c from dup_check group by flag_dup having c > 1; -- there is 512 duplicate row

-- DELETE DUPLICATE ROW
-- first add column id
alter table onlineretail
add column id INT auto_increment primary key
--  delete duplicate data
delete from onlineretail using onlineretail join dup_check on onlineretail.id = dup_check.id
where flag_dup > 1

-- check cleaned data
select count(*) from onlineretail o 

-- Menambah kolom bulan dan tahun
alter table onlineretail add column InvoiceMonth INT;
alter table onlineretail add column InvoiceYear INT;
update onlineretail set InvoiceMonth = date_format(InvoiceDate, '%m');
update onlineretail set InvoiceYear = date_format(InvoiceDate, '%Y');

-- ubah nama kolom
alter table onlineretail
rename column InvoiceDate to OrderDate;

alter table onlineretail
rename column customer_id to CustomerID;



# COHORT ANALYSIS 1 (REF: CHATGPT)

--  Pilih data yang dibutuhkan (tanggal pembelian dan id pelanggan)
select
	OrderDate as CohortMonth,
	CustomerID,
	count(distinct InvoiceNo) as TotalOrders
from onlineretail
group by
	CohortMonth,
	CustomerID;

-- Buat cohort dengan membagi pelanggan berdasarkan bulan pertama pembelian
with CohortData as (
	select
		CustomerID,
		MIN(OrderDate) as CohortMonth
	from onlineretail
	group by CustomerID
)

-- Gabungkan data pembelian pelanggan dengan data cohort
select
	CohortData.CustomerID,
	CohortData.CohortMonth,
	OrderDate,
	timestampdiff(month, CohortData.CohortMonth, OrderDate) as CohortIndex,
	count(distinct InvoiceNo) TotalOrders
from 
	CohortData
join 
	onlineretail on CohortData.CustomerID = onlineretail.CustomerID
group by
	1,2

-- Hitung retention rate (persentase pelanggan yang kembali membeli) setiap kelompok cohort pada setiap bulan
with CohortData as (
	select
		CustomerID,
		DATE_FORMAT(MIN(OrderDate), '%Y-%m') as CohortMonth
	from onlineretail
	group by CustomerID
), CohortOrders as (
	select
		CohortData.CustomerID,
		CohortData.CohortMonth as CohortMonth,
		timestampdiff(month, MIN(OrderDate), OrderDate) as CohortIndex,
		count(distinct InvoiceNo) as TotalOrders
	from 
		CohortData
	join 
		onlineretail on CohortData.CustomerID = onlineretail.CustomerID
	group by
		1, 2
), CohortRetention as (
	select
		CohortMonth,
		CohortIndex,
		TotalOrders,
		COUNT(DISTINCT CASE WHEN CohortIndex = 0 THEN CustomerID END) AS CohortSize,
	    COUNT(DISTINCT CASE WHEN CohortIndex > 0 AND TotalOrders > 0 THEN CustomerID END) AS RetainedCustomers
	from CohortOrders
	group by 1,2,3
)

select
	CohortMonth,
	CohortSize,
	RetainedCustomers,
	round(RetainedCustomers / CohortSize * 100, 2) as RetentionRate
from CohortRetention
group by
	CohortMonth,
	CohortIndex
	

	
# COHORT ANALYSIS 2 (REF: https://selectfrom.dev/performing-cohort-retention-analysis-using-sql-afe1b268dbf9)
	
create table cohort
select
	CustomerID,
	min(OrderDate) first_purchase_date,
	date_format(min(OrderDate), '%Y-%m-01') as cohort_date
from onlineretail
group by CustomerID



-- Creating the cohort index using CTE 
with Cohort as (
	select
		o.*,
		c.cohort_date,
		year(o.OrderDate) invoice_year,
		month(o.OrderDate) invoice_month,
		year(c.cohort_date) cohort_year,
		month(c.cohort_date) cohort_month
	from onlineretail o
	left join cohort c
	on o.CustomerID = c.CustomerID
), CohortIndex as (
	select
		*,
		(invoice_year - cohort_year) as year_diff,
		(invoice_month - cohort_month) as month_diff
	from Cohort
)

select
	*,
	(year_diff * 12 + month_diff + 1) as cohort_index
from CohortIndex
	

-- Creating the Cohort Index using sub query
create table cohort_retention
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
				FROM onlineretail o
				LEFT JOIN cohort c
					ON o.CustomerID = c.CustomerID
			)mm
	)mmm



-- Pivot data to see the cohort table
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
