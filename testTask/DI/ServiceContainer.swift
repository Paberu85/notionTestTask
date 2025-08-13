//
//  ServiceContainer.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Foundation

// Контейнер для dependency injection
final class ServiceContainer: BatteryModule {
	let cryptoService: CryptoServiceProtocol
	let dataQueueManager: DataQueueManagerProtocol
	let networkService: NetworkServiceProtocol
	let dataCollector: DataCollectorProtocol
	let backgroundTaskManager: BackgroundTaskManagerProtocol
	let batteryMonitorService: BatteryMonitorService

	@MainActor
	init() {
		self.cryptoService = CryptoService()
		self.dataQueueManager = DataQueueManager()
		self.networkService = NetworkService(cryptoService: cryptoService)
		self.dataCollector = DataCollector(dataQueue: dataQueueManager, network: networkService)
		self.backgroundTaskManager = BackgroundTaskManager(dataCollector: dataCollector)
		self.batteryMonitorService = BatteryMonitorService(dataQueueManager: dataQueueManager)
	}

	var monitor: BatteryMonitorService { batteryMonitorService }
	var dataQueue: DataQueueManagerProtocol { dataQueueManager }

	// Методи для керування Significant Location Changes
	func startSLC() { backgroundTaskManager.startSignificantLocationChanges() }
	func stopSLC() { backgroundTaskManager.stopSignificantLocationChanges() }
}
