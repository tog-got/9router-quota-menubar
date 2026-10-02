import Cocoa
import SwiftUI
import Combine
import QuotaTrackerCore

@MainActor
public final class StatusMenuController: NSObject {
    private var statusItem: NSStatusItem!
    private var window: NSWindow!
    private var hostingController: NSHostingController<QuotaDashboardView>!
    private let quotaManager: QuotaManager
    private var cancellables = Set<AnyCancellable>()
    
    public init(quotaManager: QuotaManager) {
        self.quotaManager = quotaManager
        super.init()
        setupWindow()
        setupStatusItem()
        setupObservers()
    }
    
    private func setupWindow() {
        let contentView = QuotaDashboardView(
            quotaManager: quotaManager,
            onOpenPasswordPrompt: { [weak self] in
                self?.openPasswordPrompt()
            },
            onOpenDashboard: { [weak self] in
                self?.openDashboard()
            },
            onQuitApp: {
                NSApplication.shared.terminate(nil)
            }
        )
        
        hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 12
        hostingController.view.layer?.masksToBounds = false

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 700),
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.appearance = NSAppearance(named: .vibrantDark)
        
        // Batasan ukuran resize
        window.minSize = NSSize(width: 360, height: 420)
        window.maxSize = NSSize(width: 650, height: 900)
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.acceptsMouseMovedEvents = true

