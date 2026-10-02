import Foundation

/// Representasi metrik kuota yang sudah dinormalisasi dari respon API
public struct NormalizedQuotaMetric: Equatable, Sendable {
    public let name: String
    public let used: Double?
    public let total: Double?
    public let remaining: Double?
    public let remainingPercentage: Double?
    public let unit: String?
    public let resetAt: Date?
    public var isEnabled: Bool
    
    public init(
        name: String,
        used: Double? = nil,
        total: Double? = nil,
        remaining: Double? = nil,
        remainingPercentage: Double? = nil,
        unit: String? = nil,
        resetAt: Date? = nil,
        isEnabled: Bool = true
    ) {
        self.name = name
        self.used = used
        self.total = total
        self.remaining = remaining
        self.remainingPercentage = remainingPercentage
        self.unit = unit
        self.resetAt = resetAt
        self.isEnabled = isEnabled
    }
    
    public var formattedUsage: String {
        if let used = used, let total = total {
            let usedStr = Formatters.formatNumber(used, unit: unit)
            let totalStr = Formatters.formatNumber(total, unit: unit)
            return "\(usedStr) / \(totalStr)"
        } else if let used = used {
            return "Terpakai: \(Formatters.formatNumber(used, unit: unit))"
        } else if let remaining = remaining {
            return "Sisa: \(Formatters.formatNumber(remaining, unit: unit))"
        } else {
            return "Data penggunaan tidak tersedia"
        }
    }
    
    public var formattedRemainingSummary: String? {
        if let rem = remaining, let pct = remainingPercentage {
            return "Sisa: \(Formatters.formatNumber(rem, unit: unit)) (\(Formatters.formatPercentage(pct)))"
        } else if let rem = remaining {
            return "Sisa: \(Formatters.formatNumber(rem, unit: unit))"
        } else if let pct = remainingPercentage {
            return "Sisa: \(Formatters.formatPercentage(pct))"
        } else if let used = used, let total = total, total > 0 {
            let calcRem = max(0, total - used)
            let calcPct = (calcRem / total) * 100.0
            return "Sisa: \(Formatters.formatNumber(calcRem, unit: unit)) (\(Formatters.formatPercentage(calcPct)))"
        }
        return nil
    }
    
    public var formattedReset: String? {
        guard let resetAt = resetAt else { return nil }
        let rel = Formatters.formatRelativeTime(from: resetAt)
        let abs = Formatters.formatDateTime(resetAt)
        return "Reset: \(abs) (\(rel))"
    }
    
    /// Nama model / kuota (mengembalikan kode internal asli)
    public func friendlyName(provider: String = "") -> String {
        return name
    }
    
    /// Ikon representatif untuk model
    public var icon: String {
        let n = name.lowercased()
        if n.contains("claude") { return "🤖" }
        if n.contains("gemini") { return "✨" }
        if n.contains("codex") || n.contains("spark") { return "⚡" }
        if n.contains("review") { return "🔍" }
        if n.contains("gpt") || n.contains("openai") { return "🧠" }
        return "📊"
    }
    
    /// Nilai persentase sisa yang efektif (0.0 - 100.0)
    public var effectiveRemainingPercentage: Double {
        if let pct = remainingPercentage {
            return max(0.0, min(100.0, pct))
        } else if let rem = remaining, let total = total, total > 0 {
            return max(0.0, min(100.0, (rem / total) * 100.0))
        } else if let used = used, let total = total, total > 0 {
            return max(0.0, min(100.0, ((total - used) / total) * 100.0))
        }
        return 100.0
    }
    
    /// Format visual progress bar dengan status sisa
    public var formattedProgressBar: String {
        let pct = effectiveRemainingPercentage
        let bar = Formatters.progressBar(percentage: pct)
        let pctStr = String(format: "%.0f%%", pct)
        
        if let used = used, let total = total {
            let usedStr = Formatters.formatNumber(used, unit: unit)
            let totalStr = Formatters.formatNumber(total, unit: unit)
            return "\(bar) \(pctStr) sisa (\(usedStr) / \(totalStr))"
        } else if let rem = remaining {
            let remStr = Formatters.formatNumber(rem, unit: unit)
            return "\(bar) \(pctStr) sisa (\(remStr))"
        } else {
            return "\(bar) \(pctStr) sisa"
        }
    }
    
