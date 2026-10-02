import Foundation
import QuotaTrackerCore

public final class TestRunner: @unchecked Sendable {
    private var passed = 0
    private var failed = 0
    
    public init() {}
    
    public func runTest(name: String, test: () async throws -> Void) async {
        print("  ▶️ Menjalankan: \(name)...", terminator: " ")
        fflush(stdout)
        do {
            try await test()
            passed += 1
            print("✅ LULUS")
        } catch {
            failed += 1
            print("❌ GAGAL: \(error)")
        }
    }
    
    public func summarize() -> Bool {
        print("\n==================================================")
        print("📊 Ringkasan Pengujian:")
        print("   ✅ Lulus: \(passed)")
        print("   ❌ Gagal: \(failed)")
        print("   📁 Total: \(passed + failed)")
        print("==================================================")
        return failed == 0
    }
}

public func assertCondition(_ condition: Bool, _ msg: String = "", file: String = #file, line: Int = #line) throws {
    if !condition {
        throw NSError(domain: "AssertionFailure", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gagal pada \(file):\(line) -> \(msg)"])
    }
}

public func assertEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String = "", file: String = #file, line: Int = #line) throws {
    if a != b {
        throw NSError(domain: "AssertionFailure", code: 1, userInfo: [NSLocalizedDescriptionKey: "Gagal pada \(file):\(line) -> [\(a)] != [\(b)] \(msg)"])
    }
}
