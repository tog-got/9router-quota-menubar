import Cocoa
import QuotaTrackerCore

@MainActor
public final class PasswordPromptWindow {
    public static func showPrompt(
        initialMessage: String = "Masukkan password untuk login ke 9Router (localhost:20128).",
        completion: @escaping (String?, Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Login 9Router"
        alert.informativeText = initialMessage
        alert.alertStyle = .informational
        
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 70))
        
        let secureField = NSSecureTextField(frame: NSRect(x: 0, y: 35, width: 300, height: 24))
        secureField.placeholderString = "Password 9Router"
        containerView.addSubview(secureField)
        
        let checkbox = NSButton(checkboxWithTitle: "Ingat Password di Keychain", target: nil, action: nil)
        checkbox.frame = NSRect(x: 0, y: 5, width: 300, height: 20)
        checkbox.state = .on
        containerView.addSubview(checkbox)
        
        alert.accessoryView = containerView
        alert.addButton(withTitle: "Hubungkan")
        alert.addButton(withTitle: "Batal")
        
        // Aktifkan fokus ke window alert
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let password = secureField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            let remember = (checkbox.state == .on)
            if !password.isEmpty {
                completion(password, remember)
            } else {
                completion(nil, false)
            }
        } else {
            completion(nil, false)
        }
    }
}