    /// Format waktu reset relatif ramah pengguna
    public var formattedResetRelative: String? {
        guard let resetAt = resetAt else { return nil }
        let rel = Formatters.formatRelativeTime(from: resetAt)
        return "Reset \(rel)"
    }
    
    /// Format waktu countdown ringkas seperti "in 1d 15h" atau "in 3h 12m"
    public var formattedCountdown: String? {
        guard let resetAt = resetAt else { return nil }
        return Formatters.formatCountdown(from: resetAt)
    }
    
    /// Menentukan apakah metrik ini adalah kuota mingguan (weekly)
    public var isWeekly: Bool {
        let n = name.lowercased()
        if n.contains("weekly") || n.contains("week") || n.contains("mingguan") {
            return true
        }
        return false
    }
}

/// Representasi lengkap kuota per provider connection
public struct NormalizedProviderQuota: Identifiable, Equatable, Sendable {
    public var id: String { connectionId }
    public let connectionId: String
    public let provider: String
    public let displayName: String
    public let accountStatus: String
    public let isOnline: Bool
    public let metrics: [NormalizedQuotaMetric]
    public let hasQuota: Bool
    public let errorMessage: String?
    public let authType: String?
    public let accountName: String?
    
    /// Metrik kuota sesi / 5 jam
    public var sessionMetrics: [NormalizedQuotaMetric] {
        return metrics.filter { !$0.isWeekly }
    }
    
    /// Metrik kuota mingguan
    public var weeklyMetrics: [NormalizedQuotaMetric] {
        return metrics.filter { $0.isWeekly }
    }
    
    public init(
        connectionId: String,
        provider: String,
        displayName: String,
        accountStatus: String,
        isOnline: Bool,
        metrics: [NormalizedQuotaMetric] = [],
        hasQuota: Bool = false,
        errorMessage: String? = nil,
        authType: String? = nil,
        accountName: String? = nil
    ) {
        self.connectionId = connectionId
        self.provider = provider
        self.displayName = displayName
        self.accountStatus = accountStatus
        self.isOnline = isOnline
        self.metrics = metrics
        self.hasQuota = hasQuota
        self.errorMessage = errorMessage
        self.authType = authType
        self.accountName = accountName
    }
    
    /// Waktu reset terdekat di antara semua metrik yang masih akan datang
    public var nearestReset: Date? {
        let dates = metrics.compactMap { $0.resetAt }.filter { $0 > Date() }
        return dates.min()
    }
    
    /// Format countdown waktu reset terdekat seperti "in 1d 15h"
    public var formattedNearestResetCountdown: String? {
        guard let nearest = nearestReset else { return nil }
        return Formatters.formatCountdown(from: nearest)
    }
    
