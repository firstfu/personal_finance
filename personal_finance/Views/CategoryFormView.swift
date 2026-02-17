// ============================================================================
// MARK: - CategoryFormView.swift
// 模組：Views
//
// 功能說明：
//   分類新增與編輯表單頁面，以 Sheet 形式呈現。
//   提供名稱、類型、圖標與顏色的選擇，支援新增與編輯兩種模式。
//
// 主要職責：
//   - 提供分類名稱輸入欄位
//   - 提供支出/收入類型選擇
//   - 以 6 欄網格顯示 12 個 SF Symbols 圖標供選取
//   - 以 6 欄網格顯示 12 個預設顏色供選取（含勾選指示）
//   - 新增模式：建立新 Category 物件並插入 ModelContext
//   - 編輯模式：載入現有分類資料並就地更新屬性
//
// UI 結構：
//   - Form 表單:
//     - TextField: 分類名稱輸入
//     - Picker: 支出/收入類型選擇
//     - Section「圖標」: LazyVGrid 圖標選擇網格
//     - Section「顏色」: LazyVGrid 顏色選擇網格
//   - Toolbar:
//     - 取消按鈕（cancellationAction）
//     - 儲存按鈕（confirmationAction），名稱為空時禁用
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於插入新分類
//   - @Environment(\.dismiss): 關閉 Sheet
//   - Mode enum: .add（新增）或 .edit(Category)（編輯）
//   - @State name / icon / colorHex / type: 表單狀態
//
// 注意事項：
//   - Mode 遵循 Identifiable 協定以支援 .sheet(item:) 綁定
//   - 編輯模式下 onAppear 時從既有分類載入初始值
//   - 新增模式下 sortOrder 預設為 99（排序至最後）
//   - initialType 參數用於新增時預設交易類型（從 CategoryManagementView 傳入）
// ============================================================================

import SwiftUI
import SwiftData

struct CategoryFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Category)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let cat): return "\(cat.persistentModelID.hashValue)"
            }
        }
    }

    let mode: Mode
    let initialType: TransactionType

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var colorHex = "#607D8B"
    @State private var type: TransactionType = .expense

    init(mode: Mode, initialType: TransactionType = .expense) {
        self.mode = mode
        self.initialType = initialType
    }

    private let iconOptions = [
        // 飲食相關
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "cart.fill", "basket.fill",
        // 交通相關
        "car.fill", "bus.fill", "tram.fill", "airplane", "bicycle", "fuelpump.fill", "parkingsign.circle.fill",
        // 居住 / 水電
        "house.fill", "building.2.fill", "bolt.fill", "drop.fill", "flame.fill", "wrench.fill", "key.fill",
        // 購物 / 服飾
        "bag.fill", "tag.fill", "tshirt.fill", "desktopcomputer",
        // 醫療 / 運動
        "cross.case.fill", "pills.fill", "figure.run", "dumbbell.fill", "heart.fill",
        // 教育 / 工作
        "book.fill", "graduationcap.fill", "briefcase.fill", "hammer.fill", "pencil.and.ruler.fill",
        // 娛樂 / 社交
        "gamecontroller.fill", "film.fill", "music.note", "tv.fill", "person.2.fill", "figure.and.child.holdinghands",
        // 通訊 / 訂閱
        "iphone.gen3", "wifi", "repeat.circle.fill", "antenna.radiowaves.left.and.right",
        // 金融 / 保險
        "creditcard.fill", "banknote.fill", "chart.line.uptrend.xyaxis", "chart.bar.fill", "shield.fill", "percent",
        // 寵物 / 自然
        "pawprint.fill", "leaf.fill", "sun.max.fill", "cloud.rain.fill",
        // 美容 / 生活
        "sparkles", "scissors", "paintbrush.fill", "camera.fill",
        // 情感 / 其他
        "gift.fill", "star.fill", "trophy.fill", "flag.fill", "mappin.and.ellipse",
        "bell.fill", "lightbulb.fill", "doc.text.fill", "doc.plaintext.fill",
        "hands.sparkles.fill", "arrow.uturn.backward.circle.fill",
        "wallet.bifold.fill", "ellipsis.circle.fill",
    ]

    private let colorOptions = [
        // 紅色系
        "#F44336", "#E91E63", "#FF5252", "#D32F2F",
        // 粉紫系
        "#9C27B0", "#AB47BC", "#7E57C2", "#5C6BC0",
        // 藍色系
        "#3F51B5", "#2196F3", "#1565C0", "#42A5F5", "#29B6F6",
        // 青綠系
        "#00BCD4", "#26C6DA", "#26A69A", "#009688",
        // 綠色系
        "#4CAF50", "#66BB6A", "#8BC34A", "#AED581", "#43A047",
        // 黃橙系
        "#FFC107", "#FFCA28", "#FFD600", "#FF9800", "#FFB74D", "#FF7043", "#FF8A65",
        // 棕灰系
        "#795548", "#8D6E63", "#6D4C41", "#A1887F",
        "#607D8B", "#78909C", "#90A4AE", "#546E7A", "#455A64", "#37474F", "#757575",
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名稱", text: $name)

                Picker("類型", selection: $type) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }

                Section("圖標") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(icon == ic ? Color(hex: colorHex).opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("顏色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "編輯分類" : "新增分類")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let category) = mode {
                    name = category.name
                    icon = category.icon
                    colorHex = category.colorHex
                    type = category.type
                } else {
                    type = initialType
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        switch mode {
        case .add:
            let category = Category(
                name: name,
                icon: icon,
                colorHex: colorHex,
                type: type,
                sortOrder: 99
            )
            modelContext.insert(category)
        case .edit(let category):
            category.name = name
            category.icon = icon
            category.colorHex = colorHex
            category.type = type
        }
    }
}
