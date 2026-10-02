import Foundation

/// Model untuk item koneksi provider dari 9Router
public struct ProviderConnection: Codable, Identifiable, Equatable, Sendable {
    public let id: FlexibleID
    public let provider: String
    public let name: String?
    public let displayName: String?
    public let email: String?
    public let accountStatus: String?
    public let status: String?
    public let priority: Int?
    public let isPaid: Bool?
    public let tier: String?
    public let authType: String?
    public let authMethod: String?
    public let type: String?
    public let accountType: String?
    public let createdAt: String?
    public let updatedAt: String?
    
    public init(
        id: FlexibleID,
        provider: String,
        name: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        accountStatus: String? = nil,
        status: String? = nil,
        priority: Int? = nil,
        isPaid: Bool? = nil,
        tier: String? = nil,
        authType: String? = nil,
        authMethod: String? = nil,
        type: String? = nil,
        accountType: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.provider = provider
        self.name = name
        self.displayName = displayName
        self.email = email
        self.accountStatus = accountStatus
        self.status = status
        self.priority = priority
        self.isPaid = isPaid
        self.tier = tier
        self.authType = authType
        self.authMethod = authMethod
        self.type = type
        self.accountType = accountType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var effectiveDisplayName: String {
        if let d = displayName, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return d
        }
        if let n = name, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return n
        }
        if let e = email, !e.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return e
        }
        return provider.capitalized
    }
    
    public var effectiveAccountName: String {
        if let n = name, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return n
        }
        if let d = displayName, !d.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return d
        }
        return "default"
    }
    
    public var effectiveAuthType: String {
        if let at = authType, !at.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return at
        }
        if let am = authMethod, !am.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return am
        }
        if let t = type, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return t
        }
        if let acc = accountType, !acc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return acc
        }
        return "OAuth"
    }
    
    public var effectiveStatus: String {
        return accountStatus ?? status ?? "unknown"
    }
    
    public var isConnectionActive: Bool {
        let st = effectiveStatus.lowercased()
        return st == "active" || st == "ok" || st == "healthy" || st == "enabled" || st == "ready"
    }
}

/// Envelope decoder untuk daftar provider
public struct ProviderListResponse: Codable, Sendable {
    public let data: [ProviderConnection]
    public let total: Int?
    
    public init(data: [ProviderConnection], total: Int? = nil) {
        self.data = data
        self.total = total
    }
    
    public init(from decoder: Decoder) throws {
        // Coba decode langsung sebagai Array
        if let array = try? [ProviderConnection](from: decoder) {
            self.data = array
            self.total = array.count
            return
        }
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let items = try? container.decode([ProviderConnection].self, forKey: .connections) {
            self.data = items
            self.total = try? container.decode(Int.self, forKey: .total)
        } else if let items = try? container.decode([ProviderConnection].self, forKey: .data) {
            self.data = items
            self.total = try? container.decode(Int.self, forKey: .total)
        } else if let items = try? container.decode([ProviderConnection].self, forKey: .items) {
            self.data = items
            self.total = try? container.decode(Int.self, forKey: .total)
        } else if let items = try? container.decode([ProviderConnection].self, forKey: .providers) {
            self.data = items
            self.total = try? container.decode(Int.self, forKey: .total)
        } else {
            self.data = []
            self.total = 0
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case connections
        case data
        case items
        case providers
        case total
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(total, forKey: .total)
    }
}
