# Personal Finance iOS App — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a personal finance iOS app for daily income/expense tracking with category statistics and chart analytics, following the approved Dribbble-inspired lime green design.

**Architecture:** SwiftUI + SwiftData with 4-tab navigation (Home, Add, Analytics, Settings). Data models are Transaction and Category with a one-to-many relationship. Charts use Swift Charts framework. All types default to @MainActor isolation.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, Swift Charts, iOS 26.2

---

## Task 1: Data Models — TransactionType Enum & Category Model

**Files:**
- Delete: `personal_finance/Item.swift`
- Create: `personal_finance/Models/TransactionType.swift`
- Create: `personal_finance/Models/Category.swift`
- Test: `personal_financeTests/CategoryTests.swift`

**Step 1: Create TransactionType enum**

Create `personal_finance/Models/TransactionType.swift`:

```swift
import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense

    var displayName: String {
        switch self {
        case .income: "收入"
        case .expense: "支出"
        }
    }
}
```

**Step 2: Create Category model**

Create `personal_finance/Models/Category.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify)
    var transactions: [Transaction]

    init(name: String, icon: String, colorHex: String, type: TransactionType, sortOrder: Int, isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.transactions = []
    }
}
```

> Note: The `transactions` relationship inverse will be set up in Task 2 when Transaction model is created.

**Step 3: Write test for Category**

Replace `personal_financeTests/personal_financeTests.swift` with:

```swift
import Testing
import Foundation
@testable import personal_finance

struct CategoryTests {
    @Test func categoryInitialization() async throws {
        let category = Category(
            name: "飲食",
            icon: "fork.knife",
            colorHex: "#FF9800",
            type: .expense,
            sortOrder: 0,
            isDefault: true
        )
        #expect(category.name == "飲食")
        #expect(category.icon == "fork.knife")
        #expect(category.colorHex == "#FF9800")
        #expect(category.type == .expense)
        #expect(category.sortOrder == 0)
        #expect(category.isDefault == true)
    }

    @Test func transactionTypeDisplayName() async throws {
        #expect(TransactionType.income.displayName == "收入")
        #expect(TransactionType.expense.displayName == "支出")
    }
}
```

**Step 4: Delete old Item.swift**

Delete `personal_finance/Item.swift` — it's the Xcode template placeholder.

**Step 5: Build and run tests**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: Tests pass (Category model created, TransactionType enum works).

> Note: Build may fail until Transaction model is created in Task 2 due to forward reference. If so, continue to Task 2 and run tests after both models exist.

**Step 6: Commit**

```bash
git add personal_finance/Models/ personal_financeTests/
git rm personal_finance/Item.swift
git commit -m "feat: add Category model and TransactionType enum"
```

---

## Task 2: Data Models — Transaction Model

**Files:**
- Create: `personal_finance/Models/Transaction.swift`
- Create: `personal_financeTests/TransactionTests.swift`

**Step 1: Create Transaction model**

Create `personal_finance/Models/Transaction.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Decimal
    var type: TransactionType
    var category: Category?
    var note: String
    var date: Date
    var createdAt: Date

    init(amount: Decimal, type: TransactionType, category: Category? = nil, note: String = "", date: Date = .now) {
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.createdAt = .now
    }
}
```

**Step 2: Update Category model to add inverse relationship**

In `personal_finance/Models/Category.swift`, update the relationship:

```swift
@Relationship(deleteRule: .nullify, inverse: \Transaction.category)
var transactions: [Transaction]
```

**Step 3: Write Transaction tests**

Create `personal_financeTests/TransactionTests.swift`:

```swift
import Testing
import Foundation
@testable import personal_finance

struct TransactionTests {
    @Test func transactionInitialization() async throws {
        let tx = Transaction(amount: 150, type: .expense, note: "午餐")
        #expect(tx.amount == 150)
        #expect(tx.type == .expense)
        #expect(tx.note == "午餐")
        #expect(tx.category == nil)
    }

    @Test func transactionWithCategory() async throws {
        let cat = Category(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", type: .expense, sortOrder: 0)
        let tx = Transaction(amount: 250, type: .expense, category: cat, note: "晚餐")
        #expect(tx.category?.name == "飲食")
    }
}
```

**Step 4: Build and run all tests**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: All tests pass.

**Step 5: Commit**

```bash
git add personal_finance/Models/Transaction.swift personal_financeTests/TransactionTests.swift personal_finance/Models/Category.swift
git commit -m "feat: add Transaction model with Category relationship"
```

---

## Task 3: Theme & Design System

**Files:**
- Create: `personal_finance/Theme/AppTheme.swift`
- Create: `personal_finance/Theme/Color+Hex.swift`

