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
        "fork.knife", "car.fill", "gamecontroller.fill", "bag.fill",
        "house.fill", "cross.case.fill", "book.fill", "tag.fill",
        "briefcase.fill", "star.fill", "gift.fill", "heart.fill"
    ]

    private let colorOptions = [
        "#FF9800", "#2196F3", "#9C27B0", "#E91E63",
        "#795548", "#F44336", "#3F51B5", "#607D8B",
        "#4CAF50", "#FFC107", "#00BCD4", "#8BC34A"
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
