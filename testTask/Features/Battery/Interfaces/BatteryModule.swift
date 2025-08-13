//
//  BatteryModule.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import Combine

// Контейнер лише з тим, що реально потрібно цьому екрану.
protocol BatteryModule {
	associatedtype Monitor: ObservableObject & BatteryMonitorServiceProtocol
	var monitor: Monitor { get }                       // UI-спостережуваний сервіс
	var dataCollector: DataCollectorProtocol { get }  // для "Send now"
	var dataQueue: DataQueueManagerProtocol { get }   // історія надсилань

	// Опційні «будильники» (можуть бути no-op у мок-контейнері)
	func startSLC()
	func stopSLC()
}
