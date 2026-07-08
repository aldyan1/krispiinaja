# Product Requirements Document (PRD)

# KrispiinAja POS

Versi: 1.0

Tagline: "Kasir Cepat, Bisnis Hebat"

---

# 1. Latar Belakang

KrispiinAja POS adalah aplikasi Point of Sale (POS) berbasis Flutter dan Supabase yang dirancang untuk membantu bisnis makanan dan minuman dengan banyak cabang dalam mengelola transaksi, kasir, produk, dan laporan penjualan secara terpusat.

Aplikasi ini mengusung konsep sederhana tanpa manajemen stok karena seluruh menu dibuat langsung saat dipesan. Produk hanya memiliki status "Tersedia" atau "Habis" yang dapat diubah oleh kasir maupun admin.

---

# 2. Tujuan Produk

## Tujuan Bisnis

* Memusatkan pengelolaan seluruh cabang dalam satu aplikasi.
* Memudahkan pemantauan penjualan setiap toko.
* Memudahkan pengelolaan kasir.
* Mempermudah proses transaksi.
* Menyediakan laporan penjualan yang akurat dan real-time.

## Tujuan Pengguna

### Pemilik Usaha (Admin)

* Mengelola banyak toko.
* Memantau transaksi seluruh toko.
* Melihat performa setiap kasir.
* Mengelola produk dan harga.

### Kasir

* Melakukan transaksi dengan cepat.
* Mengelola status produk tersedia atau habis.
* Membuka dan menutup shift kasir.
* Mengelola uang laci.

---

# 3. Role Pengguna

## Admin

Memiliki akses penuh terhadap seluruh sistem.

Hak akses:

* Dashboard
* Toko
* Produk
* Kasir
* Transaksi
* Laporan
* Pengaturan

## Kasir

Memiliki akses terbatas sesuai toko yang ditugaskan.

Hak akses:

* Dashboard
* Kasir
* Transaksi
* Uang Laci
* Status Produk

Kasir tidak dapat membuat toko maupun akun kasir baru.

---

# 4. Fitur Utama

## 4.1 Dashboard

### Admin

Filter toko:

* Semua Toko
* Toko tertentu

Informasi yang ditampilkan:

* Total Penjualan Hari Ini
* Total Transaksi
* Jumlah Kasir Aktif
* Produk Terlaris
* Pendapatan Hari Ini
* Ringkasan Uang Laci

### Kasir

Informasi yang ditampilkan:

* Nama Toko
* Shift Aktif
* Jumlah Transaksi Hari Ini
* Total Penjualan Hari Ini

---

## 4.2 Manajemen Toko

Menu khusus Admin.

### Tambah Toko

Field:

* Nama Toko
* Lokasi
* Nomor Telepon
* Status Aktif

### Edit Toko

Admin dapat mengubah data toko.

### Hapus Toko

Hanya dapat dilakukan jika tidak memiliki transaksi aktif.

### Tabel Toko

Kolom:

* Nama Toko
* Lokasi
* Jumlah Kasir
* Status

---

## 4.3 Manajemen Produk

Di bagian atas tersedia filter toko.

Setiap produk terhubung ke satu toko.

### Tambah Produk

Field:

* Foto Produk
* Nama Produk
* Harga Jual
* Deskripsi (opsional)

### Edit Produk

Admin dapat mengubah seluruh data produk.

### Hapus Produk

Admin dapat menghapus produk yang sudah tidak digunakan.

### Status Produk

Status:

* Tersedia
* Habis

Status dapat diubah oleh Admin dan Kasir.

### Tabel Produk

Kolom:

* Foto
* Nama Produk
* Harga
* Status

Catatan:

Sistem tidak menggunakan stok karena seluruh menu diproduksi langsung saat ada pesanan.

---

## 4.4 Manajemen Kasir

Menu khusus Admin.

### Tambah Kasir

Field:

* Nama Lengkap
* Email
* Password
* Pilih Toko

### Edit Kasir

Admin dapat:

* Mengubah nama
* Mengubah email
* Reset password
* Memindahkan toko

### Nonaktifkan Kasir

Admin dapat menonaktifkan akun kasir.

