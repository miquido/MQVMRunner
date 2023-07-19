import Foundation

enum VMAuthentication {
	case password(user: String, password: String)
	case privateKey(user: String, privateKeyPath: String, privateKeyPassword: String?)
	case none
}

protocol VMAuthenticable {
	var user: String { get }
	var passwordAuthorization: String? { get }
	var privateKey: String? { get }
	var privateKeyPassword: String? { get }
}

extension VMAuthenticable {
	var authentication: VMAuthentication {
		if passwordAuthorization != nil && privateKey != nil {
			Logger.warning("🔐", "Both password and private key are provided. Private key will be used.")
		}
		if let privateKey = privateKey {
			return .privateKey(user: user, privateKeyPath: privateKey, privateKeyPassword: privateKeyPassword)
		} else if let passwordAuthorization = passwordAuthorization {
			return .password(user: user, password: passwordAuthorization)
		}

		return .none
	}
}