**Step 1: Create Color hex extension**

Create `personal_finance/Theme/Color+Hex.swift`:

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
```

**Step 2: Create AppTheme**

Create `personal_finance/Theme/AppTheme.swift`:

```swift
import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let primary = Color(hex: "#8BC34A")
    static let primaryDark = Color(hex: "#2E7D32")
    static let surface = Color(hex: "#F5F5F5")
    static let onBackground = Color(hex: "#1A1A1A")
    static let secondaryText = Color(hex: "#757575")
    static let income = Color(hex: "#4CAF50")
    static let expense = Color(hex: "#E53935")

    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Dimensions
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12

    // MARK: - Fonts
    static let amountFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let titleFont = Font.title2.bold()
    static let captionFont = Font.caption
}
```

**Step 3: Build to verify compilation**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Theme/
git commit -m "feat: add design system with color palette, fonts, and spacing"
```

---

## Task 4: Default Categories Seeding

**Files:**
- Create: `personal_finance/Models/DefaultCategories.swift`
- Modify: `personal_finance/personal_financeApp.swift`

**Step 1: Create default categories data**

Create `personal_finance/Models/DefaultCategories.swift`:

```swift
import Foundation

enum DefaultCategories {
    struct CategoryData {
        let name: String
        let icon: String
        let colorHex: String
        let type: TransactionType
        let sortOrder: Int
    }

    static let all: [CategoryData] = expense + income

    static let expense: [CategoryData] = [
        .init(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", type: .expense, sortOrder: 0),
        .init(name: "交通", icon: "car.fill", colorHex: "#2196F3", type: .expense, sortOrder: 1),
        .init(name: "娛樂", icon: "gamecontroller.fill", colorHex: "#9C27B0", type: .expense, sortOrder: 2),
        .init(name: "購物", icon: "bag.fill", colorHex: "#E91E63", type: .expense, sortOrder: 3),
        .init(name: "居住", icon: "house.fill", colorHex: "#795548", type: .expense, sortOrder: 4),
        .init(name: "醫療", icon: "cross.case.fill", colorHex: "#F44336", type: .expense, sortOrder: 5),
        .init(name: "教育", icon: "book.fill", colorHex: "#3F51B5", type: .expense, sortOrder: 6),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#607D8B", type: .expense, sortOrder: 7),
    ]

    static let income: [CategoryData] = [
        .init(name: "薪資", icon: "briefcase.fill", colorHex: "#4CAF50", type: .income, sortOrder: 0),
        .init(name: "獎金", icon: "star.fill", colorHex: "#FFC107", type: .income, sortOrder: 1),
        .init(name: "投資", icon: "chart.line.uptrend.xyaxis", colorHex: "#00BCD4", type: .income, sortOrder: 2),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#8BC34A", type: .income, sortOrder: 3),
    ]

    static func seed(into context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for data in all {
            let category = Category(
                name: data.name,
                icon: data.icon,
                colorHex: data.colorHex,
                type: data.type,
                sortOrder: data.sortOrder,
                isDefault: true
            )
            context.insert(category)
        }
    }
}
```

> Note: Add `import SwiftData` at top of file since `ModelContext` is used.

**Step 2: Update App entry point**

Replace `personal_finance/personal_financeApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct personal_financeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    DefaultCategories.seed(into: sharedModelContainer.mainContext)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 3: Build and run tests**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: All tests pass, build succeeds.

**Step 4: Commit**

```bash
git add personal_finance/Models/DefaultCategories.swift personal_finance/personal_financeApp.swift
git commit -m "feat: add default category seeding on first launch"
```

---

## Task 5: Tab Navigation Shell

**Files:**
- Modify: `personal_finance/ContentView.swift`
- Create: `personal_finance/Views/HomeView.swift`
- Create: `personal_finance/Views/AddTransactionView.swift`
- Create: `personal_finance/Views/AnalyticsView.swift`
- Create: `personal_finance/Views/SettingsView.swift`

**Step 1: Create placeholder views**

Create `personal_finance/Views/HomeView.swift`:

```swift
import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Text("首頁")
                .navigationTitle("首頁")
        }
    }
}
```

Create `personal_finance/Views/AddTransactionView.swift`:

```swift
import SwiftUI

struct AddTransactionView: View {
    var body: some View {
        NavigationStack {
            Text("記帳")
                .navigationTitle("記帳")
        }
    }
}
```

Create `personal_finance/Views/AnalyticsView.swift`:

```swift
import SwiftUI

