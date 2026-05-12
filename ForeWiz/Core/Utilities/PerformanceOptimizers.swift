import Foundation
import SwiftUI
import OSLog

#if DEBUG

final class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    private let logger = AppLogger.performance

    private var operationStarts: [String: CFAbsoluteTime] = [:]
    private let queue = DispatchQueue(label: "com.forewiz.performance", qos: .utility)

    private init() {}

    func startOperation(_ name: String) {
        queue.async {
            self.operationStarts[name] = CFAbsoluteTimeGetCurrent()
            self.logger.debug("Started operation: \(name)")
        }
    }

    func endOperation(_ name: String) {
        queue.async {
            guard let startTime = self.operationStarts[name] else {
                self.logger.warning("Attempted to end operation '\(name)' that was never started")
                return
            }

            let duration = CFAbsoluteTimeGetCurrent() - startTime
            self.operationStarts.removeValue(forKey: name)

            let durationMs = duration * 1000
            self.logger.info("Operation '\(name)' completed in \(String(format: "%.2f", durationMs))ms")

            if duration > 1.0 {
                self.logger.warning("Slow operation detected: '\(name)' took \(String(format: "%.2f", durationMs))ms")
            }
        }
    }

    func measure<T>(operation name: String, _ block: () throws -> T) rethrows -> T {
        startOperation(name)
        defer { endOperation(name) }
        return try block()
    }

    func measureAsync<T>(operation name: String, _ block: () async throws -> T) async rethrows -> T {
        startOperation(name)
        defer { endOperation(name) }
        return try await block()
    }

    func reportMemoryUsage(context: String = "") {
        let contextStr = context.isEmpty ? "" : " [\(context)]"
        logger.info("Memory usage check requested\(contextStr)")
    }
}

@propertyWrapper
struct Cached<T: Codable & Sendable> {
    private let key: String
    private let cache: UserDefaults
    private let expirationInterval: TimeInterval?

    var wrappedValue: T? {
        get {
            guard let data = cache.object(forKey: key) as? Data else { return nil }

            if let expirationInterval = expirationInterval,
               let timestamp = cache.object(forKey: "\(key)_timestamp") as? Date {
                if Date().timeIntervalSince(timestamp) > expirationInterval {
                    cache.removeObject(forKey: key)
                    cache.removeObject(forKey: "\(key)_timestamp")
                    AppLogger.cache.info("Cache expired for key: \(key)")
                    return nil
                }
            }

            do {
                let value = try JSONDecoder().decode(T.self, from: data)
                return value
            } catch {
                AppLogger.cache.error("Failed to decode cached value for key \(key): \(error.localizedDescription)")
                return nil
            }
        }
        nonmutating set {
            if let newValue = newValue {
                do {
                    let data = try JSONEncoder().encode(newValue)
                    cache.set(data, forKey: key)
                    if expirationInterval != nil {
                        cache.set(Date(), forKey: "\(key)_timestamp")
                    }
                    AppLogger.cache.debug("Cached value for key: \(key)")
                } catch {
                    AppLogger.cache.error("Failed to encode value for key \(key): \(error.localizedDescription)")
                }
            } else {
                cache.removeObject(forKey: key)
                cache.removeObject(forKey: "\(key)_timestamp")
                AppLogger.cache.debug("Cleared cache for key: \(key)")
            }
        }
    }

    init(
        _ key: String,
        expirationInterval: TimeInterval? = nil,
        suiteName: String? = nil
    ) {
        self.key = key
        self.expirationInterval = expirationInterval
        if let suiteName = suiteName {
            self.cache = UserDefaults(suiteName: suiteName) ?? .standard
        } else {
            self.cache = .standard
        }
    }

    func invalidate() {
        cache.removeObject(forKey: key)
        cache.removeObject(forKey: "\(key)_timestamp")
        AppLogger.cache.debug("Invalidated cache for key: \(key)")
    }
}

final class MemoryCache<Key: Hashable & Sendable, Value: Sendable>: @unchecked Sendable {
    private let cache = NSCache<WrappedKey<Key>, Entry<Value>>()
    private let lock = NSLock()

    init(countLimit: Int = 100, totalCostLimit: Int = 50 * 1024 * 1024) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        return cache.object(forKey: WrappedKey(key))?.value
    }

    func set(_ value: Value, forKey key: Key, cost: Int = 0) {
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(Entry(value: value), forKey: WrappedKey(key), cost: cost)
        AppLogger.cache.debug("Memory cache set for key type: \(String(describing: Key.self))")
    }

    func remove(_ key: Key) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: WrappedKey(key))
    }

    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
        AppLogger.cache.info("Memory cache cleared")
    }

    private final class WrappedKey<T: Hashable>: NSObject {
        let value: T

        init(_ value: T) {
            self.value = value
        }

        override var hash: Int {
            value.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey<T> else { return false }
            return value == other.value
        }
    }

    private final class Entry<T> {
        let value: T

        init(value: T) {
            self.value = value
        }
    }
}

