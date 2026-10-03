# 9Router Tracker - Panduan & Catatan Teknis Proyek

Dokumen ini adalah panduan teknis dan operasional untuk proyek **9Router Tracker** (aplikasi native macOS Menu Bar pengukur kuota AI).

---

## 1. Ringkasan Proyek & Arsitektur
- **Nama Aplikasi**: `9Router Tracker.app`
- **Tipe**: macOS Menu Bar Extra (`LSUIElement = true`, tanpa ikon di Dock).
- **Bahasa & Kerangka Kerja**: Swift 5.9+, AppKit murni, SwiftUI, Swift Package Manager (SPM).
- **Target Arsitektur**: Apple Silicon (ARM64) macOS 13.0+.
- **Sumber Data Kuota**:
  1. **9Router API Local** (`http://localhost:20128`): Membaca provider upstream (Antigravity, Claude Code, OpenAI Codex, DeepSeek, Grok, Kimi, dll.).
  2. **OpenCode Local Database** (`~/.local/share/opencode/opencode.db`): Membaca langsung metrik token model Free Tier (seperti `big-pickle`, `fledge-alpha-free`, `space-bunny-free`, dll.) secara aman via C-SQLite3 (Read-Only).

---

## 2. Struktur Direktori Proyek
```
9router-quota-menubar/
├── Package.swift                    # Konfigurasi Swift Package Manager
├── AGENTS.md                        # Panduan agen dan catatan teknis proyek (berkas ini)
├── README.md                        # Dokumentasi dwibahasa (ID & EN)
├── Resources/
│   ├── AppIcon.icns                # Ikon resolusi tinggi 3D Apple-style
│   └── Info.plist                  # Metadata aplikasi macOS & deklarasi ikon
├── Sources/
│   ├── QuotaTrackerCore/           # Modul logika inti & pemrosesan data
│   │   ├── Models/
│   │   │   ├── AuthRequest.swift
│   │   │   ├── NormalizedQuota.swift  # Normalisasi kuota & Model Family Grouping
│   │   │   ├── ProviderConnection.swift
│   │   │   └── UsageResponse.swift    # Parsing JSON fleksibel (Array/Dict/Single)
│   │   ├── Services/
│   │   │   ├── AutoStartManager.swift # Integrasi SMAppService login item
│   │   │   ├── KeychainHelper.swift   # Keamanan password via macOS Keychain API
│   │   │   ├── NineRouterAPIClient.swift # Komunikasi HTTP/REST ke 9Router
│   │   │   ├── OpenCodeUsageReader.swift # Pembaca SQLite lokal token OpenCode
│   │   │   └── QuotaManager.swift     # State manager & orchestrator refresh kuota
│   │   └── Utils/
│   │       ├── FlexibleDecoders.swift
│   │       └── Formatters.swift
│   ├── QuotaMenuBar/               # Antarmuka aplikasi AppKit & SwiftUI
│   │   ├── AppDelegate.swift
│   │   ├── main.swift
│   │   └── UI/
│   │       ├── PasswordPromptWindow.swift
│   │       ├── QuotaDashboardView.swift # Tampilan popover, kartu provider, progress bar
│   │       └── StatusMenuController.swift # Kontroler status bar macOS & popup menu
│   └── QuotaTrackerCoreTestRunner/ # Test runner mandiri (26 unit tests)
│       ├── TestHarness.swift
│       └── main.swift
├── scripts/
│   ├── build-app.sh                # Skrip otomatis: test -> build ARM64 -> bundle .app -> codesign -> zip
│   └── generate-icon.swift         # Generator vektor aset AppIcon.icns multi-resolusi
└── build/
    ├── 9Router Tracker.app         # Paket aplikasi siap pakai
    └── 9RouterTracker-macOS-arm64.zip # Berkas arsip rilis portabel
```

---

## 3. Fitur Utama yang Telah Diimplementasikan
1. **Pengelompokan Model Terpadu (*Model Family Grouping*)**:
   - Kuota 5 Jam (Sesi) dan Mingguan (Weekly) ditampilkan berdampingan dalam satu kotak model AI (contoh: Gemini, Claude & GPT, Spark, Codex, OpenCode).
   - Dilengkapi badge tipe durasi (`⏱️ 5 Jam`, `📅 Mingguan`), progress bar sisa, persentase angka, dan waktu hitung mundur (*countdown*) reset.
2. **Kendali Jalur Langsung (*Direct Provider Toggle*)**:
   - Mengubah status koneksi provider secara instan via API `PUT /api/providers/:id` dengan payload `{"isActive": true/false}`.
3. **Pelacak OpenCode Free Tier Lokal**:
   - Membaca database `~/.local/share/opencode/opencode.db` secara otomatis untuk menghitung token model gratis 24 jam terakhir.
4. **Desain Antarmuka Simetris & Scrollbar Mengambang**:
   - Margin kartu seimbang 12pt di semua sisi.
   - Scrollbar otomatis mengambang (*floating*) hanya saat digulir (`.scrollIndicators(.automatic)`).
5. **Keamanan Hardware macOS**:
   - Menggunakan macOS Keychain API (`Security.framework`) untuk menyimpan kredensial. Password tidak pernah ditulis ke log atau teks biasa.

---

## 4. Alur Kerja Build & Verifikasi

### Menjalankan Seluruh Pengujian Unit
```bash
swift run QuotaTrackerCoreTestRunner
```
*Hasil saat ini: 26 dari 26 pengujian LULUS (100% PASS).*

### Melakukan Build Release & Pemasangan ke Aplikasi
```bash
# 1. Jalankan skrip build otomatis
./scripts/build-app.sh

# 2. Pasang ke folder Aplikasi dan jalankan
rm -rf "/Applications/9Router Tracker.app"
cp -R "build/9Router Tracker.app" /Applications/
open "/Applications/9Router Tracker.app"
```

---

## 5. Batasan & Aturan Khusus Mesin
- Hardware: MacBook Air M1, RAM 8GB. Aplikasi ini dirancang ultra-ringan dengan konsumsi RAM idle < 25MB.
- Jangan menambahkan dependensi eksternal yang berat (CocoaPods/Carthage). Pertahankan penggunaan Swift Package Manager murni dan framework native macOS (AppKit, SwiftUI, Security, SQLite3).
