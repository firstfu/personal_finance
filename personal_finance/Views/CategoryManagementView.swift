// ============================================================================
// MARK: - CategoryManagementView.swift
// 模組：Views
//
// 功能說明：
//   分類管理頁面，提供使用者檢視、新增、編輯與刪除交易分類的功能。
//   支援依支出/收入類型篩選顯示分類列表。
//
// 主要職責：
//   - 依交易類型（支出/收入）篩選並顯示分類列表
//   - 列出分類的圖示、名稱與預設標記
//   - 支援滑動刪除分類（預設分類不可刪除）
//   - 導航至 CategoryFormView 進行新增或編輯分類
//   - 刪除後同步 Widget 資料快照
//
// UI 結構：
//   - Picker（Segmented）: 支出/收入類型切換
//   - ForEach 分類列表: 每列顯示圓形色塊圖示、分類名稱、預設標籤
//   - Toolbar「+」按鈕: 開啟新增分類表單
//   - Sheet: CategoryFormView（新增/編輯模式）
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於刪除分類
//   - @Query categories: 全部分類，依 sortOrder 排序
//   - @State selectedType: 當前篩選的交易類型
//   - @State showAddCategory: 控制新增分類 Sheet
//   - @State editingCategory: 控制編輯分類 Sheet
//
// 注意事項：
//   - 預設分類（isDefault == true）在 UI 層禁止刪除，但 Model 層無強制保護
//   - filteredCategories 為依 selectedType 篩選的 computed property
//   - 從 SettingsView 透過 NavigationLink 導航進入此頁面
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

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    var body: some View {
        List {
            Picker("類型", selection: $selectedType) {
                Text("支出").tag(TransactionType.expense)
                Text("收入").tag(TransactionType.income)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            ForEach(filteredCategories) { category in
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
            .onDelete(perform: deleteCategories)
        }
        .navigationTitle("分類管理")
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
    }

    private func deleteCategories(offsets: IndexSet) {
        for index in offsets {
            let category = filteredCategories[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
        WidgetDataSync.updateSnapshot(from: modelContext)
    }
}
