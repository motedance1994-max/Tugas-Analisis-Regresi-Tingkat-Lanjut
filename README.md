# Perbandingan Statistika Inferensial vs Prediktif — Abalone

Paket proposal proyek magister, panduan materi/presentasi, PowerPoint tujuh slide,
laporan ringkas lima halaman, R Markdown, kode, dan dashboard tiga tab.
Disusun dari CSV, skrip R, dan gambar instruksi yang diunggah pengguna.
Tanggal penyusunan: 28 September 2026.

## MULAI DI SINI

1. Ekstrak ZIP ke folder biasa. Jangan menjalankan berkas dari dalam ZIP.
2. Buka `dokumen/Proposal_Abalone.docx` dan `dokumen/Panduan_Materi_dan_Presentasi_Abalone.docx`.
3. Buka `dokumen/Presentasi_Abalone_7_Slide.pptx`. Teks dan tabel dapat diedit;
   catatan pembicara ada pada Notes. Isi nama kedua anggota dan mata kuliah.
4. Untuk demo langsung tanpa memasang R, buka `03_Dashboard_Offline.html` di browser desktop.
   Tunggu pemuatan model. Semua data/model ada di dalam berkas; tidak memerlukan server/internet.
   Berkas ini cukup besar karena memuat 300 pohon, bukan hanya gambar dashboard.
5. Untuk menjalankan analisis R, ikuti bagian berikut.

## Status eksekusi yang WAJIB dibedakan

| Komponen | Status pada lingkungan penyusun |
|---|---|
| Dataset CSV dan salinan sumber | Dibaca dan dihitung; nilai data tidak diubah |
| Analisis pendamping Python | Dieksekusi; versi dan hash dicatat |
| Dashboard offline HTML / JavaScript | Diuji interaksi dan prediksi; menggunakan model Python |
| Skrip analisis R | Disiapkan dan ditinjau; BELUM DIEKSEKUSI karena runtime R tidak tersedia |
| R Markdown | Disiapkan; BELUM di-Knit / render dengan R |
| R Shiny | Disiapkan; BELUM diuji saat berjalan dengan R |
| Word dan PowerPoint | Dibuat sebagai berkas asli; dirender untuk pemeriksaan tata letak |

Angka pada proposal/panduan/laporan/PPT dan dashboard offline adalah **hasil pendamping
Python**, bukan hasil eksekusi R. Split dan fold mengikuti skrip sumber, tetapi
implementasi pohon/Random Forest berbeda. Jangan mengubah label menjadi “hasil R”
tanpa menjalankan R dan mengganti tabel beserta kesimpulannya berdasarkan output R.
Berkas visual dari percakapan sebelumnya yang memakai pembagian data lain tidak digunakan.

## Menjalankan R / RStudio

Buka `Abalone_Project.Rproj`. Working directory harus folder proyek yang berisi `data/`.
Instalasi paket memerlukan internet. Setelah paket tersedia, data dibaca dari CSV lokal.
Jalankan pada Console:

```r
source("00_Instal_Paket.R")  # cukup saat ada paket yang belum terpasang
source("01_Analisis_Abalone.R")
hasil <- analisis_abalone()

# Membuat notebook HTML dengan keluaran R (menghitung ulang analisis)
rmarkdown::render("02_Notebook_Abalone.Rmd")

# Menjalankan dashboard R sesudah hasil_R/model_dan_hasil.rds terbentuk
shiny::runApp(".")
```

Paket: `rpart`, `randomForest`, `shiny`, `rmarkdown`, `knitr`.
RStudio biasanya menyediakan Pandoc untuk render HTML. Jika render meminta Pandoc,
pastikan Pandoc tersedia melalui instalasi RStudio atau instalasi Pandoc lokal.
Tidak perlu paket ucimlrepo: tugas menggunakan CSV unggahan, bukan mengunduh ulang dataset.

Skrip juga dapat dijalankan dari terminal pada folder proyek:

```sh
Rscript 01_Analisis_Abalone.R data/abalone.csv hasil_R
```

`source("01_Analisis_Abalone.R")` hanya mendefinisikan fungsi. Panggil
`analisis_abalone()` untuk menjalankan analisis. Benchmark rpart dan RF diwajibkan;
program berhenti dengan pesan pemasangan jika paket tidak ada, bukan diam-diam melewati model.
Bila memakai jalur Windows, gunakan `C:/folder/data.csv` atau escape setiap backslash.

## Isi paket dan pemenuhan instruksi gambar

