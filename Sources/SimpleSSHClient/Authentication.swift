import Foundation
import NIO
import NIOSSH

public enum Authentication {
	case password(username: String, password: String)
	case privateKey(username: String, privateKeyPath: String, passphrase: String?)
}

extension Authentication: NIOSSHClientUserAuthenticationDelegate {
	public func nextAuthenticationType(
		availableMethods: NIOSSHAvailableUserAuthenticationMethods,
		nextChallengePromise: EventLoopPromise<NIOSSHUserAuthenticationOffer?>
	) {
		switch self {
		case .password(let username, let password):
			guard availableMethods.contains(.password) else {
				nextChallengePromise.fail(AuthenticationError("Password authentication is not available"))
				return
			}
			let offer = NIOSSHUserAuthenticationOffer.Offer.password(.init(password: password))
			let authenticationOffer = NIOSSHUserAuthenticationOffer(
				username: username, serviceName: .empty, offer: offer)
			nextChallengePromise.succeed(authenticationOffer)
		case .privateKey(let username, let path, let passphrase):
			guard availableMethods.contains(.publicKey) else {
				nextChallengePromise.fail(AuthenticationError("Public key authentication is not available"))
				return
			}
			do {
				let key = try String(contentsOfFile: path)
				let privateKey = try PrivateKeyParser.current.parse(key, passphrase)
				let offer = NIOSSHUserAuthenticationOffer.Offer.privateKey(.init(privateKey: privateKey))
				let authenticationOffer = NIOSSHUserAuthenticationOffer(
					username: username, serviceName: .empty, offer: offer)
				nextChallengePromise.succeed(authenticationOffer)
			} catch {
				nextChallengePromise.fail(error)
			}
		}
	}
}