### Tabel Kasir

Kolom:

* Nama
* Email
* Toko
* Status

---

## 4.5 Uang Laci (Cash Drawer)

### Buka Shift

Saat mulai bekerja, kasir wajib memasukkan modal awal.

Contoh:

Modal Awal:
Rp500.000

Sistem mencatat:

* Kasir
* Toko
* Waktu buka
* Modal awal

### Shift Berjalan

Seluruh transaksi tunai otomatis masuk ke perhitungan uang laci.

### Tutup Shift

Kasir memasukkan jumlah uang fisik yang tersedia.

Sistem menghitung:

* Modal Awal
* Total Penjualan Tunai
* Total Pengeluaran
* Total Seharusnya
* Uang Fisik
* Selisih

Admin dapat melihat seluruh riwayat shift dan selisih kas.

---

## 4.6 Halaman Kasir

### Pencarian Produk

Kasir dapat mencari produk berdasarkan nama.

### Keranjang

Informasi:

* Nama Produk
* Qty
* Harga
* Subtotal

### Checkout

Metode pembayaran:

* Tunai
* Transfer
* QRIS

Sistem menghitung:

* Total Belanja
* Jumlah Bayar
* Kembalian

---

## 4.7 Transaksi

### Admin

Dapat melihat transaksi seluruh toko.

Filter:

* Toko
* Kasir
* Tanggal

### Kasir

Dapat melihat transaksi miliknya sendiri.

### Data Transaksi

* Nomor Transaksi
* Nama Kasir
* Nama Toko
* Metode Pembayaran
* Total
* Tanggal

---

## 4.8 Detail Transaksi

Menampilkan:

* Daftar Produk
* Harga Produk
* Qty
* Subtotal
* Metode Pembayaran
* Total Pembayaran
* Kembalian

---

## 4.9 Cetak Struk

Struk berisi:

* Logo Toko
* Nama Toko
* Alamat
* Nomor Transaksi
* Nama Kasir
* Tanggal
* Daftar Produk
* Total
* Pembayaran
* Kembalian

Format:

* PDF
* Share ke WhatsApp

---

## 4.10 Laporan Penjualan

### Filter

* Semua Toko
* Per Toko
* Harian
* Mingguan
* Bulanan
* Rentang Tanggal

### Data Laporan

* Total Omset
* Total Transaksi
* Produk Terlaris
* Metode Pembayaran Terbanyak
* Kasir Terbaik

---

# 5. Alur Penggunaan

## Admin

Login
→ Dashboard
→ Kelola Toko
→ Kelola Produk
→ Kelola Kasir
→ Monitoring Transaksi
→ Laporan

## Kasir

Login
→ Buka Shift
→ Pilih Produk
→ Checkout
→ Cetak Struk
→ Tutup Shift

---

# 6. Desain UI

Tema:

Merah Putih

Warna Utama:

* Merah (#E53935)
* Putih (#FFFFFF)

Warna Pendukung:

* Abu-abu Muda (#F5F5F5)
* Hitam (#212121)

Font:

* Poppins

Karakter UI:

* Modern
* Minimalis
* Cepat digunakan
* Mudah dipahami kasir

---

# 7. Non Functional Requirements

## Performa

* Login < 3 detik
* Simpan transaksi < 2 detik
* Pencarian produk realtime

## Keamanan

* Supabase Authentication
* Role Based Access Control
* Row Level Security (RLS)

## Ketersediaan

* Data tersimpan secara real-time
* Sinkronisasi antar perangkat

---

# 8. Roadmap

## Versi 1.0

* Multi Toko
* Multi Kasir
* Produk
* Transaksi
* Uang Laci
* Laporan

## Versi 1.1

* Printer Bluetooth
* Scan QRIS
* Export Excel

## Versi 2.0

* Loyalty Member
* Promo dan Voucher
* Dashboard Grafik Penjualan
* Progressive Web App (PWA)

---

# KPI Keberhasilan

* Waktu transaksi rata-rata < 30 detik.
* Akurasi laporan 100%.
* Selisih uang laci < 2%.
* Admin dapat memantau seluruh cabang secara real-time.