        // Auto-close when user clicks outside the window
        setupOutsideClickMonitor()
    }

    private func setupOutsideClickMonitor() {
        if let existingMonitor = outsideClickMonitor {
            NSEvent.removeMonitor(existingMonitor)
            outsideClickMonitor = nil
        }

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            guard let self = self else { return }
            guard self.window.isVisible else { return }

            let clickLocation = NSEvent.mouseLocation
            if !self.window.frame.contains(clickLocation) {
                // Abaikan jika klik di area status item button sendiri
                if let button = self.statusItem.button,
                   let buttonWindow = button.window {
                    let buttonFrame = buttonWindow.convertToScreen(button.bounds)
                    if buttonFrame.contains(clickLocation) {
                        return
                    }
                }
                self.window.orderOut(nil)
            }
        }
    }

    private var outsideClickMonitor: Any?
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = createMenuBarIcon()
            button.imagePosition = .imageLeft
            button.toolTip = "9Router Quota Tracker"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func createMenuBarIcon() -> NSImage {
        // SF Symbol jika tersedia di macOS
        if let sfImage = NSImage(systemSymbolName: "gauge.with.dots.needle.bottom.50percent", accessibilityDescription: "9Router") {
            sfImage.isTemplate = true
            return sfImage
        }
        
        // Fallback ikon teks "9R" template
        let size = NSSize(width: 22, height: 18)
        let img = NSImage(size: size, flipped: false) { rect in
            let text = "9R"
            let font = NSFont.monospacedSystemFont(ofSize: 11, weight: .bold)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black
            ]
            let attrStr = NSAttributedString(string: text, attributes: attrs)
            let textSize = attrStr.size()
            let drawPoint = NSPoint(
                x: (rect.width - textSize.width) / 2.0,
                y: (rect.height - textSize.height) / 2.0
            )
            attrStr.draw(at: drawPoint)
            return true
        }
        img.isTemplate = true
        return img
    }
    
    private func setupObservers() {
        quotaManager.$status
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWindowContent()
            }
            .store(in: &cancellables)
        
        quotaManager.$quotas
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWindowContent()
            }
            .store(in: &cancellables)
        
        quotaManager.$lastUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateWindowContent()
            }
            .store(in: &cancellables)
    }
    
    private func updateWindowContent() {
        let contentView = QuotaDashboardView(
            quotaManager: quotaManager,
            onOpenPasswordPrompt: { [weak self] in
                self?.openPasswordPrompt()
            },
            onOpenDashboard: { [weak self] in
                self?.openDashboard()
            },
            onQuitApp: {
                NSApplication.shared.terminate(nil)
            }
        )
        hostingController.rootView = contentView
    }
    
    // MARK: - Action Handlers
    
    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else {
            toggleWindow(sender)
            return
        }
        
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showContextMenu(sender)
        } else {
            toggleWindow(sender)
        }
    }
    
    public func toggleWindow(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if window.isVisible {
            window.orderOut(sender)
        } else {
            showWindowRelativeToButton(button)
            NSApp.activate(ignoringOtherApps: true)
            window.makeKeyAndOrderFront(sender)
        }
    }
    
    private func showWindowRelativeToButton(_ button: NSStatusBarButton) {
        guard let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else {
            return
        }
        
        let buttonFrameInScreen = buttonWindow.convertToScreen(button.bounds)
        var windowFrame = window.frame
        
        // Posisikan window rata tengah di bawah icon menu bar
        windowFrame.origin.x = buttonFrameInScreen.midX - (windowFrame.width / 2)
        windowFrame.origin.y = buttonFrameInScreen.minY - windowFrame.height - 4
        
        // Pastikan tidak meluap ke luar area kerja layar
        let screenFrame = screen.visibleFrame
        if windowFrame.maxX > screenFrame.maxX - 8 {
            windowFrame.origin.x = screenFrame.maxX - windowFrame.width - 8
        }
        if windowFrame.minX < screenFrame.minX + 8 {
            windowFrame.origin.x = screenFrame.minX + 8
        }
        if windowFrame.minY < screenFrame.minY + 8 {
            windowFrame.origin.y = screenFrame.minY + 8
        }
        
        window.setFrame(windowFrame, display: true)
    }
    
    private func showContextMenu(_ sender: NSStatusBarButton) {
        if window.isKeyWindow {
            window.orderOut(nil)
        }
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        
        let headerItem = NSMenuItem(title: quotaManager.status.title, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        let font = NSFont.boldSystemFont(ofSize: 12)
        headerItem.attributedTitle = NSAttributedString(string: quotaManager.status.title, attributes: [.font: font])
        menu.addItem(headerItem)
        
        if let lastUpdate = quotaManager.lastUpdated {
            let updateStr = "Terakhir: \(Formatters.formatDateTime(lastUpdate))"
            let updateItem = NSMenuItem(title: updateStr, action: nil, keyEquivalent: "")
            updateItem.isEnabled = false
            menu.addItem(updateItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let dashItem = NSMenuItem(title: "Buka Dashboard 9Router", action: #selector(openDashboardClicked), keyEquivalent: "d")
        dashItem.target = self
        menu.addItem(dashItem)
        
        let refreshItem = NSMenuItem(title: "Refresh Kuota", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        let passItem = NSMenuItem(title: "Atur Password...", action: #selector(setPasswordClicked), keyEquivalent: "p")
        passItem.target = self
        menu.addItem(passItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let autoStartItem = NSMenuItem(title: "Auto-start saat Login", action: #selector(toggleAutoStartClicked(_:)), keyEquivalent: "")
        autoStartItem.target = self
        autoStartItem.state = AutoStartManager.shared.isAutoStartEnabled ? .on : .off
        menu.addItem(autoStartItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Keluar", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
    }
    
    private func openPasswordPrompt() {
        if window.isKeyWindow {
            window.orderOut(nil)
        }
        PasswordPromptWindow.showPrompt { [weak self] password, remember in
            guard let self = self, let password = password else { return }
            Task {
                let result = await self.quotaManager.loginAndRefresh(password: password, rememberInKeychain: remember)
                if case .failure(let error) = result {
                    let alert = NSAlert()
                    alert.messageText = "Gagal Login"
                    alert.informativeText = error.localizedDescription
                    alert.alertStyle = .warning
                    alert.runModal()
                }
            }
        }
    }
    
    private func openDashboard() {
        if let url = URL(string: "http://localhost:20128/dashboard/quota") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc private func refreshClicked() {
        Task {
            await quotaManager.refreshQuotas()
        }
    }
    
    @objc private func openDashboardClicked() {
        openDashboard()
    }
    
    @objc private func setPasswordClicked() {
        openPasswordPrompt()
    }
    
    @objc private func toggleAutoStartClicked(_ sender: NSMenuItem) {
        let currentStatus = AutoStartManager.shared.isAutoStartEnabled
        let newStatus = !currentStatus
        let result = AutoStartManager.shared.setAutoStart(enabled: newStatus)
        switch result {
        case .success(let enabled):
            sender.state = enabled ? .on : .off
        case .failure(let error):
            let alert = NSAlert()
            alert.messageText = "Pengaturan Auto-Start Gagal"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }
    
    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSWindowDelegate (optional, for handling window close)
extension StatusMenuController: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        // Clean up outside-click monitor to avoid leaks
        if let monitor = outsideClickMonitor {
            NSEvent.removeMonitor(monitor)
            outsideClickMonitor = nil
        }
    }
}