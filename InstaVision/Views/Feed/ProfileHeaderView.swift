import SwiftUI
import InstaVisionKit

struct ProfileHeaderView: View {
    let profile: InstagramProfile

    var body: some View {
        HStack(spacing: 28) {
            CachedImage(url: profile.profilePictureURL, image: { image in
                image.resizable().scaledToFill()
            }, placeholder: {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .foregroundStyle(.secondary)
            })
            .frame(width: 120, height: 120)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name ?? profile.username)
                    .font(.largeTitle.weight(.semibold))
                Text("@\(profile.username)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                HStack(spacing: 32) {
                    stat(profile.mediaCount, "posts")
                    stat(profile.followersCount, "followers")
                    stat(profile.followsCount, "following")
                }
                .padding(.top, 4)
            }
            Spacer()
        }
    }

    @ViewBuilder private func stat(_ value: Int?, _ label: String) -> some View {
        if let value {
            VStack(alignment: .leading) {
                Text(value, format: .number.notation(.compactName)).font(.title2.bold())
                Text(label).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
