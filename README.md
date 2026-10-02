# 9Router Quota Tracker (macOS Menu Bar Native App)

Aplikasi macOS Menu Bar (Status Bar) native Swift ARM64 yang ringan dan cepat untuk memantau status serta sisa kuota provider AI pada **9Router** (`http://localhost:20128`).

---

## 🌟 Fitur Utama

1. **Native & Ringan (Apple Silicon ARM64)**:
   - Dibuat dengan Swift murni dan AppKit (`NSStatusItem`).
   - Berjalan sebagai Menu Bar Extra tanpa ikon di Dock (`LSUIElement = true`).
   - Hemat memori dan CPU (sangat cocok untuk MacBook M1/M2/M3).
2. **Integrasi Penuh 9Router**:
   - Endpoint login `POST /api/auth/login` dengan manajemen sesi cookie (`URLSession` / `HTTPCookieStorage`).
   - Endpoint daftar koneksi `GET /api/providers/client`.
   - Endpoint metrik kuota `GET /api/usage/{connectionId}`.
3. **Normalisasi & Tampilan Kuota**:
   - Menampilkan status 9Router (`🟢 Terhubung`, `🟡 Perlu Login`, `🔴 Offline`).
   - Menampilkan daftar provider aktif beserta nama akun / display name.
   - Menampilkan penggunaan kuota terpakai vs total, persentase sisa, dan estimasi waktu reset.
   - **Anti-Halusinasi**: Tidak membuat data kuota palsu jika tidak disediakan oleh API.
4. **Keamanan Maksimal**:
   - Menggunakan macOS **Keychain API** (`Security.framework`) untuk menyimpan password 9Router secara terenkripsi di level sistem operasi.
   - Password dan token tidak pernah dicetak ke berkas teks atau log biasa.
5. **Auto-Refresh & Aksi Cepat**:
   - Refresh otomatis di latar belakang setiap 10 menit.
   - Tombol manual **Refresh Kuota** (`Cmd+R`).
   - Tombol **Buka Dashboard** (`Cmd+D`) untuk membuka web dashboard 9Router.
   - Tombol **Atur Password...** (`Cmd+P`) dan **Logout**.
   - Opsi **Auto-start saat Login** terintegrasi dengan `SMAppService`.

---

## 📂 Struktur Proyek

```
9router-quota-menubar/
├── Package.swift                    # Konfigurasi Swift Package Manager (macOS 13+)
├── Resources/
│   └── Info.plist                  # Metadata bundle & LSUIElement = true (No Dock)
├── Sources/
│   ├── QuotaTrackerCore/           # Logika Core, Model, & API Client
│   │   ├── Models/
│   │   │   ├── AuthRequest.swift
│   │   │   ├── ProviderConnection.swift
│   │   │   ├── UsageResponse.swift
│   │   │   └── NormalizedQuota.swift
│   │   ├── Services/
│   │   │   ├── NineRouterAPIClient.swift
│   │   │   ├── QuotaManager.swift
│   │   │   ├── KeychainHelper.swift
│   │   │   └── AutoStartManager.swift
│   │   └── Utils/
│   │       ├── FlexibleDecoders.swift
│   │       └── Formatters.swift
│   ├── QuotaMenuBar/               # Aplikasi AppKit / Menu Bar UI
│   │   ├── AppDelegate.swift
│   │   ├── main.swift
│   │   └── UI/
│   │       ├── StatusMenuController.swift
│   │       └── PasswordPromptWindow.swift
│   └── QuotaTrackerCoreTestRunner/ # Test Suite Lengkap
│       ├── TestHarness.swift
│       └── main.swift
├── scripts/
│   └── build-app.sh                # Skrip otomatis test, compile release, bundle .app & codesign
└── build/
    └── QuotaMenuBar.app            # Bundle aplikasi siap pakai
```

---

## 🚀 Cara Build & Menjalankan

### 1. Build & Bundle `.app`
Jalankan skrip build otomatis:
```bash
./scripts/build-app.sh
```
Skrip ini akan:
1. Menjalankan seluruh pengujian unit (14 skenario test).
2. Meng-compile binary release ARM64 (`swift build -c release --arch arm64`).
3. Mengemas menjadi `build/QuotaMenuBar.app` lengkap dengan `Info.plist`.
4. Menandatangani (*codesign*) app bundle secara lokal.

### 2. Menjalankan Aplikasi
Buka aplikasi yang sudah di-bundle:
```bash
open build/QuotaMenuBar.app
```
Atau salin ke folder `/Applications` jika ingin dipasang permanen:
```bash
cp -R build/QuotaMenuBar.app /Applications/
```

### 3. Menjalankan Test Suite Mandiri
```bash
swift run QuotaTrackerCoreTestRunner
```
