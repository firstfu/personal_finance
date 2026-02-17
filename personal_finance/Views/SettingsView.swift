//
//  SettingsView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showAddCategory = false
    @State private var editingCategory: Category?

    var body: some View {
        NavigationStack {
            List {
                Section("支出分類") {
                    ForEach(categories.filter { $0.type == .expense }) { category in
                        categoryRow(category)
                    }
                    .onDelete { offsets in
                        deleteCategories(offsets: offsets, type: .expense)
                    }
                }

                Section("收入分類") {
                    ForEach(categories.filter { $0.type == .income }) { category in
                        categoryRow(category)
                    }
                    .onDelete { offsets in
                        deleteCategories(offsets: offsets, type: .income)
                    }
                }

                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddCategory) {
                CategoryFormView(mode: .add)
            }
            .sheet(item: $editingCategory) { category in
                CategoryFormView(mode: .edit(category))
            }
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        Button {
            editingCategory = category
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
                Text(category.name)
                    .foregroundStyle(AppTheme.onBackground)
                Spacer()
                if category.isDefault {
                    Text("預設")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func deleteCategories(offsets: IndexSet, type: TransactionType) {
        let filtered = categories.filter { $0.type == type }
        for index in offsets {
            let category = filtered[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
    }
}

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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var colorHex = "#607D8B"
    @State private var type: TransactionType = .expense

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
