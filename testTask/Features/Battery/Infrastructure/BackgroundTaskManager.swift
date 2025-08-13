//
//  BackgroundTaskManager.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import UIKit
@preconcurrency import BackgroundTasks
import CoreLocation

final class BackgroundTaskManager: NSObject, BackgroundTaskManagerProtocol, @unchecked Sendable {
	private let backgroundTaskIdentifier = "com.app.batteryMonitor"
	private let locationManager = CLLocationManager()
	private let dataCollector: DataCollectorProtocol
	private var pendingFetchCompletion: ((UIBackgroundFetchResult) -> Void)?

	init(dataCollector: DataCollectorProtocol) {
		self.dataCollector = dataCollector
		super.init()
	}

	func registerBackgroundTasks() {
		BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
			self.handleRefresh(task: task as! BGAppRefreshTask)
		}
	}

	// на рівні операційної системи BGAppRefresh можливий не частіше ніж раз на 15хв
	func scheduleBackgroundTask() {
		let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
		request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
		do { try BGTaskScheduler.shared.submit(request) }
		catch { print("BGAppRefresh schedule error: \(error)") }
	}

	private func handleRefresh(task: BGAppRefreshTask) {
		task.expirationHandler = {
			task.setTaskCompleted(success: false)
		}

		dataCollector.collectAndSendData { [weak self] success in
			task.setTaskCompleted(success: success)
			self?.scheduleBackgroundTask()
		}
	}

	func handleSilentPush(completion: @escaping (UIBackgroundFetchResult) -> Void) {
		pendingFetchCompletion = completion

		dataCollector.collectAndSendData { [weak self] ok in
			guard let self else { return }
			DispatchQueue.main.async {
				self.pendingFetchCompletion?(ok ? .newData : .failed)
				self.pendingFetchCompletion = nil
				self.scheduleBackgroundTask()
			}
		}
	}

	func startSignificantLocationChanges() {
		locationManager.delegate = self
		locationManager.requestAlwaysAuthorization()
		locationManager.startMonitoringSignificantLocationChanges()
	}

	func stopSignificantLocationChanges() {
		locationManager.stopMonitoringSignificantLocationChanges()
	}
}

extension BackgroundTaskManager: CLLocationManagerDelegate {
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		dataCollector.collectAndSendData { _ in /* no-op */ }
	}
}
