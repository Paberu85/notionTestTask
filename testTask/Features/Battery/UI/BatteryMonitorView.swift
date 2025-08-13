//
//  BatteryMonitorView.swift
//  testTask
//
//  Created by Pavlo Buievych on 12.08.2025.
//
import SwiftUI

struct BatteryMonitorView<C: BatteryModule>: View {
	@StateObject private var viewModel: BatteryMonitorViewModel<C>
	@EnvironmentObject var appState: AppState
	@State private var isPushing = false

	private let container: C

	init(container: C) {
		self.container = container
		_viewModel = StateObject(wrappedValue: BatteryMonitorViewModel(container: container))
	}

	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 20) {
					// Стан батареї
					batteryStatusCard

					// Стан черги з тумблером SLC
					queueStatusCard

					// Ручна відправка
					manualPushButton

					// Історія відправок
					pushHistorySection
				}
				.padding()
			}
			.navigationTitle("Battery Monitor")
			.refreshable {
				viewModel.loadData()
			}
		}
		.onChange(of: appState.useLocationWakeups) { _, useSLC in
			// Керуємо SLC для додаткового пробудження
			useSLC ? container.startSLC() : container.stopSLC()
		}
	}

	private var batteryStatusCard: some View {
		VStack(spacing: 12) {
			HStack {
				Image(systemName: "battery.100")
					.font(.title2)
					.foregroundColor(batteryColor)
				Text("Стан батареї")
					.font(.headline)
				Spacer()
			}

			HStack {
				Text("Поточний рівень:")
					.foregroundColor(.secondary)
				Spacer()
				Text("\(Int(viewModel.currentBatteryLevel * 100))%")
					.font(.system(.title2, design: .rounded))
					.fontWeight(.bold)
			}

			ProgressView(value: viewModel.currentBatteryLevel)
				.tint(batteryColor)
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}

	private var queueStatusCard: some View {
		VStack(spacing: 12) {
			HStack {
				Image(systemName: "tray.full")
					.font(.title2)
					.foregroundColor(.blue)
				Text("Стан черги")
					.font(.headline)
				Spacer()
			}

			HStack {
				Text("Записів у черзі:")
					.foregroundColor(.secondary)
				Spacer()
				Text("\(viewModel.queuedDataCount)")
					.font(.system(.title3, design: .rounded))
					.fontWeight(.semibold)
			}

			HStack {
				Text("Моніторинг:")
					.foregroundColor(.secondary)
				Spacer()
				Text(viewModel.isMonitoring ? "Активний" : "Неактивний")
					.foregroundColor(viewModel.isMonitoring ? .green : .red)
					.fontWeight(.medium)
			}

			// Тумблер для альтернативного пробудження через локацію (significant location change)
			HStack {
				VStack(alignment: .leading, spacing: 2) {
					Text("Пробудження через локацію")
						.foregroundColor(.primary)
						.font(.footnote)
					Text("(SLC - резервний механізм)")
						.foregroundColor(.secondary)
						.font(.caption)
				}
				Spacer()
				Toggle("", isOn: $appState.useLocationWakeups)
					.labelsHidden()
					.tint(.green)
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}

	private var manualPushButton: some View {
		let isDisabled = isPushing || viewModel.queuedDataCount == 0

		return Button(action: {
			guard !isPushing else { return }
			Task { @MainActor in
				isPushing = true
				await viewModel.manualPush()
				isPushing = false
			}
		}) {
			HStack {
				if isPushing {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle())
						.scaleEffect(0.8)
				} else {
					Image(systemName: "icloud.and.arrow.up")
				}
				Text("Відправити зараз")
					.fontWeight(.semibold)
			}
			.frame(maxWidth: .infinity)
			.padding()
			.background(isDisabled ? Color.gray.opacity(0.35) : Color.blue)
			.foregroundColor(.white)
			.cornerRadius(10)
			.opacity(isDisabled ? 0.7 : 1.0)
			.animation(.default, value: isDisabled)
		}
		.disabled(isPushing)
	}

	private var pushHistorySection: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Image(systemName: "clock.arrow.circlepath")
					.font(.title2)
					.foregroundColor(.orange)
				Text("Історія відправок")
					.font(.headline)
				Spacer()
			}

			if viewModel.pushRecords.isEmpty {
				Text("Ще немає спроб відправки")
					.foregroundColor(.secondary)
					.frame(maxWidth: .infinity, alignment: .center)
					.padding(.vertical, 20)
			} else {
				ForEach(viewModel.pushRecords.prefix(10)) { record in
					pushRecordRow(record)
				}
			}
		}
		.padding()
		.background(Color(.systemBackground))
		.cornerRadius(12)
		.shadow(radius: 2)
	}

	private func pushRecordRow(_ record: DataPushRecord) -> some View {
		HStack {
			Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
				.foregroundColor(record.success ? .green : .red)

			VStack(alignment: .leading, spacing: 2) {
				Text(formatDate(record.timestamp))
					.font(.footnote)
					.foregroundColor(.primary)
				Text("\(record.dataCount) записів")
					.font(.caption)
					.foregroundColor(.secondary)
			}

			Spacer()

			Text(record.success ? "Успішно" : "Помилка")
				.font(.caption)
				.fontWeight(.medium)
				.foregroundColor(record.success ? .green : .red)
		}
		.padding(.vertical, 4)
	}

	private var batteryColor: Color {
		switch viewModel.currentBatteryLevel {
		case 0.5...1.0: return .green
		case 0.2...0.5: return .orange
		default: return .red
		}
	}

	private func formatDate(_ date: Date) -> String {
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .medium
		return formatter.string(from: date)
	}
}
