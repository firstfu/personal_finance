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
