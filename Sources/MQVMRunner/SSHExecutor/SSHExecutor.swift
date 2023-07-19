import Citadel
import Foundation
import NIOCore

struct SSHExecutor {
	static var current: SSHExecutor = Self.default

	typealias Host = String
	typealias User = String
	typealias Password = String
	typealias PrivateKeyPath = String
	typealias PrivateKeyPass = String
	typealias Input = String
	typealias Output = String

	private var client: SSHClientProtocol? = nil
	private let getClientUsingPassword: (Host, User, Password) async throws -> SSHClientProtocol
	private let getClientUsingPublicKey: (Host, User, PrivateKeyPath, PrivateKeyPass?) async throws -> SSHClientProtocol
	private let execute: (SSHClientProtocol, String) async throws -> AsyncThrowingStream<ExecCommandOutput, any Error>
	private let transfer: (SSHClientProtocol, Input, Output) async throws -> Void

	init(
		getClientUsingPassword: @escaping (Host, User, Password) async throws -> SSHClientProtocol,
		getClientUsingPublicKey: @escaping (Host, User, PrivateKeyPath, PrivateKeyPass?) async throws ->
			SSHClientProtocol,
		execute: @escaping (SSHClientProtocol, String) async throws -> AsyncThrowingStream<
			ExecCommandOutput, any Error
		>,
		transfer: @escaping (SSHClientProtocol, Input, Output) async throws -> Void
	) {
		self.getClientUsingPassword = getClientUsingPassword
		self.getClientUsingPublicKey = getClientUsingPublicKey
		self.execute = execute
		self.transfer = transfer
	}

	mutating func connect(host: Host, user: User, authentication: VMAuthentication) async throws {
		self.client = try await getClient(host: host, authentication: authentication)
	}

	@discardableResult
	func execute(command: String) async throws -> AsyncThrowingStream<ExecCommandOutput, any Error> {
		guard let client = self.client else { throw NoConnectedSSHClient.error() }
		return try await execute(client, command)
	}

	func transfer(input: String, output: String) async throws {
		guard let client = self.client else { throw NoConnectedSSHClient.error() }
		try await transfer(client, input, output)
	}
}

extension SSHExecutor {
	static let `default`: SSHExecutor = Self.init(
		getClientUsingPassword: { (host, user, password) in
			return try await SSHClient.connect(
				host: host,
				authenticationMethod: .passwordBased(username: user, password: password),
				hostKeyValidator: .acceptAnything(),
				reconnect: .always
			)
		},
		getClientUsingPublicKey: { (host, user, privateKeyPath, privateKeyPass) in
			let filePath = NSString(string: privateKeyPath).expandingTildeInPath.filePathURL
			let sshRSA = try Data(contentsOf: filePath)

			return try await SSHClient.connect(
				host: host,
				authenticationMethod: .rsa(
					username: user, privateKey: .init(sshRsa: sshRSA, decryptionKey: privateKeyPass?.data(.utf8))),
				hostKeyValidator: .acceptAnything(),
				reconnect: .always
			)
		},
		execute: { (client: SSHClientProtocol, command: String) in
			return try await client.execute(command: command)
		},
		transfer: { (client: SSHClientProtocol, input, output) in
			let sftp = try await client.sftpClient()
			let inputFileUrl = input.filePathURL

			let inputData = try Data(contentsOf: inputFileUrl)
			try await sftp.write(data: inputData, at: output)
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