final class DiskCache {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let queue = DispatchQueue(label: "com.forewiz.diskcache", qos: .utility)

    init(subdirectory: String = "Cache") {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = urls[0].appendingPathComponent(subdirectory, isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func save<T: Codable>(_ value: T, forKey key: String) async {
        await queue.async {
            let url = self.cacheDirectory.appendingPathComponent(key)
            do {
                let data = try JSONEncoder().encode(value)
                try data.write(to: url)
                AppLogger.cache.debug("Disk cache saved: \(key)")
            } catch {
                AppLogger.cache.error("Failed to save to disk cache '\(key)': \(error.localizedDescription)")
            }
        }
    }

    func load<T: Codable>(forKey key: String, as type: T.Type) async -> T? {
        await queue.async {
            let url = self.cacheDirectory.appendingPathComponent(key)
            guard self.fileManager.fileExists(atPath: url.path) else { return nil }

            do {
                let data = try Data(contentsOf: url)
                let value = try JSONDecoder().decode(T.self, from: data)
                AppLogger.cache.debug("Disk cache loaded: \(key)")
                return value
            } catch {
                AppLogger.cache.error("Failed to load from disk cache '\(key)': \(error.localizedDescription)")
                return nil
            }
        }
    }

    func remove(forKey key: String) async {
        await queue.async {
            let url = self.cacheDirectory.appendingPathComponent(key)
            try? self.fileManager.removeItem(at: url)
            AppLogger.cache.debug("Disk cache removed: \(key)")
        }
    }

    func clear() async {
        await queue.async {
            let contents = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents ?? [] {
                try? self.fileManager.removeItem(at: url)
            }
            AppLogger.cache.info("Disk cache cleared")
        }
    }

    func size() async -> UInt64 {
        await queue.async {
            let contents = try? self.fileManager.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            var totalSize: UInt64 = 0
            for url in contents ?? [] {
                if let attributes = try? self.fileManager.attributesOfItem(atPath: url.path),
                   let size = attributes[.size] as? UInt64 {
                    totalSize += size
                }
            }
            return totalSize
        }
    }
}

extension DispatchQueue {
    func async<T>(operation: @escaping () -> T) async -> T {
        await withCheckedContinuation { continuation in
            self.async {
                continuation.resume(returning: operation())
            }
        }
    }
}

@propertyWrapper
struct LazyLoad<T> {
    private var value: T?
    private let loader: () -> T

    var wrappedValue: T {
        mutating get {
            if let value = value {
                return value
            }
            let newValue = loader()
            self.value = newValue
            return newValue
        }
        mutating set {
            value = newValue
        }
    }

    init(_ loader: @escaping () -> T) {
        self.loader = loader
    }
}

@propertyWrapper
struct Throttled<Value> {
    private var value: Value
    private let interval: TimeInterval
    private var lastUpdate: Date = .distantPast

    var wrappedValue: Value {
        get { value }
        mutating set {
            let now = Date()
            if now.timeIntervalSince(lastUpdate) >= interval {
                value = newValue
                lastUpdate = now
            }
        }
    }

    init(wrappedValue: Value, interval: TimeInterval) {
        self.value = wrappedValue
        self.interval = interval
    }
}

@propertyWrapper
final class Debounced<Value> {
    private var value: Value
    private let interval: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue = DispatchQueue.main

    var wrappedValue: Value {
        get { value }
        set {
            workItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.value = newValue
            }
            queue.asyncAfter(deadline: .now() + interval, execute: workItem)
        }
    }

    init(wrappedValue: Value, interval: TimeInterval) {
        self.value = wrappedValue
        self.interval = interval
    }
}

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let diskCache: DiskCache
    private let queue = DispatchQueue(label: "com.forewiz.imagecache", qos: .utility)

    private init() {
        cache.countLimit = 100
        cache.totalCostLimit = 50 * 1024 * 1024
        diskCache = DiskCache(subdirectory: "ImageCache")
    }

    func image(forKey key: String) -> UIImage? {
        if let cachedImage = cache.object(forKey: key as NSString) {
            AppLogger.cache.debug("Memory image cache hit: \(key)")
            return cachedImage
        }
        return nil
    }

    func setImage(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
        AppLogger.cache.debug("Memory image cache set: \(key)")
    }

    func clearMemoryCache() {
        cache.removeAllObjects()
        AppLogger.cache.info("Memory image cache cleared")
    }

    func clearDiskCache() async {
        await diskCache.clear()
    }
}

struct AsyncImageLoader: ViewModifier {
    let url: URL?
    let placeholder: AnyView
    @State private var image: UIImage?
    @State private var isLoading = false

    func body(content: Content) -> some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else { return }
        let key = url.absoluteString

        if let cachedImage = ImageCache.shared.image(forKey: key) {
            self.image = cachedImage
            return
        }

