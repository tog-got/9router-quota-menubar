import Foundation

public enum Formatters {
    public static func formatNumber(_ value: Double, unit: String? = nil) -> String {
        let u = unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isCurrency = u == "$" || u.uppercased() == "USD" || u.uppercased() == "IDR"
        
        if isCurrency {
            if u.uppercased() == "IDR" {
                let formatter = NumberFormatter()
                formatter.locale = Locale(identifier: "id_ID")
                formatter.numberStyle = .currency
                formatter.currencyCode = "IDR"
                formatter.maximumFractionDigits = 0
                return formatter.string(from: NSNumber(value: value)) ?? "Rp\(Int(value))"
            } else {
                return String(format: "$%.2f", value)
            }
        }
        
        // Non-currency: format ringkas jika besar
        if value >= 1_000_000 {
            let formatted = String(format: "%.1fM", value / 1_000_000)
            return u.isEmpty ? formatted : "\(formatted) \(u)"
        } else if value >= 10_000 {
            let formatted = String(format: "%.1fk", value / 1_000)
            return u.isEmpty ? formatted : "\(formatted) \(u)"
        } else if floor(value) == value {
            let formatted = String(Int(value))
            return u.isEmpty ? formatted : "\(formatted) \(u)"
        } else {
            let formatted = String(format: "%.2f", value)
            return u.isEmpty ? formatted : "\(formatted) \(u)"
        }
    }
    
    public static func formatPercentage(_ percentage: Double) -> String {
        return String(format: "%.1f%%", max(0, min(100, percentage)))
    }
    
    /// Visual progress bar teks elegan dengan 10 blok karakter
    public static func progressBar(percentage: Double, length: Int = 10) -> String {
        let clamped = max(0.0, min(100.0, percentage))
        let filledCount = Int(round((clamped / 100.0) * Double(length)))
        let emptyCount = max(0, length - filledCount)
        let filled = String(repeating: "█", count: filledCount)
        let empty = String(repeating: "░", count: emptyCount)
        return "[\(filled)\(empty)]"
    }
    
    /// Format nama model / kuota - mengembalikan kode internal asli (rawName)
    public static func friendlyQuotaName(rawName: String, provider: String = "") -> String {
        return rawName
    }
    
    public static func formatRelativeTime(from date: Date, now: Date = Date()) -> String {
        let diff = date.timeIntervalSince(now)
        
        if diff < 0 {
            let pastDiff = abs(diff)
            if pastDiff < 60 {
                return "baru saja"
            } else if pastDiff < 3600 {
                let mins = Int(pastDiff / 60)
                return "\(mins) menit lalu"
            } else if pastDiff < 86400 {
                let hours = Int(pastDiff / 3600)
                return "\(hours) jam lalu"
            } else {
                let days = Int(pastDiff / 86400)
                return "\(days) hari lalu"
            }
        }
        
        if diff < 60 {
            return "dalam beberapa detik"
        } else if diff < 3600 {
            let mins = max(1, Int(diff / 60))
            return "dalam \(mins) menit"
        } else if diff < 86400 {
            let hours = Int(diff / 3600)
            let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
            if mins > 0 {
                return "dalam \(hours) jam \(mins) menit"
            }
            return "dalam \(hours) jam"
        } else {
            let days = Int(diff / 86400)
            let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
            if hours > 0 {
                return "dalam \(days) hari \(hours) jam"
            }
            return "dalam \(days) hari"
        }
    }
    
    public static func formatDateTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "id_ID")
        df.dateFormat = "dd MMM yyyy HH:mm"
        return df.string(from: date)
    }
    
    /// Format waktu hitung mundur ringkas seperti "in 1d 15h" atau "in 3h 12m"
    public static func formatCountdown(from date: Date, now: Date = Date()) -> String {
        let diff = date.timeIntervalSince(now)
        if diff <= 0 {
            return "Expired"
        }
        
        let days = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        let mins = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if days > 0 {
            if hours > 0 {
                return "in \(days)d \(hours)h"
            }
            return "in \(days)d"
        } else if hours > 0 {
            if mins > 0 {
                return "in \(hours)h \(mins)m"
            }
            return "in \(hours)h"
        } else if mins > 0 {
            return "in \(mins)m"
        } else {
            return "in <1m"
        }
    }
}
