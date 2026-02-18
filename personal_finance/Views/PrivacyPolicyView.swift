import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("最後更新日期：2026 年 2 月 19 日")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    sectionBlock(
                        title: "一、概述",
                        content: "「個人記帳」（以下簡稱「本應用程式」）非常重視您的隱私。本隱私權政策說明我們如何收集、使用及保護您的個人資訊。"
                    )

                    sectionBlock(
                        title: "二、資料收集與儲存",
                        content: "本應用程式所有資料（包括交易紀錄、帳戶資訊、分類等）均儲存於您的裝置本機及您的個人 iCloud 帳號中。我們不會將您的資料上傳至任何第三方伺服器。"
                    )

                    sectionBlock(
                        title: "三、iCloud 同步",
                        content: "若您啟用 iCloud 同步功能，資料將透過 Apple 的 CloudKit 服務在您的裝置間同步。此同步受 Apple 隱私權政策的保護。"
                    )

                    sectionBlock(
                        title: "四、第三方服務",
                        content: "本應用程式不使用任何第三方分析工具、廣告服務或追蹤技術。我們不會與任何第三方分享您的資料。"
                    )
                }

                Group {
                    sectionBlock(
                        title: "五、資料安全",
                        content: "您的資料受裝置本機安全機制及 Apple iCloud 加密保護。我們建議您開啟裝置密碼鎖定與 Face ID / Touch ID 以加強安全性。"
                    )

                    sectionBlock(
                        title: "六、資料刪除",
                        content: "您可以隨時透過設定頁面的「重設所有資料」功能刪除所有應用程式資料。刪除後的資料無法復原。"
                    )

                    sectionBlock(
                        title: "七、兒童隱私",
                        content: "本應用程式不針對 13 歲以下兒童設計，亦不會刻意收集兒童的個人資訊。"
                    )

                    sectionBlock(
                        title: "八、政策變更",
                        content: "我們可能會不定期更新本隱私權政策。更新後的政策將於應用程式內公佈，繼續使用本應用程式即表示您同意更新後的政策。"
                    )

                    sectionBlock(
                        title: "九、聯絡我們",
                        content: "如對本隱私權政策有任何疑問，請透過 App Store 頁面的開發者聯絡方式與我們聯繫。"
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("隱私權政策")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionBlock(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}
