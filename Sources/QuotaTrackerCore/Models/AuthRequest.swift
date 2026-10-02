import Foundation

public struct AuthRequest: Codable, Sendable {
    public let password: String
    
    public init(password: String) {
        self.password = password
    }
}

public struct AuthResponse: Codable, Sendable {
    public let success: Bool?
    public let message: String?
    public let error: String?
    public let token: String?
    
    public init(success: Bool? = nil, message: String? = nil, error: String? = nil, token: String? = nil) {
        self.success = success
        self.message = message
        self.error = error
        self.token = token
    }
}
