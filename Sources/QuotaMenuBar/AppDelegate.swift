import Cocoa
import QuotaTrackerCore

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var quotaManager: QuotaManager!
    private var statusMenuController: StatusMenuController!
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Pastikan tidak ada ikon di Dock
        NSApp.setActivationPolicy(.accessory)
        
        self.quotaManager = QuotaManager()
        self.statusMenuController = StatusMenuController(quotaManager: quotaManager)
        
        // Mulai auto-refresh 10 menit
        quotaManager.startAutoRefresh()
        
        // Jalankan refresh awal
        Task {
            await quotaManager.refreshQuotas()
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        quotaManager?.stopAutoRefresh()
    }
}
