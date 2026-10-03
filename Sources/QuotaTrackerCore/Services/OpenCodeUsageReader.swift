import Foundation
import SQLite3

/// Model data statistik penggunaan token OpenCode per model
public struct OpenCodeModelUsage: Sendable, Equatable {
    public let modelId: String
    public let inputTokens: Double
    public let outputTokens: Double
    public let totalTokens: Double
    public let lastUsed: Date
    public let messageCount: Int
    
    public init(
        modelId: String,
        inputTokens: Double,
        outputTokens: Double,
        totalTokens: Double,
        lastUsed: Date,
        messageCount: Int
    ) {
        self.modelId = modelId
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.lastUsed = lastUsed
        self.messageCount = messageCount
    }
}

/// Reader mandiri untuk membaca pemakaian token dari database lokal OpenCode (~/.local/share/opencode/opencode.db)
public final class OpenCodeUsageReader: Sendable {
    public let dbPath: String
    
    public init(dbPath: String? = nil) {
        if let custom = dbPath {
            self.dbPath = custom
        } else {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            self.dbPath = "\(home)/.local/share/opencode/opencode.db"
        }
    }
    
    /// Memeriksa apakah database OpenCode terpasang di sistem
    public var isAvailable: Bool {
        return FileManager.default.fileExists(atPath: dbPath)
    }
    
    /// Membaca pemakaian token 24 jam terakhir untuk semua model OpenCode
    public func fetchRecentUsage(withinHours hours: Int = 24) -> [OpenCodeModelUsage] {
        guard isAvailable else { return [] }
        
        var db: OpaquePointer?
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return []
        }
        defer {
            sqlite3_close(db)
        }
        
        // Hitung batas waktu (default 24 jam yang lalu dalam milidetik)
        let cutoffTimestamp = (Date().timeIntervalSince1970 - Double(hours * 3600)) * 1000.0
        
        let query = """
        SELECT 
          json_extract(data, '$.model.id') as model_id,
          COALESCE(sum(json_extract(data, '$.tokens.input')), 0) as input_tokens,
          COALESCE(sum(json_extract(data, '$.tokens.output')), 0) as output_tokens,
          COALESCE(sum(json_extract(data, '$.tokens.input') + json_extract(data, '$.tokens.output')), 0) as total_tokens,
          COALESCE(max(time_created), 0) as last_used,
          count(*) as msg_count
        FROM session_message 
        WHERE type = 'assistant' 
          AND json_extract(data, '$.model.providerID') = 'opencode'
          AND time_created >= ?
        GROUP BY model_id
        HAVING total_tokens > 0
        ORDER BY last_used DESC;
        """
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            return []
        }
        defer {
            sqlite3_finalize(statement)
        }
        
        sqlite3_bind_double(statement, 1, cutoffTimestamp)
        
        var results: [OpenCodeModelUsage] = []
        
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let modelCString = sqlite3_column_text(statement, 0) else { continue }
            let modelId = String(cString: modelCString)
            let inputTokens = sqlite3_column_double(statement, 1)
            let outputTokens = sqlite3_column_double(statement, 2)
            let totalTokens = sqlite3_column_double(statement, 3)
            let lastUsedMs = sqlite3_column_double(statement, 4)
            let msgCount = Int(sqlite3_column_int(statement, 5))
            
            let lastUsedDate = Date(timeIntervalSince1970: lastUsedMs / 1000.0)
            
            results.append(OpenCodeModelUsage(
                modelId: modelId,
                inputTokens: inputTokens,
                outputTokens: outputTokens,
                totalTokens: totalTokens,
                lastUsed: lastUsedDate,
                messageCount: msgCount
            ))
        }
        
        return results
    }
    
    /// Mengonversi hasil pembacaan OpenCode menjadi objek NormalizedProviderQuota
    public func generateNormalizedQuota() -> NormalizedProviderQuota? {
        guard isAvailable else { return nil }
        let usages = fetchRecentUsage(withinHours: 24)
        
        // Estimasi batas harian per model (Free tier default 1.000.000 tokens/day atau actual)
        let metrics: [NormalizedQuotaMetric] = usages.map { u in
            let estimatedDailyLimit: Double = 1_000_000.0 // 1M tokens/day baseline
            let remainingTokens = max(0, estimatedDailyLimit - u.totalTokens)
            let remainingPct = max(0.0, min(100.0, (remainingTokens / estimatedDailyLimit) * 100.0))
            
            // Waktu reset harian (tengah malam lokal berikutnya)
            let calendar = Calendar.current
            let resetDate = calendar.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)
            
            return NormalizedQuotaMetric(
                name: u.modelId,
                used: u.totalTokens,
                total: estimatedDailyLimit,
                remaining: remainingTokens,
                remainingPercentage: remainingPct,
                unit: "tokens",
                resetAt: resetDate,
                isEnabled: true
            )
        }
        
        return NormalizedProviderQuota(
            connectionId: "conn-opencode-local",
            provider: "opencode",
            displayName: "OpenCode (Free Tier)",
            accountStatus: "active",
            isOnline: true,
            metrics: metrics,
            hasQuota: !metrics.isEmpty,
            errorMessage: nil,
            authType: "Free Tier",
            accountName: "Local CLI"
        )
    }
}
