#!/usr/bin/env swift
import Cocoa

guard CommandLine.arguments.count >= 3 else {
    print("Usage: set-app-icon.swift <path/to/icon.icns or .png> <path/to/App.app>")
    exit(1)
}

let iconPath = CommandLine.arguments[1]
let appPath = CommandLine.arguments[2]

guard let iconImage = NSImage(contentsOfFile: iconPath) else {
    print("❌ Gagal membaca file icon di \(iconPath)")
    exit(1)
}

let success = NSWorkspace.shared.setIcon(iconImage, forFile: appPath, options: [])
if success {
    print("✅ Berhasil memasang icon Finder pada \(appPath)")
} else {
    print("⚠️ Gagal menyetel icon via NSWorkspace")
}
