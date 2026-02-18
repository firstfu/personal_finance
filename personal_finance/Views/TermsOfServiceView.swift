import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("最後更新日期：2026 年 2 月 19 日")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)

                    sectionBlock(
                        title: "一、接受條款",
                        content: "下載、安裝或使用「個人記帳」（以下簡稱「本應用程式」）即表示您同意遵守以下使用條款。若您不同意，請勿使用本應用程式。"
                    )

                    sectionBlock(
                        title: "二、服務說明",
                        content: "本應用程式為個人財務記帳工具，協助您記錄日常收支、管理帳戶及分類。本應用程式僅供個人使用，不構成任何財務建議。"
                    )

                    sectionBlock(
                        title: "三、使用者責任",
                        content: "您應負責確保輸入資料的準確性。本應用程式不對因資料錯誤而造成的任何損失負責。請定期備份您的資料以避免意外遺失。"
                    )

                    sectionBlock(
                        title: "四、智慧財產權",
                        content: "本應用程式的所有內容，包括但不限於設計、程式碼、圖示及文字，均受智慧財產權法保護。未經授權不得複製、修改或散佈。"
                    )
                }

                Group {
                    sectionBlock(
                        title: "五、免責聲明",
                        content: "本應用程式以「現況」提供，不提供任何明示或默示的保證。開發者不對任何直接、間接、偶然或衍生的損害承擔責任。"
                    )

                    sectionBlock(
                        title: "六、服務變更",
                        content: "我們保留隨時修改、暫停或終止本應用程式（或其任何部分）的權利，恕不另行通知。"
                    )

                    sectionBlock(
                        title: "七、條款變更",
                        content: "我們可能會不定期更新本使用條款。更新後的條款將於應用程式內公佈，繼續使用本應用程式即表示您同意更新後的條款。"
                    )

                    sectionBlock(
                        title: "八、適用法律",
                        content: "本使用條款受中華民國法律管轄。因本條款引起的任何爭議，雙方同意以臺灣臺北地方法院為第一審管轄法院。"
                    )

                    sectionBlock(
                        title: "九、聯絡我們",
                        content: "如對本使用條款有任何疑問，請透過 App Store 頁面的開發者聯絡方式與我們聯繫。"
                    )
                }
            }
            .padding()
        }
        .background(AppTheme.background)
        .navigationTitle("使用條款")
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
