import Foundation
import SwiftUI
import Combine

/// Loads images that require authentication by adding Bearer token to requests
class AuthenticatedImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?

    private let url: URL
    private let apiToken: String
    private var cancellable: AnyCancellable?

    init(url: URL, apiToken: String) {
        self.url = url
        self.apiToken = apiToken
    }

    func load() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")

        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .map { UIImage(data: $0.data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.isLoading = false
                self?.image = image
            }
    }

    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }
}

/// SwiftUI view for displaying authenticated images
struct AuthenticatedAsyncImage: View {
    @StateObject private var loader: AuthenticatedImageLoader
    let size: CGSize
    let placeholder: AnyView

    init(url: URL, apiToken: String, size: CGSize, @ViewBuilder placeholder: @escaping () -> some View) {
        _loader = StateObject(wrappedValue: AuthenticatedImageLoader(url: url, apiToken: apiToken))
        self.size = size
        self.placeholder = AnyView(placeholder())
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
            } else {
                placeholder
                    .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            loader.load()
        }
        .onDisappear {
            loader.cancel()
        }
    }
}
