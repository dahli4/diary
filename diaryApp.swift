import SwiftUI
import SwiftData

@main
struct diaryApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var authenticationService = AuthenticationService()

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Item.self,
    ])
    // iCloud + 로컬 자동 동기화 (오프라인에서도 로컬 저장으로 정상 동작)
    // 사전 요구사항: Xcode > Signing & Capabilities > iCloud (CloudKit 체크) 추가 필요
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      cloudKitDatabase: .automatic
    )

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(authenticationService)
    }
    .modelContainer(sharedModelContainer)
  }
}
