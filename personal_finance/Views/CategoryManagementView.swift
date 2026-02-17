// ============================================================================
// MARK: - CategoryManagementView.swift
// 模組：Views
//
// 功能說明：
//   分類管理頁面，以網格方式顯示分類，支援新增、編輯與刪除。
// ============================================================================

import SwiftUI
import SwiftData
import WidgetKit

struct CategoryManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedType: TransactionType = .expense
    @State private var showAddCategory = false
    @State private var editingCategory: Category?
    @State private var categoryToDelete: Category?

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 類型切換
            Picker("類型", selection: $selectedType) {
                Text("支出").tag(TransactionType.expense)
                Text("收入").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 12)

            // MARK: - 分類網格
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredCategories) { category in
                        CategoryGridItem(category: category)
                            .onTapGesture {
                                editingCategory = category
                            }
                            .onLongPressGesture {
                                if !category.isDefault {
                                    categoryToDelete = category
                                }
                            }
                    }

                    // 新增按鈕
                    Button {
                        showAddCategory = true
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray5))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Text("新增")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("分類管理")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                showAddCategory = true
            } label: {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showAddCategory) {
            CategoryFormView(mode: .add, initialType: selectedType)
        }
        .sheet(item: $editingCategory) { category in
            CategoryFormView(mode: .edit(category))
        }
        .alert("刪除分類", isPresented: Binding(
            get: { categoryToDelete != nil },
            set: { if !$0 { categoryToDelete = nil } }
        )) {
            Button("取消", role: .cancel) {
                categoryToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let category = categoryToDelete {
                    modelContext.delete(category)
                    WidgetDataSync.updateSnapshot(from: modelContext)
                    categoryToDelete = nil
                }
            }
        } message: {
            Text("確定要刪除「\(categoryToDelete?.name ?? "")」嗎？")
        }
    }
}

// MARK: - 分類網格項目
private struct CategoryGridItem: View {
    let category: Category

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: category.colorHex))
            }
            Text(category.name)
                .font(.caption)
                .foregroundStyle(AppTheme.onBackground)
                .lineLimit(1)
        }
    }
}
