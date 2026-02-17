//
//  PeriodNavigationBar.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

struct PeriodNavigationBar: View {
    @Binding var state: TimePeriodState
    @State private var showCustomDatePicker = false

    var body: some View {
        VStack(spacing: 8) {
            Picker("期間", selection: Binding(
                get: { state.periodType },
                set: { state.setPeriodType($0) }
            )) {
                ForEach(PeriodType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)

            if state.periodType == .custom {
                Button {
                    showCustomDatePicker = true
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text(state.periodLabel)
                            .font(.subheadline)
                    }
                    .foregroundStyle(AppTheme.primary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .sheet(isPresented: $showCustomDatePicker) {
                    CustomDateRangePicker(
                        startDate: $state.customStart,
                        endDate: $state.customEnd
                    )
                }
            } else {
                HStack {
                    Button {
                        state.goBack()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.bold())
                            .foregroundStyle(AppTheme.primary)
                            .frame(width: 36, height: 36)
                    }

                    Spacer()

                    Text(state.periodLabel)
                        .font(.subheadline.bold())

                    Spacer()

                    Button {
                        state.goForward()
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.bold())
                            .foregroundStyle(state.isCurrentPeriod ? AppTheme.secondaryText.opacity(0.3) : AppTheme.primary)
                            .frame(width: 36, height: 36)
                    }
                    .disabled(state.isCurrentPeriod)
                }
            }
        }
    }
}

struct CustomDateRangePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("開始日期", selection: $startDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "zh-TW"))
                DatePicker("結束日期", selection: $endDate, displayedComponents: .date)
                    .environment(\.locale, Locale(identifier: "zh-TW"))
            }
            .navigationTitle("自訂日期範圍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        if startDate > endDate {
                            swap(&startDate, &endDate)
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
