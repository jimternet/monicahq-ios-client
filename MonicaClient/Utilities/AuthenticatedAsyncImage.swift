//
//  AuthenticatedAsyncImage.swift
//  MonicaClient
//
//  Enhanced for 001-003-avatar-authentication feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI
import Combine

// MARK: - Authenticated Image Loading

/// Loads images that require authentication by adding Bearer token to requests
/// Enhanced with caching and Gravatar detection
class AuthenticatedImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = false
    @Published var error: Error?

    private let url: URL
    private let apiToken: String
    private var cancellable: AnyCancellable?
    private static let cache = NSCache<NSURL, UIImage>()

    static func configureCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
    }

    init(url: URL, apiToken: String) {
        self.url = url
        self.apiToken = apiToken
    }

    func load() {
        guard !isLoading else { return }

        // Check cache first
        if let cachedImage = Self.cache.object(forKey: url as NSURL) {
            print("🖼️ [Avatar] Cache hit for: \(url.absoluteString)")
            self.image = cachedImage
            return
        }

        print("🖼️ [Avatar] Loading image from: \(url.absoluteString)")
        isLoading = true
        error = nil

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        request.timeoutInterval = 30

        // Add Bearer token only for non-Gravatar sources
        let needsAuth = shouldAuthenticate(url: url)
        print("🖼️ [Avatar] Needs authentication: \(needsAuth) for host: \(url.host ?? "unknown")")
        if needsAuth {
            request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        }

        cancellable = URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> UIImage in
                // Check HTTP status
                if let httpResponse = response as? HTTPURLResponse {
                    print("🖼️ [Avatar] HTTP \(httpResponse.statusCode) for: \(self.url.absoluteString)")
                    if !(200...299).contains(httpResponse.statusCode) {
                        print("❌ [Avatar] Failed with status \(httpResponse.statusCode)")
                        throw URLError(.badServerResponse)
                    }
                }

                guard let image = UIImage(data: data) else {
                    print("❌ [Avatar] Failed to decode image data (\(data.count) bytes)")
                    throw URLError(.cannotDecodeContentData)
                }

                print("✅ [Avatar] Successfully loaded image (\(data.count) bytes)")
                // Cache the image
                Self.cache.setObject(image, forKey: self.url as NSURL, cost: data.count)
                return image
            }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.isLoading = false
                if image == nil {
                    print("❌ [Avatar] Load failed for: \(self?.url.absoluteString ?? "unknown")")
                }
                self?.image = image
            }
    }

    /// Determine if URL requires authentication
    private func shouldAuthenticate(url: URL) -> Bool {
        guard let host = url.host else { return false }

        // Don't authenticate external services
        if host.contains("gravatar.com") || host.contains("adorable.io") {
            return false
        }

        // Authenticate for all other sources (Monica server)
        return true
    }

    func cancel() {
        cancellable?.cancel()
        isLoading = false
    }

    static func clearCache() {
        cache.removeAllObjects()
        URLCache.shared.removeAllCachedResponses()
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
