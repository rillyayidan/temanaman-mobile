# TemanAman – Mobile Application (Flutter)

TemanAman adalah aplikasi mobile berbasis Flutter yang dirancang untuk memberikan dukungan emosional awal, edukasi, serta akses layanan bantuan terkait isu kekerasan seksual. Aplikasi ini ditujukan terutama untuk Generasi Z dengan pendekatan antarmuka modern, aman, dan berorientasi pada privasi pengguna.

Catatan penting: TemanAman bukan pengganti psikolog, tenaga medis, maupun layanan darurat. Aplikasi ini berfungsi sebagai media edukasi dan dukungan awal.

---

## Fitur Utama

Chatbot AI  
Menyediakan respons edukatif, informatif, dan dukungan emosional awal melalui percakapan berbasis teks. Fitur ini dilengkapi dengan Auto Disclaimer untuk menjelaskan batasan kemampuan AI serta menegaskan bahwa respons yang diberikan bukan merupakan diagnosis atau keputusan profesional. Percakapan tidak disimpan secara permanen demi menjaga privasi pengguna.

Safe Mode  
Fitur perlindungan tambahan yang dapat diaktifkan ketika pengguna merasa terancam atau privasinya berpotensi terganggu.

Tombol “Butuh Bantuan” dan Layanan Bantuan  
Menyediakan akses cepat ke kontak bantuan seperti telepon, WhatsApp, email, dan website. Dilengkapi filter region untuk menampilkan layanan yang relevan dan terpercaya.

Konten Edukasi  
Menyajikan informasi pencegahan kekerasan seksual, hak dan perlindungan korban, serta materi edukatif lainnya dalam kategori yang terstruktur dan mudah dipahami.

Kuis Interaktif  
Digunakan untuk mengukur pemahaman pengguna terhadap materi edukasi. Sistem menampilkan pembahasan jawaban secara bertahap untuk meningkatkan pemahaman dan kesadaran pengguna.

Privasi dan Transparansi  
Menyediakan halaman Kebijakan Privasi, AI Disclaimer, dan Ketentuan Penggunaan sebagai bentuk komitmen terhadap perlindungan data pengguna.

Onboarding  
Ditampilkan satu kali saat aplikasi pertama kali digunakan untuk memperkenalkan fitur utama, batasan AI, Safe Mode, dan prinsip privasi TemanAman.

---

## Teknologi yang Digunakan

Flutter sebagai framework pengembangan aplikasi mobile  
Bahasa pemrograman Dart  
REST API sebagai penghubung dengan backend TemanAman  
Shared Preferences untuk penyimpanan lokal (onboarding dan state sederhana)  
Material Design 3 untuk antarmuka pengguna  
AI API (OpenAI) yang diakses melalui backend

---

## Arsitektur Aplikasi

Frontend (Flutter Mobile)  
Menangani antarmuka pengguna, navigasi, serta interaksi dengan fitur aplikasi.

Backend API  
Mengelola proses Chat AI, konten edukasi, kuis, dan data layanan bantuan.

Admin Panel (Filament)  
Digunakan untuk pengelolaan konten aplikasi secara terpusat oleh administrator.

---

## Instalasi dan Menjalankan Aplikasi

1. Clone repository
```bash
git clone https://github.com/rillyayidan/teman_aman.git
cd teman_aman
````

2. Install dependency

```bash
flutter pub get
```

3. Jalankan aplikasi

```bash
flutter run
```

Pastikan Flutter SDK telah terpasang dan emulator atau perangkat fisik tersedia.

---

## Privasi dan Keamanan

Percakapan Chat AI tidak disimpan secara permanen.
Konteks percakapan hanya dikelola sementara selama sesi berlangsung (in-memory).
Ketika pengguna keluar dari ruang percakapan, konteks dan identitas ruang chat akan dihapus.
Data diproses secara minimal sesuai kebutuhan fitur dan prinsip keamanan standar.

---

## Tujuan Pengembangan

TemanAman dikembangkan untuk:

* Menyediakan media edukasi yang mudah diakses terkait kekerasan seksual
* Memberikan dukungan emosional awal secara aman dan bertanggung jawab
* Meningkatkan kesadaran dan pemahaman pengguna
* Membantu pengguna menemukan layanan bantuan yang relevan

---

## Konteks Akademik

Aplikasi ini dikembangkan sebagai bagian dari tugas akhir atau skripsi pada Program Studi Informatika, dengan fokus pada pengembangan aplikasi mobile berbasis AI yang memperhatikan aspek etika, privasi, dan keamanan pengguna.

---

## Pengembang

Nama: Muhammad Rilly Ayidan
Aplikasi: TemanAman
Platform: Flutter Mobile

---

## Lisensi

Proyek ini dikembangkan untuk keperluan akademik dan non-komersial. Penggunaan lebih lanjut menyesuaikan dengan kebijakan pengembang.

```

Tinggal bilang.
```
