# 9Router Quota Tracker (macOS Native Menu Bar App)

[![Platform: macOS](https://img.shields.io/badge/platform-macOS%2013%2B%20(ARM64)-blue.svg)](https://apple.com)
[![Swift: 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests: 25/25 Passed](https://img.shields.io/badge/Tests-25%2F25%20Passing-brightgreen.svg)]()

> **English & Bahasa Indonesia** documentation provided below.

---

## 🇮🇩 Bahasa Indonesia

Aplikasi macOS Menu Bar (Status Bar) native Swift ARM64 yang ultra-ringan dan cepat untuk memantau status serta sisa kuota provider AI pada **9Router** (`http://localhost:20128`).

### 🌟 Fitur Utama
1. **Native & Ringan (Apple Silicon ARM64)**:
   - Dibuat dengan Swift murni dan AppKit (`NSStatusItem` & SwiftUI Popover).
   - Berjalan sebagai Menu Bar Extra tanpa ikon di Dock (`LSUIElement = true`).
   - Sangat hemat memori RAM dan konsumsi CPU (dioptimalkan untuk MacBook Air/Pro M1/M2/M3/M4).
2. **Pengelompokan Kuota Terpadu (*Model Family Grouping*)**:
   - Menyatukan kuota **5 Jam (Sesi)** dan **Mingguan (Weekly)** ke dalam satu kotak kelompok model (misal: Gemini, Claude & GPT, Spark, Codex, OpenCode Free Tier).
   - Dilengkapi badge durasi yang jelas, visual progress bar, persentase sisa kuota, dan waktu hitung mundur reset (*countdown*).
3. **Dukungan Berbagai Provider AI & Free Tier**:
   - Mendukung pelacakan kuota Antigravity, Claude Code, OpenAI Codex, DeepSeek, Grok, Kimi, serta **OpenCode Free Tier**.
4. **Kendali Jalur Langsung (*Direct Provider & Model Toggle*)**:
   - Terintegrasi penuh dengan API 9Router (`PUT /api/providers/:id` dengan payload `isActive`).
   - Dapat memutus atau menyambungkan jalur provider secara instan langsung dari menu bar tanpa harus membuka browser.
5. **Keamanan Maksimal**:
   - Menggunakan **macOS Keychain API** (`Security.framework`) untuk menyimpan password 9Router secara terenkripsi di level sistem operasi.
   - Password dan token tidak pernah dicetak ke berkas teks atau log biasa.
6. **Auto-Refresh & Aksi Cepat**:
   - Refresh otomatis di latar belakang setiap 10 menit.
   - Tombol manual **Refresh Kuota** (`Cmd+R`), **Web Dashboard** (`Cmd+D`), dan **Atur Password** (`Cmd+P`).
   - Opsi **Auto-start saat Login** terintegrasi dengan `SMAppService`.

### 🚀 Cara Build & Menjalankan
```bash
# 1. Jalankan skrip build otomatis (menjalankan test, compile release ARM64, codesign, & bundling .app)
./scripts/build-app.sh

# 2. Buka aplikasi
open "build/9Router Tracker.app"

# Atau pasang permanen ke Applications:
cp -R "build/9Router Tracker.app" /Applications/
```

---

## 🇬🇧 English

An ultra-lightweight, native macOS Menu Bar application built in pure Swift (ARM64) to monitor real-time AI provider quotas and router status on **9Router** (`http://localhost:20128`).

### 🌟 Key Features
1. **Native & Lightweight (Apple Silicon ARM64)**:
   - Built with pure Swift, AppKit (`NSStatusItem`), and SwiftUI Popover views.
   - Runs as a status bar extra without cluttering the macOS Dock (`LSUIElement = true`).
   - Minimal memory footprint and low CPU usage, perfectly tailored for Apple Silicon (M1/M2/M3/M4).
2. **Unified Model Family Grouping**:
   - Organizes both **5-Hour (Session)** and **Weekly** quotas within unified model cards (e.g., Gemini, Claude & GPT, Spark, Codex, OpenCode Free Tier).
   - Features clean duration tags, visual progress indicators, percentage metrics, and live reset countdowns.
3. **Broad Provider & Free Tier Support**:
   - Native support for Antigravity, Claude Code, OpenAI Codex, DeepSeek, Grok, Kimi, and **OpenCode Free Tier**.
4. **Direct Provider & Model Toggle**:
   - Seamlessly integrated with 9Router's upstream API (`PUT /api/providers/:id` with `isActive` payload).
   - Enable or disable provider routes instantly from the menu bar without navigating to the web dashboard.
5. **Hardware-Level Security**:
   - Uses the native **macOS Keychain API** (`Security.framework`) to store credentials safely.
   - Never exposes tokens, keys, or passwords in plaintext files or standard logs.
6. **Auto-Refresh & Quick Shortcuts**:
   - Automatic background polling every 10 minutes.
   - Quick actions for **Refresh** (`Cmd+R`), **Open Dashboard** (`Cmd+D`), and **Set Password** (`Cmd+P`).
   - Native macOS login item integration via `SMAppService`.

### 🚀 Build & Installation
```bash
# 1. Execute automated build script (runs unit tests, compiles release ARM64 binary, codesigns, & bundles .app)
./scripts/build-app.sh

# 2. Launch application
open "build/9Router Tracker.app"

# Or install permanently into /Applications:
cp -R "build/9Router Tracker.app" /Applications/
```

---

## 📂 Project Structure
```
9router-quota-menubar/
├── Package.swift                    # Swift Package Manager configuration (macOS 13+)
├── Resources/
│   ├── AppIcon.icns                # High-resolution Apple Silicon icon
│   └── Info.plist                  # Bundle metadata (LSUIElement = true)
├── Sources/
│   ├── QuotaTrackerCore/           # Core logic, normalizer, models & API client
│   │   ├── Models/
│   │   ├── Services/
│   │   └── Utils/
│   ├── QuotaMenuBar/               # AppKit status bar controller & SwiftUI views
│   │   ├── AppDelegate.swift
│   │   ├── main.swift
│   │   └── UI/
│   └── QuotaTrackerCoreTestRunner/ # Standalone unit test harness (25 test suites)
│       ├── TestHarness.swift
│       └── main.swift
├── scripts/
│   ├── build-app.sh                # Automated test, release build, package & codesign script
│   └── generate-icon.swift         # Vector icon generator for macOS AppIcon.icns
└── build/
    ├── 9Router Tracker.app         # Ready-to-use macOS application bundle
    └── 9RouterTracker-macOS-arm64.zip # Portable distribution archive
```
