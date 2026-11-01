import SwiftUI
import InstaVisionKit

struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var tokenExpiry: Date?
    @State private var cacheCleared = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    if let profile = session.feed?.profile {
                        LabeledContent("Username", value: "@\(profile.username)")
                        if let type = profile.accountType {
                            LabeledContent("Account type", value: type.displayName)
                        }
                    }
                    LabeledContent("Mode", value: session.state == .demo ? "Demo" : "Instagram")
                    if session.state == .signedIn {
                        LabeledContent("Token expires") {
                            if let tokenExpiry {
                                Text(tokenExpiry, format: .relative(presentation: .named))
                            } else {
                                Text("Unknown")
                            }
                        }
                    }
                }

                Section("Storage") {
                    Button(cacheCleared ? "Image Cache Cleared" : "Clear Image Cache", systemImage: "trash") {
                        Task {
                            await ImageDataCache.shared.removeAll()
                            cacheCleared = true
                        }
                    }
                    .disabled(cacheCleared)
                }

                Section {
                    Button(session.state == .demo ? "Exit Demo" : "Sign Out", role: .destructive) {
                        Task {
                            dismiss()
                            await session.signOut()
                        }
                    }
                } footer: {
                    Text("InstaVision is not affiliated with Instagram or Meta.")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 520, minHeight: 560)
        .task { tokenExpiry = await session.tokenExpiry() }
    }
}

private extension InstagramProfile.AccountType {
    var displayName: String {
        switch self {
        case .business: "Business"
        case .mediaCreator: "Creator"
        case .personal: "Personal"
        case .unknown: "Other"
        }
    }
}