struct AnalyticsView: View {
    var body: some View {
        NavigationStack {
            Text("分析")
                .navigationTitle("分析")
        }
    }
}
```

Create `personal_finance/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("設定")
                .navigationTitle("設定")
        }
    }
}
```

**Step 2: Replace ContentView with TabView**

Replace `personal_finance/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }

            AddTransactionView()
                .tabItem {
                    Label("記帳", systemImage: "plus.circle.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primaryDark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
```

**Step 3: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Views/ personal_finance/ContentView.swift
git commit -m "feat: add 4-tab navigation shell (Home, Add, Analytics, Settings)"
```

---

## Task 6: HomeView — Monthly Summary Card

**Files:**
- Modify: `personal_finance/Views/HomeView.swift`
- Create: `personal_finance/Views/Components/MonthlySummaryCard.swift`
- Create: `personal_finance/Helpers/CurrencyFormatter.swift`

**Step 1: Create currency formatter**

Create `personal_finance/Helpers/CurrencyFormatter.swift`:

```swift
import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "TWD"
        f.currencySymbol = "NT$"
        f.maximumFractionDigits = 0
        return f
    }()

    static func format(_ value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "NT$0"
    }
}
```

**Step 2: Create MonthlySummaryCard**

Create `personal_finance/Views/Components/MonthlySummaryCard.swift`:

```swift
import SwiftUI

struct MonthlySummaryCard: View {
    let balance: Decimal
    let totalIncome: Decimal
    let totalExpense: Decimal

    var body: some View {
        VStack(spacing: 16) {
            Text("本月餘額")
                .font(AppTheme.captionFont)
                .foregroundStyle(.white.opacity(0.8))

            Text(CurrencyFormatter.format(balance))
                .font(AppTheme.amountFont)
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("收入")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    Text(CurrencyFormatter.format(totalIncome))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("支出")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    Text(CurrencyFormatter.format(totalExpense))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}
```

**Step 3: Update HomeView**

Replace `personal_finance/Views/HomeView.swift`:

```swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(
        filter: #Predicate<Transaction> { tx in
            tx.date >= Calendar.current.startOfMonth && tx.date < Calendar.current.endOfMonth
        },
        sort: \Transaction.date,
        order: .reverse
    )
    private var monthlyTransactions: [Transaction]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    greetingSection
                    MonthlySummaryCard(
                        balance: totalIncome - totalExpense,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense
                    )
                    recentTransactionsSection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Computed

    private var totalIncome: Decimal {
        monthlyTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Decimal {
        monthlyTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Subviews

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("嗨，你好")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.onBackground)
                Text(Date.now, format: .dateTime.year().month().day().weekday(.wide))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 8)
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.headline)
                Spacer()
            }

            if monthlyTransactions.isEmpty {
                Text("尚無交易紀錄")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(monthlyTransactions.prefix(10)) { tx in
                    TransactionRow(transaction: tx)
                }
            }
        }
    }
}
```

> Note: The `#Predicate` with Calendar extensions and `TransactionRow` will be implemented next. The `@Query` predicate may need adjustment since `#Predicate` doesn't support Calendar methods directly — we'll use a simpler approach by computing start/end dates in a separate helper if needed.

**Step 4: Build — expect compilation issues, resolve in next steps**

This task establishes the structure. Predicate issues and missing `TransactionRow` will be resolved in Task 7.

**Step 5: Commit (WIP if needed)**

```bash
git add personal_finance/Views/ personal_finance/Helpers/
git commit -m "feat: add HomeView with monthly summary card and greeting"
```

---

## Task 7: TransactionRow Component & HomeView Fix

**Files:**
- Create: `personal_finance/Views/Components/TransactionRow.swift`
- Modify: `personal_finance/Views/HomeView.swift` (fix @Query predicate)

**Step 1: Create TransactionRow**

Create `personal_finance/Views/Components/TransactionRow.swift`:

```swift
import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                    .foregroundStyle(categoryColor)
            }

            // Name & note
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? "未分類")
                    .font(.body)
                    .foregroundStyle(AppTheme.onBackground)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Amount & date
            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.body.bold())
                    .foregroundStyle(transaction.type == .income ? AppTheme.income : AppTheme.expense)
                Text(transaction.date, format: .dateTime.month().day())
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        guard let hex = transaction.category?.colorHex else { return .gray }
        return Color(hex: hex)
    }

    private var amountText: String {
        let prefix = transaction.type == .income ? "+" : "-"
        return prefix + CurrencyFormatter.format(transaction.amount)
    }
}
```

**Step 2: Fix HomeView @Query**

SwiftData `#Predicate` doesn't support `Calendar` methods. Simplify HomeView to query all transactions sorted by date, then filter in computed properties:

```swift
// In HomeView, replace the @Query with:
@Query(sort: \Transaction.date, order: .reverse)
private var allTransactions: [Transaction]

// Add computed property:
private var monthlyTransactions: [Transaction] {
    let calendar = Calendar.current
    let now = Date.now
    let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
    let end = calendar.date(byAdding: .month, value: 1, to: start)!
    return allTransactions.filter { $0.date >= start && $0.date < end }
}
```

**Step 3: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Views/
git commit -m "feat: add TransactionRow component and fix HomeView query"
```

---

## Task 8: AddTransactionView — Full Recording Interface

**Files:**
- Modify: `personal_finance/Views/AddTransactionView.swift`

**Step 1: Implement full add transaction view**

Replace `personal_finance/Views/AddTransactionView.swift`:

```swift
import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var selectedType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var date = Date.now
    @State private var note = ""
    @State private var showSavedFeedback = false

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Type picker
                    Picker("類型", selection: $selectedType) {
                        Text("支出").tag(TransactionType.expense)
                        Text("收入").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) {
                        selectedCategory = nil
                    }

                    // Amount display
                    amountSection

                    // Category grid
                    categoryGrid

                    // Date picker
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 4)

                    // Note
                    TextField("備註（選填）", text: $note)
                        .textFieldStyle(.roundedBorder)

                    // Save button
                    saveButton
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 8)
            }
            .navigationTitle("記帳")
            .overlay {
                if showSavedFeedback {
                    savedOverlay
                }
            }
        }
    }

    // MARK: - Amount Section

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text(selectedType == .expense ? "支出金額" : "收入金額")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            TextField("0", text: $amountText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(selectedType == .expense ? AppTheme.expense : AppTheme.income)
        }
        .padding(.vertical, 16)
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(filteredCategories) { category in
                categoryButton(category)
            }
        }
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(Color(hex: category.colorHex), lineWidth: 2)
                            .frame(width: 50, height: 50)
                    }
                }
                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(AppTheme.onBackground)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            saveTransaction()
        } label: {
            Text("儲存")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? AppTheme.primaryDark : Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    private var canSave: Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return selectedCategory != nil
    }

    private func saveTransaction() {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }
        let transaction = Transaction(
            amount: amount,
            type: selectedType,
            category: selectedCategory,
            note: note,
            date: date
        )
        modelContext.insert(transaction)

        // Reset form
        amountText = ""
        selectedCategory = nil
        note = ""
        date = .now

        // Show feedback
        withAnimation {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedFeedback = false
            }
        }
    }

    // MARK: - Feedback

    private var savedOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.income)
            Text("已儲存")
                .font(.headline)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }
}
```

**Step 2: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/AddTransactionView.swift
git commit -m "feat: add full transaction recording interface with category grid"
```

