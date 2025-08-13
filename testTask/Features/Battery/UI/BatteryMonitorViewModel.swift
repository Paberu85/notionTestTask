//
//  BatteryMonitorViewModel.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation
import Combine

@MainActor
final class BatteryMonitorViewModel<C: BatteryModule>: ObservableObject {
	@Published var currentBatteryLevel: Float = 0
	@Published var queuedDataCount: Int = 0
	@Published var isMonitoring: Bool = false
	@Published var pushRecords: [DataPushRecord] = []

	private let container: C
	private var cancellable: AnyCancellable?

	init(container: C) {
		self.container = container

		// Початкові значення
		currentBatteryLevel = container.monitor.currentBatteryLevel
		isMonitoring = container.monitor.isMonitoring
		queuedDataCount = container.dataQueue.getQueue().count
		pushRecords = container.dataQueue.getPushRecords()

		// Підписка на зміни батареї
		cancellable = container.monitor.objectWillChange.sink { [weak self] _ in
			guard let self else { return }
			Task { @MainActor in
				self.currentBatteryLevel = self.container.monitor.currentBatteryLevel
				self.isMonitoring = self.container.monitor.isMonitoring
			}
		}
	}

	func loadData() {
		// Оновлюємо дані з сервісів
		queuedDataCount = container.dataQueue.getQueue().count
		pushRecords = container.dataQueue.getPushRecords()
	}

	func manualPush() async {
		// Ручна відправка накопичених даних
		_ = await container.dataCollector.collectAndSendData()
		loadData()
	}
}
