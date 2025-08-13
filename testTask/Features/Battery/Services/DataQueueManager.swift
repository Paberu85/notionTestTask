//
//  DataQueueManager.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation

final class DataQueueManager: DataQueueManagerProtocol, @unchecked Sendable {
	private let queueKey = "BatteryDataQueue"
	private let pushRecordsKey = "DataPushRecords"
	private let maxRecords = 50 // Обмежуємо історію
	private let userDefaults = UserDefaults.standard
	private let queue = DispatchQueue(label: "io.testTask.queueManager")

	func enqueue(_ data: BatteryData) {
		queue.sync {
			var currentQueue = getQueueInternal()
			currentQueue.append(data)

			// Обмежуємо розмір черги
			if currentQueue.count > 100 {
				currentQueue = Array(currentQueue.suffix(100))
			}

			saveQueueInternal(currentQueue)
		}
	}

	func getQueue() -> [BatteryData] {
		queue.sync { getQueueInternal() }
	}

	func clearQueue() {
		queue.sync {
			userDefaults.removeObject(forKey: queueKey)
		}
	}

	func savePushRecord(_ record: DataPushRecord) {
		queue.sync {
			var records = getPushRecordsInternal()
			records.insert(record, at: 0)

			// Зберігаємо тільки останні записи
			records = Array(records.prefix(maxRecords))

			if let data = try? JSONEncoder().encode(records) {
				userDefaults.set(data, forKey: pushRecordsKey)
			}
		}
	}

	func getPushRecords() -> [DataPushRecord] {
		queue.sync { getPushRecordsInternal() }
	}

	private func getQueueInternal() -> [BatteryData] {
		guard let data = userDefaults.data(forKey: queueKey),
			  let queue = try? JSONDecoder().decode([BatteryData].self, from: data) else {
			return []
		}
		return queue
	}

	private func saveQueueInternal(_ queue: [BatteryData]) {
		if let data = try? JSONEncoder().encode(queue) {
			userDefaults.set(data, forKey: queueKey)
		}
	}

	private func getPushRecordsInternal() -> [DataPushRecord] {
		guard let data = userDefaults.data(forKey: pushRecordsKey),
			  let records = try? JSONDecoder().decode([DataPushRecord].self, from: data) else {
			return []
		}
		return records
	}
}
