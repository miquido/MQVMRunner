import Foundation
import NIO
import NIOSSH

struct AcceptingAllHostValidator: NIOSSHClientServerAuthenticationDelegate {
	func validateHostKey(hostKey: NIOSSHPublicKey, validationCompletePromise: EventLoopPromise<Void>) {
		validationCompletePromise.succeed(())
	}
}
