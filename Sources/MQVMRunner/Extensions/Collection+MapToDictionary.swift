import Foundation

extension Collection {
	@inlinable internal func map<K, V>(_ transform: (Element) throws -> (K, V)) rethrows -> [K: V] {
		try reduce([K: V]()) { partialResult, element in
			var dict = partialResult
			let mapped = try transform(element)
			dict[mapped.0] = mapped.1
			return dict
		}
	}

	@inlinable internal func compactMap<K, V>(_ transform: (Element) throws -> (K, V)?) rethrows -> [K: V] {
		try reduce([K: V]()) { partialResult, element in
			var dict = partialResult
			if let mapped = try transform(element) {
				dict[mapped.0] = mapped.1
			}
			return dict
		}
	}
}
