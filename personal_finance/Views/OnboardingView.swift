//
//  OnboardingView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var titleOffset: CGFloat = 30
    @State private var titleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 20
    @State private var subtitleOpacity: Double = 0
    @State private var decorOpacity: Double = 0

    var body: some View {
        ZStack {
            // 漸層背景
            LinearGradient(
                colors: [
                    Color(hex: "#1B5E20"),
                    Color(hex: "#2E7D32"),
                    Color(hex: "#43A047"),
                    Color(hex: "#66BB6A"),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 裝飾圓圈
            decorCircles

            // 主內容
            VStack(spacing: 0) {
                Spacer()

                // Logo 區
                ZStack {
                    // 光暈效果
                    Circle()
                        .fill(.white.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)

                    Circle()
                        .fill(.white.opacity(0.08))
                        .frame(width: 120, height: 120)

                    Image(systemName: "leaf.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                Spacer().frame(height: 40)

                // 標題
                VStack(spacing: 16) {
                    Text("記帳小幫手")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

                    Text("輕鬆記錄每日收支\n掌握你的財務生活")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)

                Spacer().frame(height: 32)

                // 功能亮點
                VStack(spacing: 14) {
                    featureRow(icon: "chart.pie.fill", text: "收支一目了然")
                    featureRow(icon: "leaf.fill", text: "養成記帳好習慣")
                    featureRow(icon: "lock.shield.fill", text: "資料安全不外洩")
                }
                .offset(y: subtitleOffset)
                .opacity(subtitleOpacity)

                Spacer()
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            startAnimations()
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
        .padding(.horizontal, 8)
    }

    private var decorCircles: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 300, height: 300)
                .offset(x: -120, y: -280)

            Circle()
                .fill(.white.opacity(0.03))
                .frame(width: 250, height: 250)
                .offset(x: 150, y: -200)

            Circle()
                .fill(.white.opacity(0.04))
                .frame(width: 200, height: 200)
                .offset(x: 130, y: 320)

            Circle()
                .fill(.white.opacity(0.03))
                .frame(width: 180, height: 180)
                .offset(x: -140, y: 280)
        }
        .opacity(decorOpacity)
    }

    private func startAnimations() {
        // Logo 彈出
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 裝飾圓圈淡入
        withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
            decorOpacity = 1.0
        }

        // 標題滑入
        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            titleOffset = 0
            titleOpacity = 1.0
        }

        // 功能亮點滑入
        withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
            subtitleOffset = 0
            subtitleOpacity = 1.0
        }

        // 自動跳轉到首頁
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.4)) {
                hasCompletedOnboarding = true
            }
        }
    }
}
