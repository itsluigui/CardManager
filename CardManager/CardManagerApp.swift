import SwiftUI

@main
struct CardManagerApp: App {
    @StateObject private var store = FinanceStore()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(store)
        }
    }
}