| Permintaan | Berkas / implementasi |
|---|---|
| Proposal | `dokumen/Proposal_Abalone.docx` (7 halaman) |
| Materi + panduan presentasi | `dokumen/Panduan_Materi_dan_Presentasi_Abalone.docx` (8 halaman), manual, naskah 7 slide, enam jawaban diskusi |
| PPT maksimal 7 slide | `dokumen/Presentasi_Abalone_7_Slide.pptx` (7 slide, catatan pembicara) |
| Laporan 3–5 halaman | `dokumen/Laporan_Ringkas_Abalone.docx` (5 halaman; pendamping Python) |
| Notebook/R Markdown | `02_Notebook_Abalone.Rmd` |
| Source code | `01_Analisis_Abalone.R`, `app.R`; Python terpisah `04_Verifikasi_Python.py` |
| Dashboard maksimal 3 tab | `app.R` (Shiny) dan `03_Dashboard_Offline.html` (pendamping Python); masing-masing tepat tiga tab |
| Demo sekitar 3 menit | Skenario 180 detik dalam panduan, Notes slide 7, dan bagian demo di bawah |
| README / reproduksibilitas | Berkas ini, `CHANGELOG.md`, `TEST_STATUS.md`, versi perangkat lunak, hash, manifest split/fold |
| Data dictionary | `DATA_DICTIONARY.md` dan `DATA_DICTIONARY.csv` |
| Sumber asli | `original/Perbandingan_Inferensial_Prediktif_Abalone_asli.R`; `data/abalone.csv`; gambar instruksi di `assets/` |

## Protokol sumber yang dipertahankan

- Inferensi OLS sederhana dan OLS berganda menggunakan seluruh 4.177 baris.
- Target `Rings`; umur pendekatan = Rings + 1,5. Age tidak boleh menjadi prediktor.
- Sex memiliki acuan F; kategori I berarti infant.
- Model sederhana: `Rings ~ Shell_weight`; model berganda: Sex dan tujuh fitur numerik.
- Pembagian LCG Park–Miller: state awal 2026, modulus 2147483647, pengali 48271.
  Skor diurutkan, 3.341 baris latih dan 836 baris uji.
- Fold 1–5 berulang pada urutan latih. Pilih model berdasarkan RMSE gabungan prediksi OOF.
- Mean, OLS sederhana, OLS berganda, pohon, RF dilatih ulang di setiap fold.
- Semua model prediktif akhir hanya dilatih pada data latih. Model inferensi seluruh
  data tidak digunakan untuk menghitung skor uji.
- R: rpart cp=0.005, minbucket=15, xval=0; randomForest ntree=300, mtry=3.
  Seed RF fold=2026+k dan final=3030.
- Tidak ada tuning atau pemilihan ulang setelah membaca skor uji.
- Baris audit Height<=0 atau>0.3 tetap dalam analisis utama; sensitivitas dipisahkan.

## Mengapa hasil Python bukan hasil R?

Python memakai statsmodels OLS serta scikit-learn untuk pohon/RF. Sex menjadi dua
kolom dummy, sedangkan implementasi R menggunakan faktor. OLS sepadan secara matematis
untuk desain yang sama. Pohon sklearn menggunakan min_samples_leaf=15 tanpa pemetaan cp.
RF sklearn memakai 300 pohon, max_features=3, min_samples_leaf=1; ini bukan konfigurasi
identik dengan implementasi randomForest R. Generator acak, pemilihan split pohon,
pengodean faktor, dan detail paket berbeda. Nilai seed sama tidak menyamakan semua hasil.

Angka pendamping (urutan menurut CV RMSE):

| Model | CV RMSE | Uji MAE | Uji RMSE | Uji R² |
|---|---:|---:|---:|---:|
| Random Forest | 2,141 | 1,539 | 2,243 | 0,5452 |
| Regresi berganda | 2,222 | 1,549 | 2,214 | 0,5571 |
| Pohon regresi | 2,296 | 1,671 | 2,426 | 0,4681 |
| Regresi sederhana | 2,494 | 1,837 | 2,579 | 0,3989 |
| Rata-rata | 3,198 | 2,395 | 3,327 | −0,0002 |

RF dipilih oleh CV, tetapi RMSE uji OLS berganda sedikit lebih rendah.
Selisih RMSE RF−OLS = 0,0296 Rings; CI bootstrap berpasangan 95%
[−0,0602; 0,1260] mencakup nol. Tidak ada dasar kuat untuk klaim keunggulan pasti.
Bootstrap 2.000 kali mengulang baris uji dengan model tetap: CI kondisional, bukan
interval prediksi individu dan tidak mencakup variasi pelatihan.

