import Foundation

public enum RouterStatus: Equatable, Sendable {
    case idle
    case loading
    case connected(providerCount: Int)
    case loginRequired
    case offline
    case error(String)
    
    public var title: String {
        switch self {
        case .idle:
            return "9Router: Menunggu"
        case .loading:
            return "9Router: Memuat data..."
        case .connected(let count):
            return "🟢 9Router Terhubung (\(count) Provider)"
        case .loginRequired:
            return "🟡 Perlu Login"
        case .offline:
            return "🔴 9Router Offline"
        case .error(let msg):
            return "⚠️ Error: \(msg)"
        }
    }
}

@MainActor
public final class QuotaManager: ObservableObject {
    @Published public private(set) var status: RouterStatus = .idle
    @Published public private(set) var quotas: [NormalizedProviderQuota] = []
    @Published public private(set) var lastUpdated: Date? = nil
    @Published public private(set) var isRefreshing: Bool = false
    
    public let apiClient: NineRouterAPIClient
    public let keychainHelper: KeychainHelper
    public let openCodeReader: OpenCodeUsageReader
    
    private var refreshTimer: Timer?
    public var refreshIntervalSeconds: TimeInterval = 600 // 10 menit
    
    public init(
        apiClient: NineRouterAPIClient = NineRouterAPIClient(),
        keychainHelper: KeychainHelper = KeychainHelper.shared,
        openCodeReader: OpenCodeUsageReader = OpenCodeUsageReader()
    ) {
        self.apiClient = apiClient
        self.keychainHelper = keychainHelper
        self.openCodeReader = openCodeReader
    }
    
    /// Memulai timer otomatis setiap 10 menit
    public func startAutoRefresh() {
        stopAutoRefresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshQuotas()
            }
        }
    }
    
    /// Menghentikan timer otomatis
    public func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Memuat data secara menyeluruh (login jika perlu, lalu fetch provider & usage)
    public func refreshQuotas() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        status = .loading
        
        defer {
            isRefreshing = false
        }
        
        do {
            // Coba fetch provider langsung (jika session cookie masih valid)
            let providers: [ProviderConnection]
            do {
                providers = try await apiClient.fetchProviders()
            } catch APIError.unauthorized {
                // Coba auto-login dengan password dari keychain jika ada
                if let savedPassword = keychainHelper.readPassword() {
                    let loginOk = try await apiClient.login(password: savedPassword)
                    if loginOk {
                        providers = try await apiClient.fetchProviders()
                    } else {
                        status = .loginRequired
                        return
                    }
                } else {
                    // Jika Keychain kosong, coba auto-login pertama kali dengan default password 123456
                    do {
                        let defaultPassword = "123456"
                        let loginOk = try await apiClient.login(password: defaultPassword)
                        if loginOk {
                            keychainHelper.savePassword(defaultPassword)
                            providers = try await apiClient.fetchProviders()
                        } else {
                            status = .loginRequired
                            return
                        }
                    } catch {
                        status = .loginRequired
                        return
                    }
                }
            }
            
            // Ambil usage kuota untuk setiap koneksi provider secara paralel
            var normalizedList: [NormalizedProviderQuota] = []
            
            await withTaskGroup(of: NormalizedProviderQuota.self) { group in
                for provider in providers {
                    let client = self.apiClient
                    group.addTask {
                        do {
                            let usage = try await client.fetchUsage(for: provider.id.rawValue)
                            return NormalizedProviderQuota.normalize(connection: provider, usage: usage)
                        } catch {
                            return NormalizedProviderQuota.normalize(connection: provider, usage: nil, error: error)
                        }
                    }
                }
                
                for await item in group {
                    normalizedList.append(item)
                }
            }
            
            // Tambahkan data penggunaan OpenCode Free Tier jika database lokal tersedia
            if let openCodeQuota = openCodeReader.generateNormalizedQuota() {
                // Hindari duplikasi jika sudah ada dari 9Router
                if !normalizedList.contains(where: { $0.provider.lowercased() == "opencode" }) {
                    normalizedList.append(openCodeQuota)
                }
            }
            
            // Urutkan berdasarkan provider name kemudian display name
            normalizedList.sort {
                if $0.provider.lowercased() == $1.provider.lowercased() {
                    return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
                }
                return $0.provider.localizedCaseInsensitiveCompare($1.provider) == .orderedAscending
            }
            
            self.quotas = normalizedList
            self.lastUpdated = Date()
            self.status = .connected(providerCount: normalizedList.count)
            
        } catch APIError.unauthorized {
            self.status = .loginRequired
        } catch APIError.offline {
            self.status = .offline
        } catch {
            self.status = .error(error.localizedDescription)
        }
    }
    
    /// Login eksplisit dengan password baru
    public func loginAndRefresh(password: String, rememberInKeychain: Bool = true) async -> Result<Void, Error> {
        isRefreshing = true
        status = .loading
        
        defer {
            isRefreshing = false
        }
        
        do {
            let success = try await apiClient.login(password: password)
            if success {
                if rememberInKeychain {
                    keychainHelper.savePassword(password)
                }
                await refreshQuotas()
                return .success(())
            } else {
                status = .loginRequired
                return .failure(APIError.unauthorized)
            }
        } catch {
            if let apiErr = error as? APIError, apiErr == .unauthorized {
                status = .loginRequired
            } else if let apiErr = error as? APIError, apiErr == .offline {
                status = .offline
            } else {
                status = .error(error.localizedDescription)
            }
            return .failure(error)
        }
    }
    
    /// Mengubah status aktif/nonaktif untuk seluruh koneksi provider
    public func toggleProvider(connectionId: String, isEnabled: Bool) async -> Result<Void, Error> {
        // Update state lokal terlebih dahulu (optimistic update)
        if let pIdx = quotas.firstIndex(where: { $0.connectionId == connectionId }) {
            var updatedProvider = quotas[pIdx]
            let updatedMetrics = updatedProvider.metrics.map { m in
                var mod = m
                mod.isEnabled = isEnabled
                return mod
            }
            updatedProvider = NormalizedProviderQuota(
                connectionId: updatedProvider.connectionId,
                provider: updatedProvider.provider,
                displayName: updatedProvider.displayName,
                accountStatus: isEnabled ? "active" : "disabled",
                isOnline: isEnabled,
                metrics: updatedMetrics,
                hasQuota: updatedProvider.hasQuota,
                errorMessage: updatedProvider.errorMessage,
                authType: updatedProvider.authType,
                accountName: updatedProvider.accountName
            )
            quotas[pIdx] = updatedProvider
        }
        
        // Kirim request ke API 9Router (PUT /api/providers/:id with {"isActive": isEnabled})
        do {
            _ = try await apiClient.updateProviderStatus(connectionId: connectionId, isEnabled: isEnabled)
            return .success(())
        } catch {
            // Revert state lokal jika terjadi error
            await refreshQuotas()
            return .failure(error)
        }
    }
    
    /// Mengubah status aktif/nonaktif untuk model / provider
    public func toggleModel(connectionId: String, metricName: String, isEnabled: Bool) async -> Result<Void, Error> {
        return await toggleProvider(connectionId: connectionId, isEnabled: isEnabled)
    }
    
    /// Logout: Hapus cookie sesi dan password di keychain jika diminta
    public func logout(clearKeychain: Bool = true) {
        apiClient.clearSession()
        if clearKeychain {
            keychainHelper.deletePassword()
        }
        self.quotas = []
        self.status = .loginRequired
        self.lastUpdated = nil
    }
}
