//
//  NetworkService.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation

final class NetworkService: NetworkServiceProtocol, @unchecked Sendable {
	private let cryptoService: CryptoServiceProtocol
	private let serverURL = "https://jsonplaceholder.typicode.com/posts"
	private let urlSession: URLSession

	init(cryptoService: CryptoServiceProtocol) {
		self.cryptoService = cryptoService

		let config = URLSessionConfiguration.default
		config.waitsForConnectivity = true
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 20
		self.urlSession = URLSession(configuration: config)
	}

	func send(payload: [BatteryData]) async -> Bool {
		guard let url = URL(string: serverURL) else { return false }

		guard let jsonData = try? JSONEncoder().encode(payload),
			  let encryptedData = cryptoService.encrypt(jsonData),
			  let base64String = String(data: encryptedData, encoding: .utf8) else {
			return false
		}

		let body: [String: Any] = [
			"timestamp": ISO8601DateFormatter().string(from: Date()),
			"count": payload.count,
			"data": base64String
		]

		guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
			return false
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = httpBody

		do {
			let (_, response) = try await urlSession.data(for: request)

			if let httpResponse = response as? HTTPURLResponse {
				return (200..<300).contains(httpResponse.statusCode)
			}
			return false
		} catch {
			print("Мережева помилка: \(error.localizedDescription)")
			return false
		}
	}
}
