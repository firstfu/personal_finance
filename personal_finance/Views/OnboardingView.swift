//
//  OnboardingView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            AppTheme.primary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.primaryDark)

                VStack(spacing: 12) {
                    Text("輕鬆記錄\n每日收支")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("直覺的介面，幫助你輕鬆管理個人財務\n掌握收支狀況，達成理財目標")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("開始使用")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
