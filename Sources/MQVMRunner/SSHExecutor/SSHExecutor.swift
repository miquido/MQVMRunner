import Foundation
import NIOCore
import SimpleSSHClient

struct SSHExecutor {
	static var current: SSHExecutor = Self.default

	typealias Host = String
	typealias User = String
	typealias Password = String
	typealias PrivateKeyPath = String
	typealias PrivateKeyPass = String

	private var client: SSHClientProtocol? = nil
	private let getClientUsingPassword: (Host, User, Password) async throws -> SSHClientProtocol
	private let getClientUsingPublicKey: (Host, User, PrivateKeyPath, PrivateKeyPass?) async throws -> SSHClientProtocol
	private let execute: (SSHClientProtocol, String) async throws -> AsyncThrowingStream<CommandOutput, any Error>

	init(
		getClientUsingPassword: @escaping (Host, User, Password) async throws -> SSHClientProtocol,
		getClientUsingPublicKey: @escaping (Host, User, PrivateKeyPath, PrivateKeyPass?) async throws ->
			SSHClientProtocol,
		execute: @escaping (SSHClientProtocol, String) async throws -> AsyncThrowingStream<
			CommandOutput, any Error
		>
	) {
		self.getClientUsingPassword = getClientUsingPassword
		self.getClientUsingPublicKey = getClientUsingPublicKey
		self.execute = execute
	}

	mutating func connect(host: Host, user: User, authentication: VMAuthentication) async throws {
		self.client = try await getClient(host: host, authentication: authentication)
	}

	func execute(command: String) async throws -> AsyncThrowingStream<CommandOutput, any Error> {
		guard let client = self.client else { throw NoConnectedSSHClient.error() }
		return try await execute(client, command)
	}
}

extension SSHExecutor {
	static let `default`: SSHExecutor = Self.init(
		getClientUsingPassword: { (host, user, password) in
			try await SimpleSSHClient.connect(host: host, authentication: .password(username: user, password: password))
		},
		getClientUsingPublicKey: { (host, user, privateKeyPath, privateKeyPass) in
			try await SimpleSSHClient.connect(
				host: host,
				authentication: .privateKey(username: user, privateKeyPath: privateKeyPath, passphrase: privateKeyPass))
		},
		execute: { (client: SSHClientProtocol, command: String) in
			return try await client.execute(command: command, timeout: 30)
		}
	)
}

private extension SSHExecutor {
	func getClient(host: Host, authentication: VMAuthentication) async throws -> SSHClientProtocol {
		switch authentication {
		case .password(let user, let password):
			return try await getClientUsingPassword(host, user, password)
		case .privateKey(let user, let privateKeyPath, let privateKeyPass):
			return try await getClientUsingPublicKey(host, user, privateKeyPath, privateKeyPass)
		case .none:
			throw NoAuthenticationProvided.error()
		}
	}
}