---

## Task 9: AnalyticsView — Charts & Statistics

**Files:**
- Modify: `personal_finance/Views/AnalyticsView.swift`

**Step 1: Implement AnalyticsView**

Replace `personal_finance/Views/AnalyticsView.swift`:

```swift
import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "本週"
        case month = "本月"
        case year = "本年"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    periodPicker
                    spendingSummaryCard
                    expenseTrendChart
                    categoryBreakdown
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .navigationTitle("分析")
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Filtered Data

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now
        let start: Date
        switch selectedPeriod {
        case .week:
            start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        case .month:
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        case .year:
            start = calendar.date(from: calendar.dateComponents([.year], from: now))!
        }
        return allTransactions.filter { $0.date >= start }
    }

    private var expenses: [Transaction] {
        filteredTransactions.filter { $0.type == .expense }
    }

    private var totalExpense: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Decimal {
        filteredTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Spending Summary

    private var spendingSummaryCard: some View {
        VStack(spacing: 8) {
            Text("總支出")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
            Text(CurrencyFormatter.format(totalExpense))
                .font(AppTheme.amountFont)
                .foregroundStyle(AppTheme.expense)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    // MARK: - Expense Trend Chart

    private var expenseTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出趨勢")
                .font(.headline)

            if expenses.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(dailyExpenses, id: \.date) { data in
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total)
                        )
                        .foregroundStyle(AppTheme.primary)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total)
                        )
                        .foregroundStyle(AppTheme.primary.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var dailyExpenses: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.map { (date: $0.key, total: NSDecimalNumber(decimal: $0.value.reduce(0) { $0 + $1.amount }).doubleValue) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Category Breakdown

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分類比例")
                .font(.headline)

            if expenses.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                // Pie chart
                Chart(categoryData, id: \.name) { item in
                    SectorMark(
                        angle: .value("金額", item.total),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .frame(height: 200)

                // Category list
                ForEach(categoryData, id: \.name) { item in
                    HStack {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.body)
                        Spacer()
                        Text(CurrencyFormatter.format(item.total))
                            .font(.body.monospacedDigit())
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var categoryData: [(name: String, colorHex: String, total: Decimal, percentage: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "未分類" }
        let total = totalExpense
        guard total > 0 else { return [] }
        return grouped.map { key, txs in
            let sum = txs.reduce(Decimal.zero) { $0 + $1.amount }
            let colorHex = txs.first?.category?.colorHex ?? "#607D8B"
            let pct = NSDecimalNumber(decimal: sum / total * 100).doubleValue
            return (name: key, colorHex: colorHex, total: sum, percentage: pct)
        }
        .sorted { $0.total > $1.total }
    }
}
```

