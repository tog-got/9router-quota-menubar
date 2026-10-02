import Foundation

/// Item kuota individu yang didapatkan dari API
public struct QuotaDetailItem: Codable, Equatable, Sendable {
    public let name: String?
    public let type: String?
    public let used: FlexibleDouble?
    public let total: FlexibleDouble?
    public let limit: FlexibleDouble?
    public let remaining: FlexibleDouble?
    public let remainingPercentage: FlexibleDouble?
    public let percentage: FlexibleDouble?
    public let unit: String?
    public let resetAt: FlexibleDate?
    public let resetTime: FlexibleDate?
    public let expiresAt: FlexibleDate?
    public let period: String?
    
    public init(
        name: String? = nil,
        type: String? = nil,
        used: FlexibleDouble? = nil,
        total: FlexibleDouble? = nil,
        limit: FlexibleDouble? = nil,
        remaining: FlexibleDouble? = nil,
        remainingPercentage: FlexibleDouble? = nil,
        percentage: FlexibleDouble? = nil,
        unit: String? = nil,
        resetAt: FlexibleDate? = nil,
        resetTime: FlexibleDate? = nil,
        expiresAt: FlexibleDate? = nil,
        period: String? = nil
    ) {
        self.name = name
        self.type = type
        self.used = used
        self.total = total
        self.limit = limit
        self.remaining = remaining
        self.remainingPercentage = remainingPercentage
        self.percentage = percentage
        self.unit = unit
        self.resetAt = resetAt
        self.resetTime = resetTime
        self.expiresAt = expiresAt
        self.period = period
    }
}

/// Response fleksibel dari endpoint `/api/usage/{connectionId}`
public struct UsageResponse: Codable, Equatable, Sendable {
    public let connectionId: FlexibleID?
    public let quotas: [QuotaDetailItem]
    public let error: String?
    public let message: String?
    public let status: String?
    
    public init(
        connectionId: FlexibleID? = nil,
        quotas: [QuotaDetailItem] = [],
        error: String? = nil,
        message: String? = nil,
        status: String? = nil
    ) {
        self.connectionId = connectionId
        self.quotas = quotas
        self.error = error
        self.message = message
        self.status = status
    }
    
    private static func convertDictToQuotaList(_ dict: [String: QuotaDetailItem]) -> [QuotaDetailItem] {
        return dict.sorted(by: { $0.key < $1.key }).map { key, item in
            if let name = item.name, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return item
            }
            return QuotaDetailItem(
                name: key,
                type: item.type,
                used: item.used,
                total: item.total,
                limit: item.limit,
                remaining: item.remaining,
                remainingPercentage: item.remainingPercentage,
                percentage: item.percentage,
                unit: item.unit,
                resetAt: item.resetAt,
                resetTime: item.resetTime,
                expiresAt: item.expiresAt,
                period: item.period
            )
        }
    }
    
    public init(from decoder: Decoder) throws {
        // Coba decode jika root adalah array [QuotaDetailItem]
        if let array = try? [QuotaDetailItem](from: decoder) {
            self.connectionId = nil
            self.quotas = array
            self.error = nil
            self.message = nil
            self.status = nil
            return
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.connectionId = try? container.decode(FlexibleID.self, forKey: .connectionId)
        self.error = try? container.decode(String.self, forKey: .error)
        self.message = try? container.decode(String.self, forKey: .message)
        self.status = try? container.decode(String.self, forKey: .status)
        
        // Cek jika field 'quotas' ada sebagai array atau dictionary
        if let items = try? container.decode([QuotaDetailItem].self, forKey: .quotas) {
            self.quotas = items
        } else if let dict = try? container.decode([String: QuotaDetailItem].self, forKey: .quotas) {
            self.quotas = Self.convertDictToQuotaList(dict)
        } else if let single = try? container.decode(QuotaDetailItem.self, forKey: .quota) {
            self.quotas = [single]
        } else if let dataObj = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data) {
            if let items = try? dataObj.decode([QuotaDetailItem].self, forKey: .quotas) {
                self.quotas = items
            } else if let dict = try? dataObj.decode([String: QuotaDetailItem].self, forKey: .quotas) {
                self.quotas = Self.convertDictToQuotaList(dict)
            } else if let single = try? dataObj.decode(QuotaDetailItem.self, forKey: .quota) {
                self.quotas = [single]
            } else if let directSingle = try? QuotaDetailItem(from: dataObj.superDecoder()) {
                // Jika data itu sendiri berisi properti quota
                if directSingle.used != nil || directSingle.total != nil || directSingle.remaining != nil {
                    self.quotas = [directSingle]
                } else {
                    self.quotas = []
                }
            } else {
                self.quotas = []
            }
        } else if let dataDict = try? container.decode([String: QuotaDetailItem].self, forKey: .data) {
            self.quotas = Self.convertDictToQuotaList(dataDict)
        } else if let direct = try? QuotaDetailItem(from: decoder) {
            // Cek apakah ada field used / total / limit langsung di root
            if direct.used != nil || direct.total != nil || direct.remaining != nil {
                self.quotas = [direct]
            } else {
                self.quotas = []
            }
        } else {
            self.quotas = []
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case connectionId
        case quotas
        case quota
        case data
        case error
        case message
        case status
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(connectionId, forKey: .connectionId)
        try container.encode(quotas, forKey: .quotas)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(status, forKey: .status)
    }
}
