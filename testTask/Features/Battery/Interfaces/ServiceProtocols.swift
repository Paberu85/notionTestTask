//
//  CryptoServiceProtocol.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation
import UIKit

// Протоколи для dependency injection та тестування
protocol CryptoServiceProtocol: AnyObject, Sendable {
	func encrypt(_ data: Data) -> Data?
	func decrypt(_ data: Data) -> Data?
}

protocol DataQueueManagerProtocol: AnyObject, Sendable {
	func enqueue(_ data: BatteryData)
	func getQueue() -> [BatteryData]
	func clearQueue()
	func savePushRecord(_ record: DataPushRecord)
	func getPushRecords() -> [DataPushRecord]
}

protocol NetworkServiceProtocol: AnyObject, Sendable {
	func send(payload: [BatteryData]) async -> Bool
}

@MainActor
protocol BatteryMonitorServiceProtocol: AnyObject {
	var currentBatteryLevel: Float { get }
	var isMonitoring: Bool { get }
	@discardableResult
	func collectBatteryData() -> BatteryData?
	func startTimer()
	func stopTimer()
}

protocol DataCollectorProtocol: AnyObject, Sendable {
	func collectAndSendData() async -> Bool
	func collectAndSendData(completion: @escaping @Sendable (Bool) -> Void)
}

protocol BackgroundTaskManagerProtocol: AnyObject, Sendable {
	func registerBackgroundTasks()
	func scheduleBackgroundTask()
	func handleSilentPush(completion: @escaping (UIBackgroundFetchResult) -> Void)
	func startSignificantLocationChanges()
	func stopSignificantLocationChanges()
}
