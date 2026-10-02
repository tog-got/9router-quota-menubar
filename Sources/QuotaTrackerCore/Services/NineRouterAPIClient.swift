import Foundation

public enum APIError: Error, LocalizedError, Equatable {
    case unauthorized
    case offline
    case serverError(statusCode: Int, message: String?)
    case invalidResponse
    case decodingError(String)
    case custom(String)
    
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Perlu Login (Password salah atau sesi berakhir)"
        case .offline:
            return "9Router Offline (Tidak dapat terhubung ke localhost:20128)"
        case .serverError(let statusCode, let message):
            if let msg = message, !msg.isEmpty {
                return "Server error (\(statusCode)): \(msg)"
            }
            return "Server error (\(statusCode))"
        case .invalidResponse:
            return "Format respon server tidak valid"
        case .decodingError(let detail):
            return "Gagal membaca data server: \(detail)"
        case .custom(let msg):
            return msg
        }
    }
}

public final class NineRouterAPIClient: @unchecked Sendable {
    public let baseURL: URL
    public let session: URLSession
    
    public init(
        baseURL: URL = URL(string: "http://localhost:20128")!,
        session: URLSession? = nil
    ) {
        self.baseURL = baseURL
        if let customSession = session {
            self.session = customSession
        } else {
            let config = URLSessionConfiguration.default
            config.httpCookieStorage = HTTPCookieStorage.shared
            config.httpShouldSetCookies = true
            config.httpCookieAcceptPolicy = .always
            config.timeoutIntervalForRequest = 10
            config.timeoutIntervalForResource = 15
            self.session = URLSession(configuration: config)
        }
    }
    
    /// Melakukan login ke 9Router dengan password
    public func login(password: String) async throws -> Bool {
        let endpoint = baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body = AuthRequest(password: password)
        request.httpBody = try JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return true
            } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.unauthorized
            } else {
                let errResponse = try? JSONDecoder().decode(AuthResponse.self, from: data)
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: errResponse?.error ?? errResponse?.message)
            }
        } catch let err as APIError {
            throw err
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                throw APIError.offline
            }
            throw APIError.custom(error.localizedDescription)
        }
    }
    
    /// Mengambil daftar koneksi provider
    public func fetchProviders() async throws -> [ProviderConnection] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/providers/client"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "pageSize", value: "50"),
            URLQueryItem(name: "accountStatus", value: "all"),
            URLQueryItem(name: "sort", value: "priority")
        ]
        
        guard let url = components?.url else {
            throw APIError.custom("URL pembuatan query tidak valid")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }
            
            let decoder = JSONDecoder()
            let listResponse = try decoder.decode(ProviderListResponse.self, from: data)
            return listResponse.data
        } catch let err as APIError {
            throw err
        } catch let decodingErr as DecodingError {
            throw APIError.decodingError(decodingErr.localizedDescription)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                throw APIError.offline
            }
            throw APIError.custom(error.localizedDescription)
        }
    }
    
    /// Mengambil data penggunaan/kuota untuk satu koneksi provider
    public func fetchUsage(for connectionId: String) async throws -> UsageResponse {
        let endpoint = baseURL.appendingPathComponent("api/usage/\(connectionId)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.unauthorized
            }
            
            guard httpResponse.statusCode == 200 else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }
            
            let decoder = JSONDecoder()
            let usageResponse = try decoder.decode(UsageResponse.self, from: data)
            return usageResponse
        } catch let err as APIError {
            throw err
        } catch let decodingErr as DecodingError {
            throw APIError.decodingError(decodingErr.localizedDescription)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                throw APIError.offline
            }
            throw APIError.custom(error.localizedDescription)
        }
    }
    
    /// Mengubah status aktif/nonaktif provider connection di 9Router
    public func updateProviderStatus(connectionId: String, isEnabled: Bool) async throws -> Bool {
        let endpoint = baseURL.appendingPathComponent("api/providers/\(connectionId)")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let body: [String: Any] = ["isActive": isEnabled]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                return true
            } else if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw APIError.unauthorized
            } else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, message: nil)
            }
        } catch let err as APIError {
            throw err
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                throw APIError.offline
            }
            throw APIError.custom(error.localizedDescription)
        }
    }
    
    /// Menghapus cookie sesi aktif
    public func clearSession() {
        if let cookies = HTTPCookieStorage.shared.cookies(for: baseURL) {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}
