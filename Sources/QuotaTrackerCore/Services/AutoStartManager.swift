import Foundation
import ServiceManagement

public final class AutoStartManager: Sendable {
    public static let shared = AutoStartManager()
    
    public init() {}
    
    /// Cek status auto-start saat ini
    public var isAutoStartEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    /// Aktifkan atau nonaktifkan auto-start
    public func setAutoStart(enabled: Bool) -> Result<Bool, Error> {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                return .success(isAutoStartEnabled)
            } catch {
                return .failure(error)
            }
        }
        return .success(false)
    }
}
