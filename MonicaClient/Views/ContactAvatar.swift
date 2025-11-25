import SwiftUI

/// Reusable contact avatar component that displays contact photos with fallbacks
struct ContactAvatar: View {
    let contact: ContactEntity
    let size: CGFloat
    @EnvironmentObject var authManager: AuthenticationManager

    init(contact: ContactEntity, size: CGFloat = 40) {
        self.contact = contact
        self.size = size
    }

    var body: some View {
        Group {
            if let avatarURL = avatarURL, let url = URL(string: avatarURL) {
                let _ = print("🔍 [ContactAvatar] Found avatar URL for \(contact.fullName): \(avatarURL)")
                // Use authenticated image loader for avatar photos
                AuthenticatedAsyncImage(
                    url: url,
                    apiToken: authManager.apiToken ?? "",
                    size: CGSize(width: size, height: size)
                ) {
                    InitialsAvatar(initials: initials, backgroundColor: avatarColor, size: size)
                }
                .clipShape(Circle())
            } else {
                let _ = print("🔍 [ContactAvatar] No avatar URL for \(contact.fullName), using initials")
                InitialsAvatar(initials: initials, backgroundColor: avatarColor, size: size)
            }
        }
    }

    private var avatarURL: String? {
        return contact.avatarURL
    }

    private var initials: String {
        let first = contact.firstName?.prefix(1) ?? ""
        let last = contact.lastName?.prefix(1) ?? ""
        let result = "\(first)\(last)".uppercased()
        return result.isEmpty ? "?" : result
    }

    private var avatarColor: Color {
        // Use stored avatar color if available, otherwise generate from ID
        if let colorString = contact.avatarColor {
            return Color(hex: colorString)
        }
        return fallbackColorFromId
    }

    private var fallbackColorFromId: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan]
        let index = Int(contact.id) % colors.count
        return colors[index]
    }
}

/// Avatar showing initials with a colored background
struct InitialsAvatar: View {
    let initials: String
    let backgroundColor: Color
    let size: CGFloat

    init(initials: String, backgroundColor: Color = .blue, size: CGFloat = 40) {
        self.initials = initials
        self.backgroundColor = backgroundColor
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
            
            Text(initials)
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

/// For displaying avatars from Contact model (API data)
struct ContactAvatarFromContact: View {
    let contact: Contact
    let size: CGFloat
    @EnvironmentObject var authManager: AuthenticationManager

    init(contact: Contact, size: CGFloat = 40) {
        self.contact = contact
        self.size = size
    }

    var body: some View {
        Group {
            if let avatarURL = contact.avatarURL, let url = URL(string: avatarURL) {
                AuthenticatedAsyncImage(
                    url: url,
                    apiToken: authManager.apiToken ?? "",
                    size: CGSize(width: size, height: size)
                ) {
                    InitialsAvatar(initials: contact.initials, backgroundColor: fallbackColor, size: size)
                }
                .clipShape(Circle())
            } else {
                InitialsAvatar(initials: contact.initials, backgroundColor: fallbackColor, size: size)
            }
        }
    }

    private var fallbackColor: Color {
        if let colorString = contact.avatarColor {
            return Color(hex: colorString)
        }
        return .blue
    }
}

#Preview {
    VStack(spacing: 20) {
        InitialsAvatar(initials: "JD", backgroundColor: .blue, size: 60)
        InitialsAvatar(initials: "AB", backgroundColor: .green, size: 40)
        InitialsAvatar(initials: "XY", backgroundColor: .orange, size: 30)
    }
    .padding()
}