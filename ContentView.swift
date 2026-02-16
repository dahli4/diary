import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var openComposerToken = 0
    @State private var reminderPrompt: String?
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authenticationService: AuthenticationService
    @AppStorage("isBiometricLockEnabled") private var biometricLockEnabled = false
    
    var body: some View {
        Group {
            if biometricLockEnabled && !authenticationService.isUnlocked {
                lockOverlay
            } else {
                mainTabs
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NotificationManager.openEditorFromReminder)) { output in
            let prompt = output.userInfo?["prompt"] as? String
            reminderPrompt = prompt
            selectedTab = 0
            openComposerToken += 1
        }
        .onChange(of: biometricLockEnabled) { _, enabled in
            if enabled {
                authenticationService.isUnlocked = false
                authenticationService.authenticate()
            } else {
                authenticationService.isUnlocked = true
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard biometricLockEnabled else { return }
            if phase == .background {
                authenticationService.isUnlocked = false
            }
            if phase == .active && !authenticationService.isUnlocked {
                authenticationService.authenticate()
            }
        }
        .onAppear {
            if biometricLockEnabled && !authenticationService.isUnlocked {
                authenticationService.authenticate()
            }
        }
    }

    private var mainTabs: some View {
        TabView(selection: $selectedTab) {
            MainListView(openComposerToken: $openComposerToken, reminderPrompt: $reminderPrompt)
                .tabItem {
                    Label("홈", systemImage: "house")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("캘린더", systemImage: "calendar")
                }
                .tag(1)
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("설정", systemImage: "gearshape")
            }
            .tag(2)
        }
        .tint(.primary)
    }

    private var lockOverlay: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 32))
                Text("잠금 해제 필요")
                    .font(.headline)
                Text("Face ID 또는 Touch ID로 잠금을 해제하세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button("잠금 해제") {
                    authenticationService.authenticate()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 28)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationService())
        .modelContainer(for: Item.self, inMemory: true)
}
