import SwiftUI
import AppKit
import QuotaTrackerCore

/// View Utama Popover Quota Tracker bergaya Dashboard Cards 9Router
public struct QuotaDashboardView: View {
    @ObservedObject var quotaManager: QuotaManager
    var onOpenPasswordPrompt: () -> Void
    var onOpenDashboard: () -> Void
    var onQuitApp: () -> Void
    var onToggleAutoStart: () -> Void
    
    private var _selectedProviderFilter = SwiftUI.State<String>(initialValue: "all")
    private var selectedProviderFilter: String {
        get { _selectedProviderFilter.wrappedValue }
        nonmutating set { _selectedProviderFilter.wrappedValue = newValue }
    }
    
    public init(
        quotaManager: QuotaManager,
        onOpenPasswordPrompt: @escaping () -> Void,
        onOpenDashboard: @escaping () -> Void,
        onQuitApp: @escaping () -> Void,
        onToggleAutoStart: @escaping () -> Void = {
            _ = AutoStartManager.shared.setAutoStart(enabled: !AutoStartManager.shared.isAutoStartEnabled)
        }
    ) {
        self.quotaManager = quotaManager
        self.onOpenPasswordPrompt = onOpenPasswordPrompt
        self.onOpenDashboard = onOpenDashboard
        self.onQuitApp = onQuitApp
        self.onToggleAutoStart = onToggleAutoStart
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Header Popover
            popoverHeader
                .padding(.horizontal, 10)
                .padding(.top, 8)
                .padding(.bottom, 6)
            
            Divider()
                .opacity(0.6)
            
            // 1.5. Filter Selector Bar (Muncul jika ada data provider)
            if !quotaManager.quotas.isEmpty {
                filterSelectorBar
                
                Divider()
                    .opacity(0.4)
            }
            
            // 2. Konten Utama (Scrollable Cards)
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 8) {
                    statusBannerView
                    
                    if quotaManager.quotas.isEmpty && !quotaManager.isRefreshing {
                        emptyStateView
                    } else if filteredQuotas.isEmpty && !quotaManager.isRefreshing {
                        filteredEmptyStateView
                    } else {
                        ForEach(filteredQuotas) { provider in
                            ProviderCardView(
                                provider: provider,
                                onToggleMetric: { metricName, isEnabled in
                                    Task {
                                        _ = await quotaManager.toggleModel(
                                            connectionId: provider.connectionId,
                                            metricName: metricName,
                                            isEnabled: isEnabled
                                        )
                                    }
                                }
                            )
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)
            
            Divider()
                .opacity(0.6)
            
            // 3. Footer Status & Action Bar
            popoverFooter
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
        }
        .frame(minWidth: 360, idealWidth: 460, maxWidth: 650, minHeight: 420, idealHeight: 700, maxHeight: 900)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Header
    
    private var popoverHeader: some View {
        HStack(spacing: 10) {
            // Icon Logo 9R
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                
                Text("9R")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("9Router Quota")
                    .font(.system(size: 14, weight: .bold))
                
                Text("Quota & Usage Tracker")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Tombol Buka Web Dashboard
            Button(action: onOpenDashboard) {
                Image(systemName: "safari")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Buka Quota Tracker Web")
            
            // Tombol Refresh Animatif
            Button(action: {
                Task {
                    await quotaManager.refreshQuotas()
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(quotaManager.isRefreshing ? .accentColor : .secondary)
                    .rotationEffect(Angle(degrees: quotaManager.isRefreshing ? 360 : 0))
                    .animation(
                        quotaManager.isRefreshing
                            ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false)
                            : .default,
                        value: quotaManager.isRefreshing
                    )
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(quotaManager.isRefreshing)
            .help("Refresh Data Kuota")
            
            // Menu Aksi Tambahan
            Menu {
                Button("Atur Password...", action: onOpenPasswordPrompt)
                
                Button(
                    AutoStartManager.shared.isAutoStartEnabled ? "✓ Auto-start saat Login (Aktif)" : "Auto-start saat Login (Nonaktif)",
                    action: onToggleAutoStart
                )
                
                Divider()
                
                Button("Logout (Hapus Sesi)") {
                    quotaManager.logout(clearKeychain: true)
                }
                
                Divider()
                
                Button("Keluar (Quit)", action: onQuitApp)
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 24, height: 24)
            .help("Pengaturan & Menu")
        }
    }
    
    // MARK: - Status Banner
    
    @ViewBuilder
    private var statusBannerView: some View {
        switch quotaManager.status {
        case .loginRequired:
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.orange)
                    Text("Perlu Login 9Router")
                        .font(.system(size: 12, weight: .bold))
                }
                Text("Password diperlukan untuk mengakses data kuota.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Button("Atur Password Sekarang", action: onOpenPasswordPrompt)
                    .font(.system(size: 11, weight: .medium))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .padding(.top, 2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            
        case .offline:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                    Text("9Router Offline")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                Text("Pastikan 9Router berjalan di port 20128 (localhost).")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Button("Coba Hubungkan Kembali") {
                    Task { await quotaManager.refreshQuotas() }
                }
                .font(.system(size: 11))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 2)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.red.opacity(0.25), lineWidth: 1)
            )
            
        case .error(let msg):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(msg)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
            
        case .loading:
            if quotaManager.quotas.isEmpty {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Memuat data kuota...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
        case .connected, .idle:
            EmptyView()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Belum Ada Provider Terdaftar")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Button("Buka Web Dashboard", action: onOpenDashboard)
                .font(.system(size: 11))
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
    
    private var filteredEmptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 28))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Tidak ada akun untuk provider ini")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
            Button("Tampilkan Semua Provider") {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedProviderFilter = "all"
                }
            }
            .font(.system(size: 11))
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
    
    // MARK: - Filter Selector & Logic
    
    struct ProviderFilterOption: Identifiable, Hashable {
        let id: String
        let title: String
        let count: Int
    }
    
    private var providerFilterOptions: [ProviderFilterOption] {
        let total = quotaManager.quotas.count
        var options: [ProviderFilterOption] = [
            ProviderFilterOption(id: "all", title: "Semua", count: total)
        ]
        
        var counts: [String: (rawName: String, count: Int)] = [:]
        var orderedKeys: [String] = []
        
        for item in quotaManager.quotas {
            let key = item.provider.lowercased()
            if let existing = counts[key] {
                counts[key] = (existing.rawName, existing.count + 1)
            } else {
                counts[key] = (item.provider, 1)
                orderedKeys.append(key)
            }
        }
        
        for key in orderedKeys {
            if let data = counts[key] {
                let title = formatProviderName(data.rawName)
                options.append(ProviderFilterOption(id: key, title: title, count: data.count))
            }
        }
        
        return options
    }
    
    private var filteredQuotas: [NormalizedProviderQuota] {
        if selectedProviderFilter == "all" {
            return quotaManager.quotas
        }
        return quotaManager.quotas.filter {
            $0.provider.lowercased() == selectedProviderFilter.lowercased()
        }
    }
    
    private var filterSelectorBar: some View {
        HStack(spacing: 4) {
            // Horizontal scrollable filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(providerFilterOptions) { option in
                        filterChip(option: option)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
            }
            
            // Dropdown Menu Selector Cepat
            Menu {
                ForEach(providerFilterOptions) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedProviderFilter = option.id
                        }
                    }) {
                        if selectedProviderFilter == option.id {
                            Text("✓ \(option.title) (\(option.count))")
                        } else {
                            Text("   \(option.title) (\(option.count))")
                        }
                    }
                }
            } label: {
                Image(systemName: selectedProviderFilter == "all" ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedProviderFilter == "all" ? .secondary : .accentColor)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .padding(.trailing, 10)
            .help("Pilih Kelompok Provider")
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.35))
    }
    
    private func filterChip(option: ProviderFilterOption) -> some View {
        let isSelected = selectedProviderFilter == option.id
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedProviderFilter = option.id
            }
        }) {
            HStack(spacing: 5) {
                if option.id != "all" {
                    Circle()
                        .fill(providerColor(for: option.id))
                        .frame(width: 6, height: 6)
                }
                
                Text(option.title)
                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                
                // Badge Jumlah Akun
                Text("\(option.count)")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.25) : Color.secondary.opacity(0.12))
                    )
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.08), lineWidth: 1)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
    
    private func formatProviderName(_ raw: String) -> String {
        let p = raw.lowercased()
        if p == "antigravity" { return "Antigravity" }
        if p == "codex" { return "Codex" }
        if p == "openai" || p == "chatgpt" { return "OpenAI" }
        if p == "claude" || p == "anthropic" { return "Claude" }
        if p == "gemini" || p == "google" { return "Gemini" }
        if p == "spark" { return "Spark" }
        if p == "groq" { return "Groq" }
        if p == "deepseek" { return "DeepSeek" }
        return raw.capitalized
    }
    
    private func providerColor(for raw: String) -> Color {
        let p = raw.lowercased()
        if p == "antigravity" { return .purple }
        if p == "codex" { return .teal }
        if p == "claude" || p == "anthropic" { return .orange }
        if p == "openai" || p == "chatgpt" { return .green }
        if p == "gemini" || p == "google" { return .blue }
        if p == "spark" { return .yellow }
        if p == "deepseek" { return .cyan }
        return .secondary
    }
    
    // MARK: - Footer
    
    private var popoverFooter: some View {
        VStack(spacing: 8) {
            HStack {
                // Status Server & Koneksi
                HStack(spacing: 5) {
                    Circle()
                        .fill(serverStatusColor)
                        .frame(width: 7, height: 7)
                    
                    Text(serverStatusLabel)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let lastUpdated = quotaManager.lastUpdated {
                    Text(Formatters.formatDateTime(lastUpdated))
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            
            // Action Buttons Bar
            HStack(spacing: 8) {
                Button(action: onOpenDashboard) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 10))
                        Text("Web Dashboard")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    Task { await quotaManager.refreshQuotas() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                        Text("Refresh")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: onQuitApp) {
                    Text("Keluar")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
    
    private var serverStatusColor: Color {
        switch quotaManager.status {
        case .connected:
            return .green
        case .loading:
            return .blue
        case .loginRequired:
            return .orange
        case .offline, .error:
            return .red
        case .idle:
            return .gray
        }
    }
    
    private var serverStatusLabel: String {
        switch quotaManager.status {
        case .connected(let count):
            return "9Router Connected (\(count) Provider)"
        case .loading:
            return "Refreshing..."
        case .loginRequired:
            return "9Router (Login Diperlukan)"
        case .offline:
            return "9Router Offline (:20128)"
        case .error:
            return "Koneksi Bermasalah"
        case .idle:
            return "9Router Siap"
        }
    }
}

// MARK: - Provider Card View

public struct ProviderCardView: View {
    let provider: NormalizedProviderQuota
    var onToggleMetric: ((String, Bool) -> Void)? = nil
    
    public init(
        provider: NormalizedProviderQuota,
        onToggleMetric: ((String, Bool) -> Void)? = nil
    ) {
        self.provider = provider
        self.onToggleMetric = onToggleMetric
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Card
            cardHeader
            
            // List Metrik Kuota
            if provider.metrics.isEmpty {
                if let err = provider.errorMessage, !err.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.orange)
                            .font(.system(size: 11))
                        Text(err)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                } else {
                    Text("Tidak ada batasan kuota terdaftar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 2)
                }
            } else {
                VStack(spacing: 11) {
                    // Kelompok 1: Kuota 5 Jam / Sesi
                    if !provider.sessionMetrics.isEmpty {
                        VStack(alignment: .leading, spacing: 7) {
                            HStack(spacing: 5) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.blue)
                                Text("Kuota 5 Jam (Sesi)")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.top, 2)
                            
                            VStack(spacing: 8) {
                                ForEach(Array(provider.sessionMetrics.enumerated()), id: \.offset) { _, metric in
                                    MetricRowView(
                                        metric: metric,
                                        provider: provider.provider,
                                        onToggle: { isEnabled in
                                            onToggleMetric?(metric.name, isEnabled)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Pembatas
                    Divider()
                        .opacity(0.35)
                    
                    // Kelompok 2: Kuota Mingguan (Weekly)
                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 5) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.purple)
                            Text("Kuota Mingguan (Weekly)")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.top, 2)
                        
                        if !provider.weeklyMetrics.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(Array(provider.weeklyMetrics.enumerated()), id: \.offset) { _, metric in
                                    MetricRowView(
                                        metric: metric,
                                        provider: provider.provider,
                                        onToggle: { isEnabled in
                                            onToggleMetric?(metric.name, isEnabled)
                                        }
                                    )
                                }
                            }
                        } else {
                            Text("Tidak ada batasan kuota mingguan")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary.opacity(0.7))
                                .padding(.vertical, 2)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
    
    private var cardHeader: some View {
        VStack(spacing: 6) {
            // Baris 1: Ikon Brand + Nama Provider + Status Online
            HStack(spacing: 8) {
                // Ikon Logo Brand
                providerBrandIcon
                
                // Nama Provider
                Text(providerTitleFormatted)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Status Aktif Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(provider.isOnline ? Color.green : Color.gray)
                        .frame(width: 6, height: 6)
                    Text(provider.isOnline ? "Active" : "Inactive")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(provider.isOnline ? .green : .secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(provider.isOnline ? Color.green.opacity(0.12) : Color.secondary.opacity(0.1))
                )
            }
            
            // Baris 2: Badge Akun, Tipe Auth, dan Waktu Reset Terdekat
            HStack(spacing: 6) {
                // Badge Akun (misal: "default", "spark-prod")
                Text(provider.accountName ?? "default")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.12))
                    )
                
                // Badge Tipe Auth (misal: "OAuth", "API Key", "Bearer")
                if let auth = provider.authType, !auth.isEmpty {
                    Text(auth)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.12))
                        )
                }
                
                Spacer()
                
                // Waktu Reset Terdekat (misal: "⏳ in 1d 15h" atau "⏳ in 3h 12m")
                if let countdown = provider.formattedNearestResetCountdown {
                    HStack(spacing: 3) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 9))
                        Text(countdown)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.orange.opacity(0.12))
                    )
                }
            }
        }
    }
    
    private var providerTitleFormatted: String {
        let p = provider.provider.lowercased()
        if p == "antigravity" { return "Antigravity" }
        if p == "codex" { return "Codex" }
        if p == "openai" || p == "chatgpt" { return "OpenAI" }
        if p == "claude" || p == "anthropic" { return "Claude" }
        if p == "gemini" || p == "google" { return "Gemini" }
        if p == "spark" { return "Spark" }
        if p == "groq" { return "Groq" }
        if p == "deepseek" { return "DeepSeek" }
        return provider.provider.capitalized
    }
    
    private var providerBrandIcon: some View {
        let p = provider.provider.lowercased()
        let gradient: LinearGradient
        let iconName: String
        
        if p == "antigravity" {
            gradient = LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "sparkles"
        } else if p == "codex" {
            gradient = LinearGradient(colors: [Color.teal, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "bolt.fill"
        } else if p == "claude" || p == "anthropic" {
            gradient = LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "cpu"
        } else if p == "openai" || p == "chatgpt" {
            gradient = LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "brain.head.profile"
        } else if p == "gemini" || p == "google" {
            gradient = LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "sparkle"
        } else if p == "spark" {
            gradient = LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "bolt.circle.fill"
        } else if p == "deepseek" {
            gradient = LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "cube.transparent.fill"
        } else {
            gradient = LinearGradient(colors: [Color.gray, Color.secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
            iconName = "cube.fill"
        }
        
        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(gradient)
                .frame(width: 22, height: 22)
            
            Image(systemName: iconName)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Metric Row View

public struct MetricRowView: View {
    let metric: NormalizedQuotaMetric
    let provider: String
    var onToggle: ((Bool) -> Void)? = nil
    
    private var _isEnabled: SwiftUI.State<Bool>
    private var isEnabled: Bool {
        get { _isEnabled.wrappedValue }
        nonmutating set { _isEnabled.wrappedValue = newValue }
    }
    
    public init(
        metric: NormalizedQuotaMetric,
        provider: String,
        onToggle: ((Bool) -> Void)? = nil
    ) {
        self.metric = metric
        self.provider = provider
        self.onToggle = onToggle
        self._isEnabled = SwiftUI.State<Bool>(initialValue: metric.isEnabled)
    }
    
    public var body: some View {
        VStack(spacing: 4) {
            // Baris 1: Nama Kuota/Model & Persentase Sisa + Sakelar Toggle
            HStack(spacing: 6) {
                // Ikon & Nama Model / Kuota
                HStack(spacing: 4) {
                    Text(metric.icon)
                        .font(.system(size: 11))
                    
                    Text(metric.friendlyName(provider: provider))
                        .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                        .foregroundColor(isEnabled ? .primary : .secondary)
                }
                
                Spacer()
                
                // Angka Persentase Sisa + Label
                Text("\(Int(round(metric.effectiveRemainingPercentage)))% remaining")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isEnabled ? remainingColor : .secondary)
                
                // Sakelar Toggle Kompak Modern
                Button(action: {
                    let newState = !isEnabled
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isEnabled = newState
                    }
                    onToggle?(newState)
                }) {
                    ZStack(alignment: isEnabled ? .trailing : .leading) {
                        Capsule()
                            .fill(isEnabled ? Color.green : Color.secondary.opacity(0.35))
                            .frame(width: 28, height: 16)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .padding(.horizontal, 2)
                            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 0.5)
                    }
                }
                .buttonStyle(.plain)
                .help(isEnabled ? "Model Aktif (Klik untuk Nonaktifkan)" : "Model Nonaktif (Klik untuk Aktifkan)")
            }
            
            // Baris 2: Visual Modern Thin Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track Background
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 5)
                    
                    // Filled Track
                    Capsule()
                        .fill(isEnabled ? remainingColor : Color.secondary.opacity(0.4))
                        .frame(
                            width: max(0, min(geo.size.width, geo.size.width * CGFloat(metric.effectiveRemainingPercentage / 100.0))),
                            height: 5
                        )
                }
            }
            .frame(height: 5)
            .padding(.vertical, 1)
            
            // Baris 3: Nilai Pemakaian (0 / 100) & Waktu Reset Spesifik
            HStack {
                // Info Penggunaan / Kuota
                Text(usageSubtitle)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Reset Countdown Spesifik Baris
                if let resetCountdown = metric.formattedCountdown {
                    HStack(spacing: 2.5) {
                        Image(systemName: "clock")
                            .font(.system(size: 8.5))
                        Text(resetCountdown)
                            .font(.system(size: 9.5, weight: .regular))
                    }
                    .foregroundColor(.secondary)
                } else if let relReset = metric.formattedResetRelative {
                    Text(relReset)
                        .font(.system(size: 9.5, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var remainingColor: Color {
        let pct = metric.effectiveRemainingPercentage
        if pct >= 60.0 {
            return Color.green
        } else if pct >= 20.0 {
            return Color.orange
        } else {
            return Color.red
        }
    }
    
    private var usageSubtitle: String {
        if let used = metric.used, let total = metric.total {
            let uStr = Formatters.formatNumber(used, unit: metric.unit)
            let tStr = Formatters.formatNumber(total, unit: metric.unit)
            return "\(uStr) / \(tStr)"
        } else if let rem = metric.remaining {
            return "Sisa: \(Formatters.formatNumber(rem, unit: metric.unit))"
        } else if let used = metric.used {
            return "Terpakai: \(Formatters.formatNumber(used, unit: metric.unit))"
        }
        return ""
    }
}
