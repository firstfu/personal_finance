// ============================================================================
// MARK: - CategoryFormView.swift
// 模組：Views
//
// 功能說明：
//   分類新增與編輯表單頁面，以 Sheet 形式呈現。
//   提供名稱、類型、圖標與顏色的選擇，支援新增與編輯兩種模式。
//   圖標與顏色使用固定高度的可捲動網格，避免頁面過長。
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
            VStack(spacing: 0) {
                // MARK: - 預覽區
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: colorHex).opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: icon)
                            .font(.title)
                            .foregroundStyle(Color(hex: colorHex))
                    }
                    Text(name.isEmpty ? "分類名稱" : name)
                        .font(.subheadline)
                        .foregroundStyle(name.isEmpty ? AppTheme.secondaryText : AppTheme.onBackground)
                }
                .padding(.top, 16)
                .padding(.bottom, 12)

                // MARK: - 名稱與類型
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("名稱", text: $name)
                            .textFieldStyle(.roundedBorder)

                        Picker("", selection: $type) {
                            Text("支出").tag(TransactionType.expense)
                            Text("收入").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // MARK: - 圖標與顏色選擇（Tab 切換）
                TabView {
                    // 圖標 Tab
                    iconGridView
                        .tabItem {
                            Image(systemName: "square.grid.2x2")
                            Text("圖標")
                        }

                    // 顏色 Tab
                    colorGridView
                        .tabItem {
                            Image(systemName: "paintpalette")
                            Text("顏色")
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

    // MARK: - 圖標網格
    private var iconGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                ForEach(iconOptions, id: \.self) { ic in
                    Button {
                        icon = ic
                    } label: {
                        Image(systemName: ic)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(icon == ic ? Color(hex: colorHex).opacity(0.2) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(icon == ic ? Color(hex: colorHex) : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - 顏色網格
    private var colorGridView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(colorOptions, id: \.self) { hex in
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 36, height: 36)
                            .overlay {
                                if colorHex == hex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(colorHex == hex ? Color(hex: hex) : Color.clear, lineWidth: 2)
                                    .padding(-3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
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
