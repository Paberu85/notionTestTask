//
//  DataCollectorProtocol.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation

final class DataCollector: DataCollectorProtocol, @unchecked Sendable {
	private let dataQueue: DataQueueManagerProtocol
	private let network: NetworkServiceProtocol

	init(dataQueue: DataQueueManagerProtocol, network: NetworkServiceProtocol) {
		self.dataQueue = dataQueue
		self.network = network
	}

	// Async версія для SwiftUI
	func collectAndSendData() async -> Bool {
		let queue = dataQueue.getQueue()
		guard !queue.isEmpty else { return true }

		let success = await network.send(payload: queue)

		// Зберігаємо запис про спробу
		let record = DataPushRecord(
			timestamp: Date(),
			dataCount: queue.count,
			success: success
		)
		dataQueue.savePushRecord(record)

		// Очищаємо чергу при успіху
		if success {
			dataQueue.clearQueue()
		}

		return success
	}

	// Completion версія для background tasks
	func collectAndSendData(completion: @escaping @Sendable (Bool) -> Void) {
		Task {
			let success = await collectAndSendData()
			await MainActor.run {
				completion(success)
			}
		}
	}
}
