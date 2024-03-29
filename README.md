# Cohort Retention Analysis - Online Retail Dataset
*Cohort analysis* adalah suatu teknik yang digunakan untuk menganalisis dan memahami perilaku sekelompok individu dari waktu ke waktu. Individu tersebut dikelompokkan berdasarkan karakteristiknya, seperti waktu saat mereka mendaftar untuk suatu layanan atau produk yang dibeli.

Dalam *cohort retention analysis*, pelanggan dikelompokkan secara berbeda berdasarkan waktu saat mereka kembali menggunakan layanan atau membeli produk, mencerminkan metrik yang disebut retensi. 

### Fungsi Cohort Analysis
- Mengetahui kesehatan bisnis
- Memahami pelanggan dengan lebih baik
- Segmentasi pelanggan dengan lebih akurat
- Peningkatan retensi pelanggan
- Meningkatkan produk/layanan untuk untuk meningkatkan minat

## Metodologi
Proyek ini menggunakan tool DBeaver dengan DBMS MySQL untuk melakukan analisis retensi, dan Tableu adalah tool visualisasi yang digunakan. <br>
Berikut ini adalah rincian langkah-langkah yang diambil untuk melaksanakan proyek ini.

 <center><img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/8d2b380f-a4fd-4d94-8715-147f7217cd49" style="width:90%"></center>

 ## Dataset 
 Dataset yang digunakan diperoleh dari [Kaggle](https://www.kaggle.com/datasets/lakshmi25npathi/online-retail-dataset). Ini berisi semua transaksi yang terjadi antara bulan Desember 2010 hingga Desember 2011. Kumpulan data ini berisi semua pembelian yang dilakukan untuk perusahaan retail online yang berbasis di UK. 

## Data Cleaning
Dataset diunduh dalam format CSV yang kemudian diimpor sebagai *flat file* ke DBeaver. Kemudian dilakukan semua proses *data cleaning* sesuai dengan *query* yang terdapat pada file `cohort_analysis.sql`. <br>

Hal pertama yang dilakukan adalah menampilkan seluruh data untuk memberikan gambaran tentang apa yang akan dikerjakan. Di sini dapat dilihat bahwa ada lebih dari lima ratus ribu baris data yang dapat digunakan untuk analisis.

<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/c045f36f-54b6-4bde-b87d-e30c05735312" style="width:100%" alt="Raw Dataset">
</p>
<p style="text-align:center"><em>Raw Dataset</em> </p>


Selanjutnya adalah mengubah format dan tipe data dari kolom `InvoiceDate`, yang sebelumnya bertipe data `VARCHAR` menjadi tipe data `DATE`, agar mempermudah dalam mengelompokkan data berdasarkan tanggal nantinya. 
<!-- ```
UPDATE onlineretail SET InvoiceDate = str_to_date(InvoiceDate, '%m/%d/%Y %H:%i');
ALTER TABLE onlineretail MODIFY COLUMN InvoiceDate DATE;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/716eeda4-e1a9-4245-bae2-af3af0f20f22" style="width:100%" alt="Raw Dataset">
</p>

Selanjutnya adalah mencari tahu apakah terdapat data *null* di dataset tersebut. Karena pada proyek ini sedang melakukan analisis retensi, kolom utama yang digunakan adalah `CustomerID` yang merupakan pengindentifikasi unik untuk setiap pelanggan yang membeli layanan/produk perusahaan. 

Pengecekan data *null* pada kolom `CustomerID` dengan *query* berikut:
<!-- ```
SELECT count(*) FROM onlineretail WHERE CustomerID IS NULL;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/532f6b6f-09cb-468f-a36d-5f2a2bd98bec" style="width:100%" alt="Raw Dataset">
</p>

Dari **541.909**, terdapat **135.080** baris data tidak memiliki *CustomerID*. Sehingga menyisakan **406.829** baris data untuk dianalisis.

Jika diperhatikan bahwa terdapat nilai negatif pada kolom `Quantity`. Kemungkinan besar ini adalah barang yang dikembalikan atau rusak. Ini jelas akan mempengaruhi kolom `UnitPrice`. Jadi data dengan nilai negatif tersebut perlu dihapus.

<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/e0c0944e-179b-4425-83a8-01fec2001081" style="width:100%" alt="negative quantity">
</p>

<!-- ```
DELETE FROM onlineretail WHERE Quantity < 0;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/52a45dc0-042f-472b-a00b-25e723a2529d" style="width:100%" alt="Raw Dataset">
</p>

Ini mengurangi baris data sebesar **8.905**. Sehingga sisa baris pada dataset menjadi **397.924**.

Kita juga akan memeriksa apakah kolom `UnitPrice` juga terdapat nilai negatif atau nol, karena tidak mungkin harga produk di perusahaan bernilai negatif atau nol. Jadi data dengan nilai negatif atau nol tersebut juga perlu dihapus.

<!-- ```
DELETE FROM onlineretail WHERE UnitPrice <= 0;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/93daf33d-99c8-4e54-acda-b001a5280a1d" style="width:100%" alt="Raw Dataset">
</p>

Ini mengurangi baris data sebesar **40**. Sehingga sisa baris pada dataset menjadi **397.884**.

Selanjutnya kita akan memeriksa dan menghapus data duplikat. Ini menunjukkan setiap baris memiliki data yang sama yang dimasukkan lebih dari satu kali. Saya akan membuat CTE (*Common Table Expression*) untuk melakukan tugas ini.

<!-- ```
# DELETE DUPLICATE DATA
WITH dup_check AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY InvoiceNo, StockCode, Quantity ORDER BY OrderDate) flag_dup
	FROM onlineretail
)

-- first add column id
ALTER TABLE onlineretail
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;

--  delete duplicate data
DELETE FROM onlineretail USING onlineretail JOIN dup_check ON onlineretail.id = dup_check.id
WHERE flag_dup > 1;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/0cf0d0c9-5e36-4908-9998-1b320e1f8a83" style="width:100%" alt="Raw Dataset">
</p>

*Query* di atas akan menghapus data duplikat yang berjumlah **5.215** dan menyisakan **392.669** data bersih untuk dianalisis. 

## Performing Cohort Analysis
Dalam melakukan *cohort analysis*, pertama perlu mengelompokkan *customer* berdasarkan bulan mereka melakukan pembelian pertama lalu menyimpannya di tabel cohort.

<!-- ```
CREATE TABLE cohort
SELECT
	CustomerID,
	MIN(OrderDate) first_purchase_date,
	DATE_FORMAT(MIN(OrderDate), '%Y-%m-01') AS cohort_date
FROM onlineretail
GROUP BY CustomerID;
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/8b194dbe-9c70-448f-829b-b4bbde3f8c0f" style="width:100%" alt="Raw Dataset">
</p>

Selanjutnya adalah membuat *cohort index*. Ini pada dasarnya adalah representasi bilangan bulat dari jumlah bulan yang berlalu sejak pembelian pertama *customer*. Di sini kita akan menggabungkan dua tabel yaitu tabel utama **onlineretail** dengan tabel **cohort** untuk memungkinkan menghitung *cohort index*. Hasil *query* ini akan disimpan dalam tabel **cohort_retention**.

<!-- ```
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
		FROM onlineretail o
		LEFT JOIN cohort c
		ON o.CustomerID = c.CustomerID
		)mm
	)mmm
``` -->
<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/921265a8-c754-4f87-a4b9-8479a57f0eb2" style="width:100%" alt="Raw Dataset">
</p>

Dengan menjalankan *query* di atas kita dapat melihat pelanggan yang kembali setelah pembelian pertama mereka, kita juga bisa melihat berapa bulan berlalu sebelum pembelian berikutnya, dan juga *customer* yang tidak kembali membeli sama sekali. 

Selanjutnya adalah membuat tabel pivot yang berupa ringkasan data sehingga dapat melihat berapa banyak *customer* yang termasuk ke dalam setiap kelompok. 

<p>
<img src="https://github.com/fadhlurrahmann/cohort-analysis-online-retail/assets/64050390/8dc631b3-b47c-4097-9967-9638857f9924" style="width:100%" alt="Pivot Table">
</p>

Dari gambar di atas dapat dilihat bahwa terdapat *customer* yang berjumlah 885 pada bulan *cohort* Desember 2010 , namun hanya 324 yang kembali. Selain itu juga dapat dilihat tren lainnya seiring berjalannya waktu. 

## Data Visualization
Untuk lebih mudah dalam memahami dan menginterpretasikan data, berikut ini [link visualisasi data](https://public.tableau.com/views/CohortAnalysis_16831834527590/CohortRetentionDash?:language=en-US&:display_count=n&:origin=viz_share_link) tersebut dengan menggunakan Tableu.

- Y-axis merepresentasikan jumlah *customer* yang membeli produk untuk pertama kalinya setiap bulan.
- X-axis merepresentasikan jumlah *customer* yang aktif di bulan-bulan berikutnya sejak pembelian pertama.
- Pada tabel *cohort retention rate*, setiap kotak mewakili persentase *customer* yang kembali pada bulan tertentu. Bulan *cohort* pertama akan selalu menampilkan 100% karena ini adalah bulan dasar *customer* melakukan pembelian pertama.

Sebagai contoh bulan Desember 2010, dapat dilihat distribusinya sepanjang bulan. Semakin gelap warnanya, semakin banyak *customer* yang kembali, semakin terang warnanya, semakin sedikit jumlah *customer* yang kembali. Jika dilihat hingga bulan ke-12, maka akan terlihat peningkatan signifikan dalam jumlah *customer* yang kembali. Kemungkinan peningkatan tersebut bertepatan dengan musim liburan, sehingga *customer* akan kembali untuk membeli produk saat liburan.

Kita juga dapat membacanya secara vertikal untuk membandingkan nilai antar kelompok (*cohort*). Dan terakhir, kita bisa membacanya secara diagonal untuk melihat bulan kalender. Hal ini sangat berguna jika ingin mencoba menemukan masalah dalam jangka waktu tertentu. Dapat dilihat bahwa ada perbedaan yang signifikan antara kelompok bulan Desember 2010 dan bulan Januari 2011. Tampaknya juga akuisisi *customer* menurun sepanjang periode tersebut. 

Berdasarkan analisis *cohort* tersebut, dapat dieksplorasi lebih banyak wawasan berdasarkan data tersebut. Dengan lebih banyak pertanyaan dan penelitian dapat membantu memahami pola perilaku *customer* di setiap bulannya.