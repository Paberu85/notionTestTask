//
//  AppDelegate.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import UIKit
import BackgroundTasks

final class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {
	var backgroundTaskManager: BackgroundTaskManagerProtocol?

	func application(_ application: UIApplication,
					 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		backgroundTaskManager?.registerBackgroundTasks()
		UIApplication.shared.registerForRemoteNotifications()
		return true
	}

	func application(_ application: UIApplication,
					 didReceiveRemoteNotification userInfo: [AnyHashable : Any],
					 fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		backgroundTaskManager?.handleSilentPush(completion: completionHandler)
	}
}
