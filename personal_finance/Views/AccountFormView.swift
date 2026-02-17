import SwiftUI
import SwiftData

struct AccountFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Account)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let acc): return "\(acc.persistentModelID.hashValue)"
            }
        }
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: AccountType = .bank
    @State private var icon = "building.columns.fill"
    @State private var colorHex = "#2196F3"
    @State private var initialBalance = ""

    private let colorOptions = [
        "#4CAF50", "#2196F3", "#FF9800", "#E91E63",
        "#9C27B0", "#00BCD4", "#795548", "#607D8B",
        "#F44336", "#FFC107", "#3F51B5", "#8BC34A"
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名稱", text: $name)

                Picker("類型", selection: $type) {
                    ForEach(AccountType.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .onChange(of: type) {
                    icon = type.defaultIcon
                }

                Section("初始餘額") {
                    TextField("0", text: $initialBalance)
                        .keyboardType(.numberPad)
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
            .navigationTitle(isEditing ? "編輯帳戶" : "新增帳戶")
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
                if case .edit(let account) = mode {
                    name = account.name
                    type = account.type
                    icon = account.icon
                    colorHex = account.colorHex
                    initialBalance = "\(account.initialBalance)"
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        let balance = Decimal(string: initialBalance) ?? 0
        switch mode {
        case .add:
            let account = Account(
                name: name,
                type: type,
                icon: type.defaultIcon,
                colorHex: colorHex,
                initialBalance: balance,
                sortOrder: 99
            )
            modelContext.insert(account)
        case .edit(let account):
            account.name = name
            account.type = type
            account.icon = type.defaultIcon
            account.colorHex = colorHex
            account.initialBalance = balance
        }
    }
}
