import Foundation
import QuotaTrackerCore

// Mock URLProtocol untuk pengujian unit
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockURLProtocol", code: 0, userInfo: nil))
            return
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

@main
struct TestMain {
    static func main() async {
        print("🧪 Memulai Test Suite untuk QuotaTrackerCore...\n")
        let runner = TestRunner()
        
        // 1. Model Tests
        await runner.runTest(name: "FlexibleDouble Decoding") {
            let jsonDouble = "12.34".data(using: .utf8)!
            let decDouble = try JSONDecoder().decode(FlexibleDouble.self, from: jsonDouble)
            try assertCondition(abs(decDouble.value - 12.34) < 0.001, "Nilai double tidak sesuai")
            
            let jsonInt = "50".data(using: .utf8)!
            let decInt = try JSONDecoder().decode(FlexibleDouble.self, from: jsonInt)
            try assertEqual(decInt.value, 50.0, "Nilai int tidak sesuai")
            
            let jsonStr = "\"99.95\"".data(using: .utf8)!
            let decStr = try JSONDecoder().decode(FlexibleDouble.self, from: jsonStr)
            try assertCondition(abs(decStr.value - 99.95) < 0.001, "Nilai string numeric tidak sesuai")
        }
        
        await runner.runTest(name: "FlexibleID Decoding") {
            let jsonStr = "\"conn-12345\"".data(using: .utf8)!
            let decStr = try JSONDecoder().decode(FlexibleID.self, from: jsonStr)
            try assertEqual(decStr.rawValue, "conn-12345")
            
            let jsonInt = "42".data(using: .utf8)!
            let decInt = try JSONDecoder().decode(FlexibleID.self, from: jsonInt)
            try assertEqual(decInt.rawValue, "42")
        }
        
        await runner.runTest(name: "FlexibleDate Decoding") {
            let isoJson = "\"2026-10-01T12:00:00Z\"".data(using: .utf8)!
            let decIso = try JSONDecoder().decode(FlexibleDate.self, from: isoJson)
            try assertCondition(abs(decIso.date.timeIntervalSince1970 - 1790856000) < 1.0)
            
            let secJson = "1790856000".data(using: .utf8)!
            let decSec = try JSONDecoder().decode(FlexibleDate.self, from: secJson)
            try assertCondition(abs(decSec.date.timeIntervalSince1970 - 1790856000) < 1.0)
            
            let msJson = "1790856000000".data(using: .utf8)!
            let decMs = try JSONDecoder().decode(FlexibleDate.self, from: msJson)
            try assertCondition(abs(decMs.date.timeIntervalSince1970 - 1790856000) < 1.0)
        }
        
        await runner.runTest(name: "ProviderListResponse Decoding") {
            let json = """
            {
                "data": [
                    {
                        "id": "conn-1",
                        "provider": "openai",
                        "displayName": "OpenAI Production",
                        "accountStatus": "active",
                        "priority": 1
                    },
                    {
                        "id": 2,
                        "provider": "anthropic",
                        "name": "Claude Dev",
                        "status": "active"
                    }
                ],
                "total": 2
            }
            """.data(using: .utf8)!
            
            let response = try JSONDecoder().decode(ProviderListResponse.self, from: json)
            try assertEqual(response.data.count, 2)
            try assertEqual(response.data[0].id.rawValue, "conn-1")
            try assertEqual(response.data[0].effectiveDisplayName, "OpenAI Production")
            try assertEqual(response.data[0].isConnectionActive, true)
            try assertEqual(response.data[1].id.rawValue, "2")
            try assertEqual(response.data[1].effectiveDisplayName, "Claude Dev")
        }
        
        await runner.runTest(name: "ProviderListResponse Decoding (9Router Real Payload with 'connections')") {
            let json = """
            {
                "connections": [
                    {
                        "id": "conn-spark-1",
                        "provider": "spark",
                        "name": "Spark Production",
                        "displayName": "Spark Pro",
                        "status": "active",
                        "priority": 10
                    }
                ],
                "pagination": {
                    "page": 1,
                    "pageSize": 50,
                    "total": 1
                }
            }
            """.data(using: .utf8)!
            
            let response = try JSONDecoder().decode(ProviderListResponse.self, from: json)
            try assertEqual(response.data.count, 1)
            try assertEqual(response.data[0].id.rawValue, "conn-spark-1")
            try assertEqual(response.data[0].provider, "spark")
            try assertEqual(response.data[0].effectiveDisplayName, "Spark Pro")
            try assertEqual(response.data[0].isConnectionActive, true)
        }
        
        await runner.runTest(name: "UsageResponse Decoding (Array format)") {
            let json = """
            {
                "connectionId": "conn-1",
                "quotas": [
                    {
                        "name": "Monthly Limit",
                        "used": 15.50,
                        "total": 50.00,
                        "remaining": 34.50,
                        "remainingPercentage": 69.0,
                        "unit": "$",
                        "resetAt": "2026-10-01T00:00:00Z"
                    }
                ]
            }
            """.data(using: .utf8)!
            
            let response = try JSONDecoder().decode(UsageResponse.self, from: json)
            try assertEqual(response.connectionId?.rawValue, "conn-1")
            try assertEqual(response.quotas.count, 1)
            try assertEqual(response.quotas[0].name, "Monthly Limit")
            try assertEqual(response.quotas[0].used?.value, 15.50)
            try assertEqual(response.quotas[0].total?.value, 50.00)
            try assertEqual(response.quotas[0].unit, "$")
        }
        
        await runner.runTest(name: "UsageResponse Decoding (9Router Real Dictionary format)") {
            let json = """
            {
                "connectionId": "conn-spark-1",
                "quotas": {
                    "spark_session": {
                        "used": 0,
                        "total": 100,
                        "remaining": 100,
                        "resetAt": "2026-10-01T00:00:00Z"
                    },
                    "spark_tokens": {
                        "name": "Custom Token Quota",
                        "used": 5000,
                        "total": 20000,
                        "remaining": 15000,
                        "unit": "tokens"
                    }
                }
            }
            """.data(using: .utf8)!
            
            let response = try JSONDecoder().decode(UsageResponse.self, from: json)
            try assertEqual(response.connectionId?.rawValue, "conn-spark-1")
            try assertEqual(response.quotas.count, 2)
            
            let sessionQuota = response.quotas.first { $0.name == "spark_session" }
            try assertEqual(sessionQuota != nil, true, "spark_session quota tidak ditemukan")
            try assertEqual(sessionQuota?.used?.value, 0.0)
            try assertEqual(sessionQuota?.total?.value, 100.0)
            try assertEqual(sessionQuota?.remaining?.value, 100.0)
            
            let tokenQuota = response.quotas.first { $0.name == "Custom Token Quota" }
            try assertEqual(tokenQuota != nil, true, "Custom Token Quota tidak ditemukan")
            try assertEqual(tokenQuota?.used?.value, 5000.0)
            try assertEqual(tokenQuota?.total?.value, 20000.0)
            try assertEqual(tokenQuota?.unit, "tokens")
        }
        
        // 2. Quota Normalizer Tests
        await runner.runTest(name: "Quota Normalizer (Full Data)") {
            let conn = ProviderConnection(
                id: FlexibleID("conn-1"),
                provider: "openai",
                displayName: "OpenAI Main",
                accountStatus: "active"
            )
            
            let resetDate = Date(timeIntervalSince1970: 1790856000)
            let usage = UsageResponse(
                connectionId: FlexibleID("conn-1"),
                quotas: [
                    QuotaDetailItem(
                        name: "Monthly Spend",
                        used: FlexibleDouble(12.50),
                        total: FlexibleDouble(100.00),
                        remaining: FlexibleDouble(87.50),
                        remainingPercentage: FlexibleDouble(87.5),
                        unit: "$",
                        resetAt: FlexibleDate(resetDate)
                    )
                ]
            )
            
            let normalized = NormalizedProviderQuota.normalize(connection: conn, usage: usage)
            try assertEqual(normalized.connectionId, "conn-1")
            try assertEqual(normalized.provider, "openai")
            try assertEqual(normalized.displayName, "OpenAI Main")
            try assertEqual(normalized.isOnline, true)
            try assertEqual(normalized.hasQuota, true)
            try assertEqual(normalized.authType, "OAuth")
            try assertEqual(normalized.accountName, "OpenAI Main")
            try assertEqual(normalized.metrics.count, 1)
            
            let metric = normalized.metrics[0]
            try assertEqual(metric.name, "Monthly Spend")
            try assertEqual(metric.used, 12.50)
            try assertEqual(metric.total, 100.00)
            try assertEqual(metric.formattedUsage, "$12.50 / $100.00")
            try assertCondition(metric.formattedRemainingSummary?.contains("87.5%") == true)
        }
        
        await runner.runTest(name: "Quota Normalizer (No Fake Data when Empty)") {
            let conn = ProviderConnection(
                id: FlexibleID("conn-free"),
                provider: "groq",
                displayName: "Groq Free Tier",
                accountStatus: "active"
            )
            let usage = UsageResponse(connectionId: FlexibleID("conn-free"), quotas: [])
            let normalized = NormalizedProviderQuota.normalize(connection: conn, usage: usage)
            
            try assertEqual(normalized.connectionId, "conn-free")
            try assertEqual(normalized.hasQuota, false)
            try assertEqual(normalized.metrics.count, 0)
            try assertEqual(normalized.errorMessage, nil)
        }
        
        // 3. Formatters Tests
        await runner.runTest(name: "Formatters (Currency & Numbers)") {
            try assertEqual(Formatters.formatNumber(15.5, unit: "$"), "$15.50")
            try assertEqual(Formatters.formatNumber(100.0, unit: "USD"), "$100.00")
            try assertEqual(Formatters.formatNumber(50000.0, unit: "IDR"), "Rp50.000")
            try assertEqual(Formatters.formatNumber(1500000.0, unit: "tokens"), "1.5M tokens")
            try assertEqual(Formatters.formatNumber(25000.0, unit: "req"), "25.0k req")
            try assertEqual(Formatters.formatPercentage(75.54), "75.5%")
        }
        
        await runner.runTest(name: "Formatters (Progress Bar)") {
            try assertEqual(Formatters.progressBar(percentage: 100.0), "[██████████]")
            try assertEqual(Formatters.progressBar(percentage: 60.0), "[██████░░░░]")
            try assertEqual(Formatters.progressBar(percentage: 0.0), "[░░░░░░░░░░]")
            try assertEqual(Formatters.progressBar(percentage: 80.0), "[████████░░]")
        }
        
        await runner.runTest(name: "Formatters (Countdown Formatting)") {
            let base = Date(timeIntervalSince1970: 1000000)
            let in30m = Date(timeIntervalSince1970: 1000000 + 1800)
            let in3h12m = Date(timeIntervalSince1970: 1000000 + 3 * 3600 + 12 * 60)
            let in1d15h = Date(timeIntervalSince1970: 1000000 + 86400 + 15 * 3600)
            let past = Date(timeIntervalSince1970: 1000000 - 10)
            
            try assertEqual(Formatters.formatCountdown(from: in30m, now: base), "in 30m")
            try assertEqual(Formatters.formatCountdown(from: in3h12m, now: base), "in 3h 12m")
            try assertEqual(Formatters.formatCountdown(from: in1d15h, now: base), "in 1d 15h")
            try assertEqual(Formatters.formatCountdown(from: past, now: base), "Expired")
        }
        
        await runner.runTest(name: "Formatters (Friendly Quota Name Raw Passthrough)") {
            // Antigravity
            try assertEqual(Formatters.friendlyQuotaName(rawName: "claude", provider: "antigravity"), "claude")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "claude_gpt_session", provider: "antigravity"), "claude_gpt_session")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "gemini", provider: "antigravity"), "gemini")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "gemini_session", provider: "antigravity"), "gemini_session")
            
            // Codex
            try assertEqual(Formatters.friendlyQuotaName(rawName: "session", provider: "codex"), "session")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "spark_session", provider: "codex"), "spark_session")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "weekly", provider: "codex"), "weekly")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "spark_weekly", provider: "codex"), "spark_weekly")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "review_session", provider: "codex"), "review_session")
            
            // Claude
            try assertEqual(Formatters.friendlyQuotaName(rawName: "session", provider: "claude"), "session")
            try assertEqual(Formatters.friendlyQuotaName(rawName: "weekly", provider: "claude"), "weekly")
        }
        
        await runner.runTest(name: "NormalizedQuotaMetric (Visual Progress Bar & Reset)") {
            let metric = NormalizedQuotaMetric(
                name: "spark_session",
                used: 0,
                total: 100,
                remaining: 100,
                remainingPercentage: 100.0,
                resetAt: Date(timeIntervalSince1970: 1790856000)
            )
            
            try assertEqual(metric.friendlyName(provider: "codex"), "spark_session")
            try assertCondition(metric.formattedProgressBar.contains("[██████████] 100% sisa (0 / 100)"))
            try assertEqual(metric.icon, "⚡")
        }
        
        // 4. KeychainHelper Tests
        await runner.runTest(name: "KeychainHelper (Save, Read, Update, Delete)") {
            let testService = "com.9router.test.quotamenubar"
            let helper = KeychainHelper(serviceName: testService)
            let testAccount = "test_user_unit_test"
            let testPassword = "super_secret_test_password_123"
            
            helper.deletePassword(for: testAccount)
            
            let saveOk = helper.savePassword(testPassword, for: testAccount)
            try assertEqual(saveOk, true, "Gagal menyimpan password ke Keychain")
            
            let readPass = helper.readPassword(for: testAccount)
            try assertEqual(readPass, testPassword, "Password yang dibaca tidak sesuai")
            
            let updateOk = helper.savePassword("updated_pass", for: testAccount)
            try assertEqual(updateOk, true, "Gagal mengupdate password")
            try assertEqual(helper.readPassword(for: testAccount), "updated_pass")
            
            let deleteOk = helper.deletePassword(for: testAccount)
            try assertEqual(deleteOk, true, "Gagal menghapus password")
            try assertEqual(helper.readPassword(for: testAccount), nil)
        }
        
        // 5. API Client Mock Tests
        await runner.runTest(name: "API Client (Login Success 200)") {
            MockURLProtocol.requestHandler = { request in
                try assertEqual(request.httpMethod, "POST")
                try assertEqual(request.url?.path, "/api/auth/login")
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Set-Cookie": "session=abc123; Path=/"]
                )!
                let data = "{\"success\": true}".data(using: .utf8)!
                return (response, data)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            let result = try await client.login(password: "test_pass")
            try assertEqual(result, true)
            MockURLProtocol.requestHandler = nil
        }
        
        await runner.runTest(name: "API Client (Login Unauthorized 401)") {
            MockURLProtocol.requestHandler = { request in
                let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                let data = "{\"error\": \"Unauthorized\"}".data(using: .utf8)!
                return (response, data)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            do {
                _ = try await client.login(password: "wrong")
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Seharusnya gagal"])
            } catch let err as APIError {
                try assertEqual(err, .unauthorized)
            }
            MockURLProtocol.requestHandler = nil
        }
        
        await runner.runTest(name: "API Client (Fetch Providers)") {
            MockURLProtocol.requestHandler = { request in
                try assertEqual(request.httpMethod, "GET")
                try assertEqual(request.url?.path, "/api/providers/client")
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let json = "{\"data\": [{\"id\": \"c1\", \"provider\": \"openai\", \"displayName\": \"OpenAI\"}]}".data(using: .utf8)!
                return (response, json)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            let list = try await client.fetchProviders()
            try assertEqual(list.count, 1)
            try assertEqual(list[0].id.rawValue, "c1")
            MockURLProtocol.requestHandler = nil
        }
        
        await runner.runTest(name: "API Client (Fetch Usage)") {
            MockURLProtocol.requestHandler = { request in
                try assertEqual(request.httpMethod, "GET")
                try assertEqual(request.url?.path, "/api/usage/c1")
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let json = "{\"connectionId\": \"c1\", \"quotas\": [{\"name\": \"Daily\", \"used\": 10, \"total\": 100}]}".data(using: .utf8)!
                return (response, json)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            let usage = try await client.fetchUsage(for: "c1")
            try assertEqual(usage.connectionId?.rawValue, "c1")
            try assertEqual(usage.quotas.count, 1)
            try assertEqual(usage.quotas[0].used?.value, 10.0)
            MockURLProtocol.requestHandler = nil
        }
        
        await runner.runTest(name: "API Client (Offline Connection Error)") {
            MockURLProtocol.requestHandler = { request in
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotConnectToHost, userInfo: nil)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            do {
                _ = try await client.fetchProviders()
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Seharusnya gagal"])
            } catch let err as APIError {
                try assertEqual(err, .offline)
            }
            MockURLProtocol.requestHandler = nil
        }
        
        // 6. QuotaManager Auto-Login Tests
        await runner.runTest(name: "QuotaManager Auto-Login with default 123456 when Keychain empty") {
            let testService = "com.9router.test.quotamenubar.autologin"
            let helper = KeychainHelper(serviceName: testService)
            helper.deletePassword()
            
            nonisolated(unsafe) var loginSucceeded = false
            MockURLProtocol.requestHandler = { request in
                if request.url?.path == "/api/providers/client" {
                    if loginSucceeded {
                        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                        let json = "{\"connections\": [{\"id\": \"c1\", \"provider\": \"spark\", \"displayName\": \"Spark\"}]}".data(using: .utf8)!
                        return (response, json)
                    } else {
                        let response = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
                        let json = "{\"error\": \"Unauthorized\"}".data(using: .utf8)!
                        return (response, json)
                    }
                } else if request.url?.path == "/api/auth/login" {
                    loginSucceeded = true
                    let response = HTTPURLResponse(
                        url: request.url!,
                        statusCode: 200,
                        httpVersion: nil,
                        headerFields: nil
                    )!
                    let data = "{\"success\": true}".data(using: .utf8)!
                    return (response, data)
                } else if request.url?.path == "/api/usage/c1" {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    let json = "{\"connectionId\": \"c1\", \"quotas\": {\"session\": {\"used\": 5, \"total\": 100}}}".data(using: .utf8)!
                    return (response, json)
                }
                
                throw NSError(domain: "Test", code: 404, userInfo: nil)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            let manager = QuotaManager(apiClient: client, keychainHelper: helper)
            
            await manager.refreshQuotas()
            let status = manager.status
            try assertEqual(status, .connected(providerCount: 1))
            
            let saved = helper.readPassword()
            try assertEqual(saved, "123456")
            
            let quotas = manager.quotas
            try assertEqual(quotas.count, 1)
            try assertEqual(quotas[0].metrics.count, 1)
            try assertEqual(quotas[0].metrics[0].name, "session")
            try assertEqual(quotas[0].metrics[0].used, 5.0)
            
            helper.deletePassword()
            MockURLProtocol.requestHandler = nil
        }
        
        // 7. Provider Quota Grouping & Filtering Tests
        await runner.runTest(name: "Provider Quota Grouping & Filter Logic") {
            let p1 = NormalizedProviderQuota(connectionId: "c1", provider: "antigravity", displayName: "Anti 1", accountStatus: "active", isOnline: true)
            let p2 = NormalizedProviderQuota(connectionId: "c2", provider: "antigravity", displayName: "Anti 2", accountStatus: "active", isOnline: true)
            let p3 = NormalizedProviderQuota(connectionId: "c3", provider: "codex", displayName: "Codex 1", accountStatus: "active", isOnline: true)
            let p4 = NormalizedProviderQuota(connectionId: "c4", provider: "claude", displayName: "Claude 1", accountStatus: "active", isOnline: true)
            
            let allQuotas = [p1, p2, p3, p4]
            
            // Filter "all"
            let allFiltered = allQuotas.filter { _ in true }
            try assertEqual(allFiltered.count, 4)
            
            // Filter "antigravity"
            let antiFiltered = allQuotas.filter { $0.provider.lowercased() == "antigravity" }
            try assertEqual(antiFiltered.count, 2)
            try assertEqual(antiFiltered[0].connectionId, "c1")
            try assertEqual(antiFiltered[1].connectionId, "c2")
            
            // Filter "codex"
            let codexFiltered = allQuotas.filter { $0.provider.lowercased() == "codex" }
            try assertEqual(codexFiltered.count, 1)
            try assertEqual(codexFiltered[0].connectionId, "c3")
            
            // Filter non-existent
            let emptyFiltered = allQuotas.filter { $0.provider.lowercased() == "gemini" }
            try assertEqual(emptyFiltered.count, 0)
        }
        
        // 8. Model & Provider Toggle Tests
        await runner.runTest(name: "Model & Provider Toggle API Client & QuotaManager") {
            MockURLProtocol.requestHandler = { request in
                try assertEqual(request.url?.path, "/api/providers/c-test-1")
                try assertCondition(request.httpMethod == "PATCH" || request.httpMethod == "PUT")
                
                let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                let data = "{\"success\": true}".data(using: .utf8)!
                return (response, data)
            }
            
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [MockURLProtocol.self]
            let session = URLSession(configuration: config)
            let client = NineRouterAPIClient(baseURL: URL(string: "http://localhost:20128")!, session: session)
            
            let toggleOk = try await client.updateProviderStatus(connectionId: "c-test-1", isEnabled: false)
            try assertEqual(toggleOk, true, "Toggle provider status gagal")
            
            let testService = "com.9router.test.quotamenubar.toggle"
            let helper = KeychainHelper(serviceName: testService)
            let manager = QuotaManager(apiClient: client, keychainHelper: helper)
            
            let result = await manager.toggleModel(connectionId: "c-test-1", metricName: "spark_session", isEnabled: false)
            switch result {
            case .success:
                break
            case .failure(let error):
                throw error
            }
            
            MockURLProtocol.requestHandler = nil
        }
        
        // 9. Session (5 Hours) vs Weekly (Mingguan) Quota Classification Tests
        await runner.runTest(name: "Session vs Weekly Quota Classification & Family Grouping") {
            let mGeminiSession = NormalizedQuotaMetric(name: "gemini_session", used: 10, total: 100)
            let mGeminiWeekly = NormalizedQuotaMetric(name: "gemini_weekly", used: 50, total: 200)
            let mClaudeSession = NormalizedQuotaMetric(name: "claude_gpt_session", used: 0, total: 100)
            let mClaudeWeekly = NormalizedQuotaMetric(name: "claude_gpt_weekly", used: 20, total: 100)
            let mWeeklyToken = NormalizedQuotaMetric(name: "weekly_token_limit", used: 100, total: 500)
            
            try assertEqual(mClaudeSession.isWeekly, false, "claude_gpt_session seharusnya bukan weekly")
            try assertEqual(mGeminiSession.isWeekly, false, "gemini_session seharusnya bukan weekly")
            try assertEqual(mGeminiWeekly.isWeekly, true, "gemini_weekly seharusnya weekly")
            try assertEqual(mClaudeWeekly.isWeekly, true, "claude_gpt_weekly seharusnya weekly")
            try assertEqual(mWeeklyToken.isWeekly, true, "weekly_token_limit seharusnya weekly")
            
            try assertEqual(mGeminiSession.durationLabel, "5 Jam (Sesi)")
            try assertEqual(mGeminiWeekly.durationLabel, "Mingguan (Weekly)")
            
            let provider = NormalizedProviderQuota(
                connectionId: "p1",
                provider: "antigravity",
                displayName: "Antigravity",
                accountStatus: "active",
                isOnline: true,
                metrics: [mGeminiSession, mClaudeSession, mGeminiWeekly, mClaudeWeekly]
            )
            
            try assertEqual(provider.sessionMetrics.count, 2, "Jumlah session metrics harus 2")
            try assertEqual(provider.weeklyMetrics.count, 2, "Jumlah weekly metrics harus 2")
            
            // Verifikasi Family Groups: Gemini dan Claude & GPT
            let families = provider.familyGroups
            try assertEqual(families.count, 2, "Harus ada 2 keluarga model (Gemini dan Claude & GPT)")
            
            let geminiFamily = families.first { $0.title == "Gemini" }
            try assertEqual(geminiFamily != nil, true, "Grup Gemini harus ditemukan")
            try assertEqual(geminiFamily?.metrics.count, 2, "Grup Gemini harus punya 2 metrik (5 Jam dan Weekly)")
            try assertEqual(geminiFamily?.metrics[0].name, "gemini_session", "Metrik 5 jam sesi harus di urutan pertama")
            try assertEqual(geminiFamily?.metrics[1].name, "gemini_weekly", "Metrik mingguan harus di urutan kedua")
            
            let claudeFamily = families.first { $0.title == "Claude & GPT" }
            try assertEqual(claudeFamily != nil, true, "Grup Claude & GPT harus ditemukan")
            try assertEqual(claudeFamily?.metrics.count, 2, "Grup Claude & GPT harus punya 2 metrik (5 Jam dan Weekly)")
            try assertEqual(claudeFamily?.metrics[0].name, "claude_gpt_session")
            try assertEqual(claudeFamily?.metrics[1].name, "claude_gpt_weekly")
        }
        
        let allSuccess = runner.summarize()
        if !allSuccess {
            exit(1)
        }
    }
}
