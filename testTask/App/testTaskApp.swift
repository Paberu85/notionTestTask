//
//  testTaskApp.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import SwiftUI
import BackgroundTasks
import UserNotifications

/*
iOS запускає фонові оновлення через BGAppRefresh не частіше ніж раз на ~15 хвилин і не гарантує точний інтервал або виконання у
заданий час (це залежить від стану мережі, заряду, режиму Low Power, налаштувань “Background App Refresh” тощо).
Тому для більш стабільного збору даних модуль додатково використовує альтернативні механізми пробудження:
Silent Push (content-available=1): бекенд може “розштовхнути” застосунок без показу сповіщення.
Significant Location Change (SLC): опційно, за згодою користувача, iOS будить застосунок при суттєвій зміні локації.
Використані шаблонні підходи і архітектура, варіація MVVM, dependecy injection, etc.
Код для демонстрації загальної концепції підходу до вирішення поставленої проблеми.
 */

@main
struct TestTaskApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	@Environment(\.scenePhase) private var scenePhase
	@StateObject private var appState = AppState()

	private let serviceContainer = ServiceContainer()

	init() {
		appDelegate.backgroundTaskManager = serviceContainer.backgroundTaskManager
	}

	var body: some Scene {
		WindowGroup {
			BatteryMonitorView(container: serviceContainer)
				.environmentObject(appState)
				.onAppear {
					appState.bindServices(container: serviceContainer)
				}
				.onChange(of: scenePhase) { _, newPhase in
					handleScenePhaseChange(newPhase: newPhase)
				}
				.onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
					// Збираємо дані при активації додатку
					_ = serviceContainer.batteryMonitorService.collectBatteryData()
					serviceContainer.backgroundTaskManager.scheduleBackgroundTask()
				}
		}
	}

	private func handleScenePhaseChange(newPhase: ScenePhase) {
		switch newPhase {
		case .active:
			// Активний стан - запускаємо таймер
			serviceContainer.batteryMonitorService.startTimer()
			_ = serviceContainer.batteryMonitorService.collectBatteryData()
			serviceContainer.backgroundTaskManager.scheduleBackgroundTask()

		case .background:
			// Фоновий режим - зупиняємо таймер та використовуємо background task
			serviceContainer.batteryMonitorService.stopTimer()
			beginBackgroundTaskAndFlush()
			serviceContainer.backgroundTaskManager.scheduleBackgroundTask()

		case .inactive:
			break
		@unknown default:
			break
		}
	}

	@MainActor
	private func beginBackgroundTaskAndFlush() {
		let taskID = UIApplication.shared.beginBackgroundTask(withName: "flush-queue") {}
		Task {
			_ = await serviceContainer.dataCollector.collectAndSendData()
			await MainActor.run {
				UIApplication.shared.endBackgroundTask(taskID)
			}
		}
	}
}