        isLoading = true
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    ImageCache.shared.setImage(loadedImage, forKey: key)
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                AppLogger.cache.error("Failed to load image: \(error.localizedDescription)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

extension View {
    func asyncImage(url: URL?, placeholder: @escaping () -> some View) -> some View {
        modifier(AsyncImageLoader(url: url, placeholder: AnyView(placeholder())))
    }
}

struct TaskLimiter {
    private var task: Task<Void, Never>?
    private let lock = NSLock()

    mutating func execute(_ operation: @escaping () async -> Void) {
        lock.lock()
        task?.cancel()
        task = Task {
            await operation()
        }
        lock.unlock()
    }

    mutating func cancel() {
        lock.lock()
        task?.cancel()
        task = nil
        lock.unlock()
    }
}

final class RateLimiter {
    private let interval: TimeInterval
    private var lastExecution: Date = .distantPast
    private let lock = NSLock()

    init(interval: TimeInterval) {
        self.interval = interval
    }

    func execute(_ operation: () -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        if now.timeIntervalSince(lastExecution) >= interval {
            lastExecution = now
            operation()
            return true
        }
        return false
    }

    func executeAsync(_ operation: @escaping () async -> Void) async -> Bool {
        guard markExecutionIfAllowed() else { return false }
        await operation()
        return true
    }

    private func markExecutionIfAllowed() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        let now = Date()
        guard now.timeIntervalSince(lastExecution) >= interval else { return false }

        lastExecution = now
        return true
    }
}

actor RequestDeduper<Key: Hashable> {
    private var inFlightRequests: [Key: Task<Any, Error>] = [:]

    func deduplicate<T>(key: Key, operation: @escaping () async throws -> T) async throws -> T {
        if let existingTask = inFlightRequests[key] {
            AppLogger.performance.debug("Deduplicating request for key: \(String(describing: key))")
            if let value = try await existingTask.value as? T {
                return value
            }
        }

        let task = Task<Any, Error> {
            defer {
                Task {
                    await self.removeRequest(forKey: key)
                }
            }
            return try await operation()
        }

        inFlightRequests[key] = task

        if let value = try await task.value as? T {
            return value
        }
        throw AppError.invalidData
    }

    private func removeRequest(forKey key: Key) async {
        inFlightRequests.removeValue(forKey: key)
    }

    func cancel(key: Key) {
        inFlightRequests[key]?.cancel()
        inFlightRequests.removeValue(forKey: key)
    }
}

protocol Batchable {
    associatedtype BatchKey: Hashable
    var batchKey: BatchKey { get }
}

final class Batcher<Key: Hashable, Value>: @unchecked Sendable {
    private let interval: TimeInterval
    private let processor: ([Key]) async -> [Key: Value]
    private var pending: Set<Key> = []
    private var inFlight: [Key: Task<Value, Error>] = [:]
    private let lock = NSLock()

    init(interval: TimeInterval, processor: @escaping ([Key]) async -> [Key: Value]) {
        self.interval = interval
        self.processor = processor
    }

    func request(_ key: Key) async throws -> Value {
        if let task = task(for: key) {
            return try await task.value
        }

        let task = Task<Value, Error> { [weak self] in
            guard let self else { throw AppError.unknown }

            defer {
                self.removeTask(for: key)
            }

            try await Task.sleep(nanoseconds: UInt64(self.interval * 1_000_000_000))

            let batch = self.takePendingBatch()
            let results = await self.processor(batch)
            guard let value = results[key] else {
                throw AppError.unknown
            }
            return value
        }

        store(task, for: key)
        return try await task.value
    }

    private func task(for key: Key) -> Task<Value, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return inFlight[key]
    }

    private func store(_ task: Task<Value, Error>, for key: Key) {
        lock.lock()
        pending.insert(key)
        inFlight[key] = task
        lock.unlock()
    }

    private func removeTask(for key: Key) {
        lock.lock()
        inFlight.removeValue(forKey: key)
        lock.unlock()
    }

    private func takePendingBatch() -> [Key] {
        lock.lock()
        defer { lock.unlock() }
        let batch = Array(pending)
        pending.removeAll()
        return batch
    }
}

struct PrefetchCache<Key: Hashable & Sendable> {
    private let cache = NSCache<WrappedKey<Key>, NSNumber>()

    func prefetch(_ keys: [Key]) {
        for key in keys {
            cache.setObject(NSNumber(value: true), forKey: WrappedKey(key))
        }
    }

    func isPrefetched(_ key: Key) -> Bool {
        cache.object(forKey: WrappedKey(key)) != nil
    }

    func clear() {
        cache.removeAllObjects()
    }

    private final class WrappedKey<T: Hashable>: NSObject {
        let value: T

        init(_ value: T) {
            self.value = value
        }

        override var hash: Int {
            value.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? WrappedKey<T> else { return false }
            return value == other.value
        }
    }
}

final class MemoryPressureHandler {
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryPressure),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc private func handleMemoryPressure() {
        AppLogger.performance.warning("Memory pressure detected, clearing caches")
        handler()
    }
}

#endif