## Tiga tab dashboard dan demo 180 detik

| Waktu | Aksi | Anggota |
|---|---|---|
| 00:00–00:45 | Tab1 Data & EDA: jumlah data, filter F (1.307 baris), kembali semua, audit Height | 1 |
| 00:45–01:30 | Tab2 Model & diagnostik: CI HC3, VIF, residual dan benchmark | 1 |
| 01:30–02:30 | Tab3 Prediksi & benchmark: contoh latih, ubah Shell_weight sedikit, hitung, bandingkan lima model | 2 |
| 02:30–03:00 | Kembalikan contoh; jelaskan label Python/R dan keterbatasan prediksi titik | 2 |

Jangan mengubah prediktor ke nilai tidak masuk akal hanya untuk mendapatkan hasil tertentu.
Rentang marginal tidak menjamin kewajaran kombinasi pengukuran. Intervensi input bukan
estimasi efek kausal. Benchmark tidak berubah ketika slider/input berubah karena model
atau data uji tidak dilatih ulang.
Paparan tujuh slide sekitar 8 menit, lalu demo 3 menit dan tanya jawab.

## Menjalankan ulang pendamping Python (opsional, bukan pengganti R)

```sh
python -m pip install -r requirements_python.txt
python 04_Verifikasi_Python.py
```

Skrip mencari data relatif terhadap folder tempat skrip berada dan menyimpan perhitungan
ke `hasil_python/`. Versi yang dipakai dicatat dalam `versi_dan_status.json`.
`model_dashboard_python.json` berisi serialisasi pohon/koefisien. Dashboard offline yang
ada merupakan snapshot hasil tersebut; menjalankan skrip Python tidak otomatis memperbarui
HTML/PPT/Word. Untuk hasil baru, perbarui keluaran komunikasi secara eksplisit.

## Keluaran R setelah berhasil dijalankan

Folder `hasil_R/` akan memuat `perbandingan_model.csv`, `prediksi_data_uji.csv`,
`inferensi_sederhana_HC3.csv`, `inferensi_berganda_HC3.csv`, `vif_kolom_desain.csv`,
`audit_height.csv`, `split_dan_fold.csv`, `prediksi_oof.csv`, `perhitungan_manual.csv`,
`korelasi.csv`, `bootstrap_RMSE_kondisional.csv`, `selisih_RMSE_RF_OLS.csv`,
`model_dan_hasil.rds`, grafik, `sessionInfo.txt`, dan `versi_paket.csv`.
Keluaran tersebut belum disertakan karena R belum dieksekusi.

## Interpretasi dan keterbatasan

Koefisien menunjukkan asosiasi, bukan kausalitas. R² sampel bukan ukuran ketepatan
individu; R² uji dapat negatif. HC3 membantu menghadapi heteroskedastisitas, bukan
menyelesaikan perancu, ketergantungan, atau bentuk model yang salah. VIF per kolom
desain tidak sama dengan GVIF gabungan faktor Sex. Sampel bukan sensus seluruh
populasi abalone. Data baru harus sejenis; validasi eksternal belum dilakukan.
Sebagian ukuran bobot destruktif, sehingga proyek bukan sistem umur sepenuhnya
nondestruktif. Unit efek mengikuti skala CSV; lihat kamus data sebelum konversi fisik.

## Sumber dan atribusi

- Berkas pengguna: CSV Abalone, skrip R asli, dan gambar instruksi proyek.
- Nash, W., Sellers, T., Talbot, S., Cawthorn, A., & Ford, W. (1994).
  Abalone [Dataset]. UCI. DOI: 10.24432/C55C7W. Lisensi CC BY 4.0 menurut UCI.
  https://archive.ics.uci.edu/dataset/1/abalone
- Shmueli, G. (2010). To Explain or to Predict? Statistical Science25(3),289–310.
  DOI:10.1214/10-STS330.
- Breiman, L. (2001). Random Forests. Machine Learning45,5–32.
  DOI:10.1023/A:1010933404324.
- Dokumentasi resmi R lm, rpart.control, randomForest; Posit Shiny/RMarkdown;
  scikit-learn RandomForestRegressor; statsmodels OLSResults.HC3_se.
  Rujukan rinci di proposal dan notebook. Diakses28September2026.

Pembagian kerja dalam dokumen adalah usulan, bukan klaim bahwa kedua anggota telah
mengerjakan bagian tersebut. Pelajari kode, verifikasi hasil R, dan sesuaikan identitas
serta aturan akademik mata kuliah sebelum menyerahkan tugas.
