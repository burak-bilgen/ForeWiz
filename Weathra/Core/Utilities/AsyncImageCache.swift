import SwiftUI
import Combine

@MainActor
final class AsyncImageCache: ObservableObject {
    static let shared = AsyncImageCache()

    private var cache: [URL: Image] = [:]
    private var loadingTasks: [URL: Task<Image, Error>] = [:]

    private init() {}

    func image(for url: URL) async throws -> Image {
        if let cached = cache[url] {
            return cached
        }

        if let task = loadingTasks[url] {
            return try await task.value
        }

        let task = Task<Image, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else {
                throw URLError(.badURL)
            }
            let image = Image(uiImage: uiImage)
            cache[url] = image
            loadingTasks.removeValue(forKey: url)
            return image
        }

        loadingTasks[url] = task
        return try await task.value
    }

    func clearCache() {
        cache.removeAll()
        loadingTasks.removeAll()
    }
}

struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: Image

    @StateObject private var cache = AsyncImageCache.shared

    @State private var image: Image?
    @State private var isLoading = false

    var body: some View {
        Group {
            if let image = image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                placeholder
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(isLoading ? 0.5 : 1.0)
                    .overlay {
                        if isLoading {
                            ProgressView()
                        }
                    }
            }
        }
        .task {
            await loadImage()
        }
    }

    private func loadImage() async {
        guard let url = url else { return }
        isLoading = true
        do {
            image = try await cache.image(for: url)
        } catch {
            // Keep placeholder on error
        }
        isLoading = false
    }
}
