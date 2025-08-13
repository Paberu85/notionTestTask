//
//  BatteryData.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import UIKit

struct BatteryData: Codable, Sendable {
	let timestamp: Date
	let batteryLevel: Float
	let deviceId: String

	init(
		batteryLevel: Float,
		timestamp: Date = .init(),
		deviceId: String = "unknown"
	) {
		self.timestamp = timestamp
		self.batteryLevel = batteryLevel
		self.deviceId = deviceId
	}
}

struct DataPushRecord: Identifiable, Codable, Sendable {
	let id: UUID
	let timestamp: Date
	let dataCount: Int
	let success: Bool

	init(
		timestamp: Date = .init(),
		dataCount: Int = 0,
		success: Bool = false,
		id: UUID = .init()
	) {
		self.id = id
		self.timestamp = timestamp
		self.dataCount = dataCount
		self.success = success
	}
}
