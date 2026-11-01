import SwiftUI

struct SignInView: View {
    @Environment(AppSession.self) private var session
    @State private var token = ""

    private let docsURL = URL(string: "https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login")!

    var body: some View {
        @Bindable var session = session
        VStack(spacing: 28) {
            VStack(spacing: 10) {
                Image(systemName: "camera.aperture")
                    .font(.system(size: 72))
                    .foregroundStyle(.tint)
                Text("InstaVision")
                    .font(.extraLargeTitle)
                Text("Your Instagram, in your space.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Access token")
                    .font(.headline)
                SecureField("Paste an Instagram access token", text: $token)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .onSubmit(signIn)
                Text("Works with Instagram professional (business or creator) accounts. [How to get a token](\(docsURL.absoluteString))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if let error = session.signInError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: 520)

            HStack(spacing: 16) {
                Button("Try the Demo") { session.startDemo() }
                    .buttonStyle(.bordered)
                Button(action: signIn) {
                    if session.isSigningIn {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(token.isEmpty || session.isSigningIn)
            }
        }
        .padding(56)
        .glassBackgroundEffect()
    }

    private func signIn() {
        Task { await session.signIn(token: token) }
    }
}

#Preview(windowStyle: .automatic) {
    SignInView()
        .environment(AppSession())
}
