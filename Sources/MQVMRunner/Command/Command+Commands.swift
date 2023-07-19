import Foundation

extension Command {
	internal enum Tart {
		case run(image: String, options: [Option] = [])
		case stop(image: String)
		case delete(image: String)
		case clone(original: String, cloned: String)

		internal enum Option {
			case netBridged(interface: String)
			case mount(directory: String, to: String, readonly: Bool = false)

			internal var value: String {
				switch self {
				case .netBridged(let interface):
					return "--net-bridged=\"\(interface)\""
				case .mount(let directory, let to, let readonly):
					return "--dir=\(to):\(directory)" + (readonly ? ":ro" : "")
				}
			}
		}
	}

	internal static func tart(_ tart: String, _ command: Tart) -> Self {
		switch command {
		case .run(let image, let options):
			return .init(tart, ["run", image] + options.map(\.value))
		case .stop(let image):
			return .init(tart, "stop", image)
		case .delete(let image):
			return .init(tart, "delete", image)
		case .clone(let original, let cloned):
			return .init(tart, "clone", original, cloned)
		}
	}
}
