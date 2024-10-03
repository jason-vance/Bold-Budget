//
//  Cache.swift
//  Bold Budget
//
//  Created by Jason Vance on 10/1/24.
//

import Foundation

final class Cache<Key: Hashable, Value> {
    
    var entryLifetime: TimeInterval = .greatestFiniteMagnitude
    var maximumEntryCount: Int {
        get { wrapped.countLimit }
        set { wrapped.countLimit = newValue }
    }
    
    var keys: Set<Key> { keyTracker.keys }
    var values: [Value] { keyTracker.keys.compactMap { key in value(forKey: key)} }
    
    private let wrapped = NSCache<WrappedKey, Entry>()
    private let keyTracker = KeyTracker()
    
    init() {
        wrapped.delegate = keyTracker
    }
    
    func removeAll() {
        wrapped.removeAllObjects()
        keyTracker.keys.removeAll()
    }

    func insert(_ value: Value, forKey key: Key, dateProvider: @escaping () -> Date = Date.init) {
        let date = dateProvider().addingTimeInterval(entryLifetime)
        let entry = Entry(key: key, value: value, expirationDate: date)
        wrapped.setObject(entry, forKey: WrappedKey(key))
        keyTracker.keys.insert(key)
    }

    func value(forKey key: Key) -> Value? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard Date() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }

        return entry.value
    }

    func removeValue(forKey key: Key) {
        wrapped.removeObject(forKey: WrappedKey(key))
    }
}

private extension Cache {
    func entry(forKey key: Key) -> Entry? {
        guard let entry = wrapped.object(forKey: WrappedKey(key)) else {
            return nil
        }

        guard Date() < entry.expirationDate else {
            removeValue(forKey: key)
            return nil
        }

        return entry
    }

    func insert(_ entry: Entry) {
        wrapped.setObject(entry, forKey: WrappedKey(entry.key))
        keyTracker.keys.insert(entry.key)
    }
}


extension Cache {
    subscript(key: Key) -> Value? {
        get { return value(forKey: key) }
        set {
            guard let value = newValue else {
                // If nil was assigned using our subscript,
                // then we remove any value for that key:
                removeValue(forKey: key)
                return
            }

            insert(value, forKey: key)
        }
    }
}

private extension Cache {
    final class WrappedKey: NSObject {
        let key: Key

        init(_ key: Key) { self.key = key }

        override var hash: Int { return key.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            guard let value = object as? WrappedKey else {
                return false
            }

            return value.key == key
        }
    }
}

private extension Cache {
    final class Entry {
        let key: Key
        let value: Value
        let expirationDate: Date

        init(key: Key, value: Value, expirationDate: Date) {
            self.key = key
            self.value = value
            self.expirationDate = expirationDate
        }
    }
}

private extension Cache {
    final class KeyTracker: NSObject, NSCacheDelegate {
        var keys = Set<Key>()

        func cache(_ cache: NSCache<AnyObject, AnyObject>,
                   willEvictObject object: Any) {
            guard let entry = object as? Entry else {
                return
            }

            keys.remove(entry.key)
        }
    }
}

extension Cache.Entry: Codable where Key: Codable, Value: Codable {}

extension Cache: Codable where Key: Codable, Value: Codable {
    convenience init(from decoder: Decoder) throws {
        self.init()

        let container = try decoder.singleValueContainer()
        let entries = try container.decode([Entry].self)
        entries.forEach(insert)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(keyTracker.keys.compactMap(entry))
    }
}

private extension Cache {
    static func fileUrl(
        withFileName name: String,
        using fileManager: FileManager = .default
    ) -> URL {
        let folderURLs = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )

        var url = folderURLs[0].appendingPathComponent(name + ".cache")
        
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? url.setResourceValues(values)

        return url
    }
}

extension Cache where Key: Codable, Value: Codable {
    
    func saveToDisk(
        withName name: String,
        using fileManager: FileManager = .default
    ) throws {
        let fileUrl = Self.fileUrl(withFileName: name, using: fileManager)
        let data = try JSONEncoder().encode(self)
        try data.write(to: fileUrl)
        print("Cache: Saved to disk\n - Location: \(fileUrl.absoluteString)\n - With \(keys.count) entries")
    }
    
    static func readFromDisk<TypedCache>(
        _ typedCache: TypedCache.Type,
        withName name: String,
        using fileManager: FileManager = .default
    ) throws -> TypedCache where TypedCache: Cache {
        let fileUrl = fileUrl(withFileName: name, using: fileManager)
        let data = try Data.init(contentsOf: fileUrl)
        return try JSONDecoder().decode(TypedCache.self, from: data)
    }
    
    static func readFromDiskOrDefault<TypedCache>(
        _ typedCache: TypedCache.Type,
        withName name: String,
        using fileManager: FileManager = .default
    ) -> TypedCache where TypedCache: Cache {
        if let cache = try? readFromDisk(TypedCache.self, withName: name) {
            print("Cache: Found `\(name)` cache on disk with \(cache.keys.count) entries")
            return cache
        }
        
        print("Cache: Instantiating new cache `\(name)`")
        return TypedCache()
    }
}
