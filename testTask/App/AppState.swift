//
//  AppState.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//

import UIKit
import Combine

@MainActor
final class AppState: ObservableObject {
	@Published var useLocationWakeups = false {
		didSet {
			// Вмикаємо/вимикаємо SLC для додаткового пробудження
			guard let container else { return }
			if useLocationWakeups {
				container.startSLC()
			} else {
				container.stopSLC()
			}
		}
	}

	private weak var container: ServiceContainer?

	func bindServices(container: ServiceContainer) {
		self.container = container
	}
}
