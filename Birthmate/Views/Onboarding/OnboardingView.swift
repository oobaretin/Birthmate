import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var notificationManager: NotificationManager
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

    var body: some View {
        ZStack {
            BirthmateTheme.onboardingGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 16) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: BirthmateTheme.accent.opacity(0.25), radius: 12, y: 6)

                    Text("Birthmate")
                        .font(.largeTitle.bold())

                    Text("Enter your birth month and day to see who shares it with you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Picker("Month", selection: $selectedMonth) {
                            ForEach(1...12, id: \.self) { month in
                                Text(months[month - 1]).tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)

                        Picker("Day", selection: $selectedDay) {
                            ForEach(1...daysInMonth, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                    }
                    .frame(height: 180)
                    .onChange(of: selectedMonth) { _, _ in
                        if selectedDay > daysInMonth { selectedDay = daysInMonth }
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 24)

                Spacer()

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
                    Text("Continue")
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
    }
}

#Preview {
    OnboardingView()
        .environmentObject(BirthdateStore())
        .environmentObject(NotificationManager())
}