**Step 2: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/AnalyticsView.swift
git commit -m "feat: add analytics with expense trend chart and category breakdown"
```

---

## Task 10: SettingsView — Category Management

**Files:**
- Modify: `personal_finance/Views/SettingsView.swift`

**Step 1: Implement SettingsView with category management**

Replace `personal_finance/Views/SettingsView.swift`:

```swift
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

// MARK: - CategoryFormView

struct CategoryFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Category)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let cat): return cat.id.uuidString
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
```

> Note: `Category` needs to conform to `Identifiable` for `.sheet(item:)`. SwiftData `@Model` classes automatically conform to `Identifiable` via their `id` property.

**Step 2: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/SettingsView.swift
git commit -m "feat: add settings with category management (add/edit/delete)"
```

---

## Task 11: Onboarding Welcome Screen

**Files:**
- Create: `personal_finance/Views/OnboardingView.swift`
- Modify: `personal_finance/ContentView.swift`

**Step 1: Create OnboardingView**

Create `personal_finance/Views/OnboardingView.swift`:

```swift
import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            AppTheme.primary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.primaryDark)

                VStack(spacing: 12) {
                    Text("輕鬆記錄\n每日收支")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("直覺的介面，幫助你輕鬆管理個人財務\n掌握收支狀況，達成理財目標")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("開始使用")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
```

**Step 2: Update ContentView to show onboarding**

Replace `personal_finance/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView()
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }

            AddTransactionView()
                .tabItem {
                    Label("記帳", systemImage: "plus.circle.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primaryDark)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self], inMemory: true)
}
```

**Step 3: Build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Views/OnboardingView.swift personal_finance/ContentView.swift
git commit -m "feat: add lime green onboarding welcome screen"
```

---

## Task 12: Polish & Final Integration

**Files:**
- Ensure all files added to Xcode project
- Run full test suite
- Final build verification

**Step 1: Run full test suite**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: All tests pass.

**Step 2: Run full build**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 3: Verify file structure**

Expected project structure:

```
personal_finance/
├── personal_financeApp.swift
├── ContentView.swift
├── Models/
│   ├── TransactionType.swift
│   ├── Category.swift
│   ├── Transaction.swift
│   └── DefaultCategories.swift
├── Views/
│   ├── HomeView.swift
│   ├── AddTransactionView.swift
│   ├── AnalyticsView.swift
│   ├── SettingsView.swift
│   ├── OnboardingView.swift
│   └── Components/
│       ├── MonthlySummaryCard.swift
│       └── TransactionRow.swift
├── Theme/
│   ├── AppTheme.swift
│   └── Color+Hex.swift
└── Helpers/
    └── CurrencyFormatter.swift
```

**Step 4: Final commit**

```bash
git add -A
git commit -m "chore: finalize project structure and verify all builds pass"
```

---

## Summary

| Task | Description | Key Files |
|------|-------------|-----------|
| 1 | TransactionType + Category model | Models/ |
| 2 | Transaction model | Models/ |
| 3 | Theme & Design System | Theme/ |
| 4 | Default categories seeding | Models/DefaultCategories.swift, App entry |
| 5 | Tab navigation shell | ContentView + 4 placeholder views |
| 6 | HomeView — summary card | HomeView, MonthlySummaryCard, CurrencyFormatter |
| 7 | TransactionRow + HomeView fix | TransactionRow, HomeView query fix |
| 8 | AddTransactionView — full UI | AddTransactionView |
| 9 | AnalyticsView — charts | AnalyticsView (Swift Charts) |
| 10 | SettingsView — categories | SettingsView, CategoryFormView |
| 11 | Onboarding screen | OnboardingView, ContentView update |
| 12 | Polish & final integration | Full build + test verification |
