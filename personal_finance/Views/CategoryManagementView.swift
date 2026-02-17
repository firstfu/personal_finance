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