    /// Normalisasi dari koneksi provider dan respon usage API
    public static func normalize(
        connection: ProviderConnection,
        usage: UsageResponse? = nil,
        error: Error? = nil
    ) -> NormalizedProviderQuota {
        let connId = connection.id.rawValue
        let providerName = connection.provider
        let displayName = connection.effectiveDisplayName
        let status = connection.effectiveStatus
        let isOnline = connection.isConnectionActive
        let auth = connection.effectiveAuthType
        let accName = connection.effectiveAccountName
        
        if let err = error {
            return NormalizedProviderQuota(
                connectionId: connId,
                provider: providerName,
                displayName: displayName,
                accountStatus: status,
                isOnline: isOnline,
                metrics: [],
                hasQuota: false,
                errorMessage: err.localizedDescription,
                authType: auth,
                accountName: accName
            )
        }
        
        guard let usage = usage else {
            return NormalizedProviderQuota(
                connectionId: connId,
                provider: providerName,
                displayName: displayName,
                accountStatus: status,
                isOnline: isOnline,
                metrics: [],
                hasQuota: false,
                errorMessage: nil,
                authType: auth,
                accountName: accName
            )
        }
        
        if let apiError = usage.error, !apiError.isEmpty {
            return NormalizedProviderQuota(
                connectionId: connId,
                provider: providerName,
                displayName: displayName,
                accountStatus: status,
                isOnline: isOnline,
                metrics: [],
                hasQuota: false,
                errorMessage: apiError,
                authType: auth,
                accountName: accName
            )
        }
        
        var normalizedMetrics: [NormalizedQuotaMetric] = []
        
        var interimMetrics: [(name: String, metric: NormalizedQuotaMetric)] = []
        
        for item in usage.quotas {
            let metricName = item.name ?? item.type ?? "Kuota"
            let usedVal = item.used?.value
            let totalVal = item.total?.value ?? item.limit?.value
            let unitVal = item.unit
            let resetDate = item.resetAt?.date ?? item.resetTime?.date ?? item.expiresAt?.date
            
            var remVal = item.remaining?.value
            var remPct = item.remainingPercentage?.value ?? item.percentage?.value
            
            // Hitung kalkulasi sisa jika total & used ada tapi remaining belum dihitung oleh server
            if remVal == nil, let u = usedVal, let t = totalVal {
                remVal = max(0, t - u)
            }
            if remPct == nil, let rem = remVal, let t = totalVal, t > 0 {
                remPct = (rem / t) * 100.0
            }
            
            // Masukkan metrik hanya jika memiliki data kuota nyata (tidak mengarang nilai)
            if usedVal != nil || totalVal != nil || remVal != nil || remPct != nil || resetDate != nil {
                let metric = NormalizedQuotaMetric(
                    name: metricName,
                    used: usedVal,
                    total: totalVal,
                    remaining: remVal,
                    remainingPercentage: remPct,
                    unit: unitVal,
                    resetAt: resetDate,
                    isEnabled: isOnline
                )
                interimMetrics.append((metricName, metric))
            }
        }
        
        // Gabungkan metrik gemini dan claude/gpt untuk provider Antigravity agar tampil seperti web
        if providerName.lowercased() == "antigravity" {
            func familyKey(for name: String) -> String {
                let lower = name.lowercased()
                let isWeekly = lower.contains("weekly") || lower.contains("week") || lower.contains("mingguan")
                
                if lower.contains("gemini") {
                    return isWeekly ? "gemini_weekly" : "gemini_session"
                }
                if lower.contains("claude") || lower.contains("gpt") {
                    return isWeekly ? "claude_gpt_weekly" : "claude_gpt_session"
                }
                if isWeekly {
                    return "weekly"
                }
                return lower
            }
            
            var grouped: [String: [(name: String, metric: NormalizedQuotaMetric)]] = [:]
            for item in interimMetrics {
                let key = familyKey(for: item.name)
                grouped[key, default: []].append(item)
            }
            
            normalizedMetrics = grouped.compactMap { key, items in
                var aggregateUsed: Double = 0
                var aggregateTotal: Double = 0
                var aggregateRemaining: Double = 0
                var weightedPctSum: Double = 0
                var totalWeight: Double = 0
                var latestReset: Date? = nil
                var units: Set<String> = []
                
                for item in items {
                    let m = item.metric
                    if let u = m.used { aggregateUsed += u }
                    if let t = m.total { 
                        aggregateTotal += t
                        totalWeight += t
                    }
                    if let r = m.remaining { aggregateRemaining += r }
                    if let p = m.remainingPercentage, let t = m.total {
                        weightedPctSum += p * Double(t)
                    } else if let p = m.remainingPercentage {
                        weightedPctSum += p
                        totalWeight += 1
                    }
                    if let d = m.resetAt, latestReset == nil || d > latestReset! { latestReset = d }
                    if let u = m.unit { units.insert(u) }
                }
                
                let avgPct: Double? = totalWeight > 0 ? weightedPctSum / totalWeight : nil
                
                return NormalizedQuotaMetric(
                    name: key,
                    used: aggregateTotal > 0 ? aggregateUsed : nil,
                    total: aggregateTotal > 0 ? aggregateTotal : nil,
                    remaining: aggregateRemaining > 0 ? aggregateRemaining : nil,
                    remainingPercentage: avgPct,
                    unit: units.first,
                    resetAt: latestReset,
                    isEnabled: isOnline
                )
            }
        } else {
            normalizedMetrics = interimMetrics.map { $0.metric }
        }
        
        let hasValidQuota = !normalizedMetrics.isEmpty
        
        return NormalizedProviderQuota(
            connectionId: connId,
            provider: providerName,
            displayName: displayName,
            accountStatus: status,
            isOnline: isOnline,
            metrics: normalizedMetrics,
            hasQuota: hasValidQuota,
            errorMessage: usage.message,
            authType: auth,
            accountName: accName
        )
    }
}
