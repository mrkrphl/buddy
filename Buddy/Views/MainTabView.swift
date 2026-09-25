import SwiftUI

struct MainTabView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)

            PlanView()
                .tabItem {
                    Label("Plan", systemImage: "list.bullet.clipboard")
                }
                .tag(1)

            ChatView()
                .tabItem {
                    Label("Buddy", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(2)
        }
        .tint(BuddyTheme.needle)
        .toolbarBackground(BuddyTheme.canvas, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
