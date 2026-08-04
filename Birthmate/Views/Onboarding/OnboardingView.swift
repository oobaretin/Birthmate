import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var notificationManager: NotificationManager
    @StateObject private var previewModel = OnboardingPreviewModel()
    @State private var selectedMonth: Int = 1
    @State private var selectedDay: Int = 1

    private let months = Calendar.current.monthSymbols
    private var daysInMonth: Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2024
        components.month = selectedMonth
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }

    private var selectedDateLabel: String {
        DateFormatting.birthdate(month: selectedMonth, day: selectedDay)
    }

    var body: some View {
        ZStack {
            BirthmateTheme.onboardingGradient
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 8)

                VStack(spacing: 12) {
                    AppLogoView(size: 112, cornerRadius: 24)

                    Text("Birthmate")
                        .font(.largeTitle.bold())

                    Text("Choose your birth month and day to discover who shares it and what happened in history on your day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text("No birth year needed — just month and day.")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(BirthmateTheme.accent.opacity(0.85))
                }

                VStack(spacing: 12) {
                    Text(selectedDateLabel)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(BirthmateTheme.accent)
                        .animation(.easeInOut(duration: 0.2), value: selectedDateLabel)

                    HStack(spacing: 0) {
                        datePickerColumn(title: "Month") {
                            Picker("Month", selection: $selectedMonth) {
                                ForEach(1...12, id: \.self) { month in
                                    Text(months[month - 1]).tag(month)
                                }
                            }
                            .pickerStyle(.wheel)
                        }

                        Divider()
                            .padding(.vertical, 12)

                        datePickerColumn(title: "Day") {
                            Picker("Day", selection: $selectedDay) {
                                ForEach(1...daysInMonth, id: \.self) { day in
                                    Text("\(day)").tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                        }
                    }
                    .frame(height: 148)
                    .onChange(of: selectedMonth) { _, _ in
                        if selectedDay > daysInMonth { selectedDay = daysInMonth }
                        previewModel.load(month: selectedMonth, day: selectedDay)
                    }
                    .onChange(of: selectedDay) { _, _ in
                        previewModel.load(month: selectedMonth, day: selectedDay)
                    }

                    OnboardingPreviewCard(
                        dateLabel: selectedDateLabel,
                        sampleName: previewModel.sampleName,
                        birthCount: previewModel.birthCount,
                        sampleEvent: previewModel.sampleEvent,
                        isLoading: previewModel.isLoading
                    )
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)

                Spacer(minLength: 8)

                Button {
                    birthdateStore.save(month: selectedMonth, day: selectedDay)
                    if notificationManager.isEnabled {
                        Task {
                            await notificationManager.scheduleDailyReminder(
                                month: selectedMonth,
                                day: selectedDay
                            )
                        }
                    }
                } label: {
                    Text("Discover my day")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BirthmateTheme.accent.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            applyInitialSelection()
            previewModel.load(month: selectedMonth, day: selectedDay)
        }
        .onDisappear {
            previewModel.cancel()
        }
    }

    private func datePickerColumn<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
            content()
        }
        .frame(maxWidth: .infinity)
    }

    private func applyInitialSelection() {
        if birthdateStore.hasBirthdate,
           let month = birthdateStore.month,
           let day = birthdateStore.day {
            selectedMonth = month
            selectedDay = day
            return
        }

        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        selectedMonth = today.month ?? 1
        selectedDay = today.day ?? 1
    }
}

#Preview {
    OnboardingView()
        .environmentObject(BirthdateStore())
        .environmentObject(NotificationManager())
}
