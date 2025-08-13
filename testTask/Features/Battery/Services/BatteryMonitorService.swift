//
//  BatteryMonitorService.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation
import UIKit
import Combine

@MainActor
final class BatteryMonitorService: BatteryMonitorServiceProtocol, ObservableObject {
	@Published private(set) var currentBatteryLevel: Float = 0 // [0,1]
	@Published private(set) var isMonitoring: Bool = false

	private let dataQueueManager: DataQueueManagerProtocol
	private var timer: Timer?

	init(dataQueueManager: DataQueueManagerProtocol) {
		self.dataQueueManager = dataQueueManager
		UIDevice.current.isBatteryMonitoringEnabled = true

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(batteryLevelDidChange),
			name: UIDevice.batteryLevelDidChangeNotification,
			object: nil
		)

		startTimer()
		updateBatteryLevel()
	}

	func startTimer() {
		guard timer == nil else { return }
		let t = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
			Task { @MainActor in self?.updateBatteryLevel() }
		}
		t.tolerance = 12
		timer = t
		isMonitoring = true
	}

	func stopTimer() {
		timer?.invalidate()
		timer = nil
		isMonitoring = false
	}

	@discardableResult
	func collectBatteryData() -> BatteryData? {
		let level = currentBatteryLevel
		let id = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
		let item = BatteryData(batteryLevel: level, deviceId: id)
		dataQueueManager.enqueue(item)
		return item
	}

	@objc private func batteryLevelDidChange() { updateBatteryLevel() }

	private func updateBatteryLevel() {
		var level = UIDevice.current.batteryLevel
		#if targetEnvironment(simulator)
		if level < 0 { level = 0.66 }
		#endif
		currentBatteryLevel = max(0, min(1, level))
	}
}
