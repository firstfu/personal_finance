# 記帳頁面重設計 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將 AddTransactionView 從 ScrollView + 系統鍵盤改為固定佈局 + 自訂數字鍵盤，並修復分類重複 seed bug。

**Architecture:** 頁面分為上半資訊區（VStack: 類型切換 → 分類水平列 → 帳戶膠囊 → 金額 → 日期備註）與下半固定鍵盤區（NumberPadView + 儲存按鈕）。數字鍵盤抽為獨立元件。Seed bug 透過 init 參數修正 + 啟動清理解決。

**Tech Stack:** Swift, SwiftUI, SwiftData, Swift Testing

---

## Task 1: 修復 Category.init seedIdentifier 參數

**Files:**
- Modify: `personal_finance/Models/Category.swift:24-32`
- Modify: `personal_financeTests/personal_financeTests.swift:13-28`

**Step 1: 更新測試，驗證 seedIdentifier 透過 init 設定**

在 `personal_financeTests/personal_financeTests.swift` 的 `CategoryTests` 中新增：

```swift
@Test func categorySeedIdentifier() async throws {
    let category = Category(
        name: "飲食",
        icon: "fork.knife",
        colorHex: "#FF9800",
        type: .expense,
        sortOrder: 0,
        isDefault: true,
        seedIdentifier: "default_expense_0"
    )
    #expect(category.seedIdentifier == "default_expense_0")
}
```

**Step 2: 執行測試確認失敗**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: 編譯失敗，Category.init 沒有 seedIdentifier 參數

**Step 3: 在 Category.init 加入 seedIdentifier 參數**

修改 `personal_finance/Models/Category.swift:24-32`：

```swift
init(name: String, icon: String, colorHex: String, type: TransactionType, sortOrder: Int, isDefault: Bool = false, seedIdentifier: String = "") {
    self.name = name
    self.icon = icon
    self.colorHex = colorHex
    self.type = type
    self.sortOrder = sortOrder
    self.isDefault = isDefault
    self.seedIdentifier = seedIdentifier
    self.transactions = []
}
```

**Step 4: 執行測試確認通過**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 5: Commit**

```bash
git add personal_finance/Models/Category.swift personal_financeTests/personal_financeTests.swift
git commit -m "fix: add seedIdentifier parameter to Category.init"
```

---

## Task 2: 修復 Account.init seedIdentifier 參數

**Files:**
- Modify: `personal_finance/Models/Account.swift:24-33`
- Modify: `personal_financeTests/personal_financeTests.swift:52-58`

**Step 1: 更新測試**

在 `AccountTests` 中新增：

```swift
@Test func accountSeedIdentifier() async throws {
    let account = Account(
        name: "現金",
        type: .cash,
        icon: "banknote.fill",
        colorHex: "#4CAF50",
        seedIdentifier: "default_account_0"
    )
    #expect(account.seedIdentifier == "default_account_0")
}
```

**Step 2: 執行測試確認失敗**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: 編譯失敗

**Step 3: 在 Account.init 加入 seedIdentifier 參數**

修改 `personal_finance/Models/Account.swift:24-33`：

```swift
init(name: String, type: AccountType, icon: String, colorHex: String, initialBalance: Decimal = 0, sortOrder: Int = 0, isDefault: Bool = false, seedIdentifier: String = "") {
    self.name = name
    self.type = type
    self.icon = icon
    self.colorHex = colorHex
    self.initialBalanceString = "\(initialBalance)"
    self.sortOrder = sortOrder
    self.isDefault = isDefault
    self.seedIdentifier = seedIdentifier
    self.transactions = []
}
```

**Step 4: 執行測試確認通過**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 5: Commit**

```bash
git add personal_finance/Models/Account.swift personal_financeTests/personal_financeTests.swift
git commit -m "fix: add seedIdentifier parameter to Account.init"
```

---

## Task 3: 更新 DefaultCategories seed 邏輯 + 啟動清理

**Files:**
- Modify: `personal_finance/Models/DefaultCategories.swift:41-57` (seed function)
- Modify: `personal_finance/Models/DefaultCategories.swift:75-92` (seedAccounts function)
- Modify: `personal_finance/personal_financeApp.swift:34-43`

**Step 1: 更新 DefaultCategories.seed() 使用 init 參數**

修改 `personal_finance/Models/DefaultCategories.swift` 的 `seed` 函式：

```swift
static func seed(into context: ModelContext) {
    let existingCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
    let existingIds = Set(existingCategories.map(\.seedIdentifier))

    for data in all {
        guard !existingIds.contains(data.seedIdentifier) else { continue }
        let category = Category(
            name: data.name,
            icon: data.icon,
            colorHex: data.colorHex,
            type: data.type,
            sortOrder: data.sortOrder,
            isDefault: true,
            seedIdentifier: data.seedIdentifier
        )
        context.insert(category)
    }
}
```

**Step 2: 同樣更新 seedAccounts()**

```swift
static func seedAccounts(into context: ModelContext) {
    let existingAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
    let existingIds = Set(existingAccounts.map(\.seedIdentifier))

    for data in defaultAccounts {
        guard !existingIds.contains(data.seedIdentifier) else { continue }
        let account = Account(
            name: data.name,
            type: data.type,
            icon: data.icon,
            colorHex: data.colorHex,
            sortOrder: data.sortOrder,
            isDefault: true,
            seedIdentifier: data.seedIdentifier
        )
        context.insert(account)
    }
}
```

**Step 3: 在 personal_financeApp.swift 加入啟動清理**

在 `DefaultCategories.seed(into:)` 呼叫前加入清理函式：

```swift
.onAppear {
    let context = sharedModelContainer.mainContext

    MigrationService.migrateIfNeeded(to: context)

    // Clean up duplicate seeded categories
    DefaultCategories.removeDuplicates(from: context)

    DefaultCategories.seed(into: context)
    DefaultCategories.seedAccounts(into: context)

    WidgetDataSync.updateSnapshot(from: context)

    NotificationCenter.default.addObserver(
        forName: .NSPersistentStoreRemoteChange,
        object: nil,
        queue: .main
    ) { _ in
        WidgetDataSync.updateSnapshot(from: context)
    }
}
```

**Step 4: 在 DefaultCategories 加入 removeDuplicates**

在 `DefaultCategories.swift` 末尾加入：

```swift
static func removeDuplicates(from context: ModelContext) {
    // Clean duplicate categories
    let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
    var seenCategoryIds = Set<String>()
    for category in allCategories {
        guard !category.seedIdentifier.isEmpty else { continue }
        if seenCategoryIds.contains(category.seedIdentifier) {
            context.delete(category)
        } else {
            seenCategoryIds.insert(category.seedIdentifier)
        }
    }

    // Clean duplicate accounts
    let allAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
    var seenAccountIds = Set<String>()
    for account in allAccounts {
        guard !account.seedIdentifier.isEmpty else { continue }
        if seenAccountIds.contains(account.seedIdentifier) {
            context.delete(account)
        } else {
            seenAccountIds.insert(account.seedIdentifier)
        }
    }
}
```

**Step 5: 建置確認編譯通過**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 6: 執行測試確認不影響既有測試**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 7: Commit**

```bash
git add personal_finance/Models/DefaultCategories.swift personal_finance/personal_financeApp.swift
git commit -m "fix: seed via init parameter and clean up duplicate categories/accounts on launch"
```

---

## Task 4: 建立 NumberPadView 元件

**Files:**
- Create: `personal_finance/Views/Components/NumberPadView.swift`
- Create: `personal_financeTests/NumberPadTests.swift`

**Step 1: 撰寫 NumberPadView 輸入邏輯測試**

建立 `personal_financeTests/NumberPadTests.swift`：

```swift
import Testing
import Foundation
@testable import personal_finance

struct NumberPadLogicTests {
    @Test func appendDigit() async throws {
        var text = ""
        NumberPadLogic.append("5", to: &text)
        #expect(text == "5")
        NumberPadLogic.append("3", to: &text)
        #expect(text == "53")
    }

    @Test func appendDecimalOnce() async throws {
        var text = "12"
        NumberPadLogic.append(".", to: &text)
        #expect(text == "12.")
        NumberPadLogic.append(".", to: &text)
        #expect(text == "12.") // 不重複加
    }

    @Test func maxTwoDecimalPlaces() async throws {
        var text = "12.34"
        NumberPadLogic.append("5", to: &text)
        #expect(text == "12.34") // 不超過兩位小數
    }

    @Test func maxAmount() async throws {
        var text = "9999999"
        NumberPadLogic.append("9", to: &text)
        #expect(text == "9999999") // 不超過上限
    }

    @Test func deleteLast() async throws {
        var text = "123"
        NumberPadLogic.deleteLast(from: &text)
        #expect(text == "12")
    }

    @Test func deleteFromEmpty() async throws {
        var text = ""
        NumberPadLogic.deleteLast(from: &text)
        #expect(text == "")
    }

    @Test func leadingZeroPrevention() async throws {
        var text = "0"
        NumberPadLogic.append("0", to: &text)
        #expect(text == "0") // 不加前導零
        NumberPadLogic.append("5", to: &text)
        #expect(text == "5") // 替換前導零
    }

    @Test func formattedDisplay() async throws {
        #expect(NumberPadLogic.formatted("1250") == "1,250")
        #expect(NumberPadLogic.formatted("") == "0")
        #expect(NumberPadLogic.formatted("1234567") == "1,234,567")
        #expect(NumberPadLogic.formatted("12.5") == "12.5")
    }
}
```

**Step 2: 執行測試確認失敗**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: 編譯失敗，NumberPadLogic 不存在

**Step 3: 建立 NumberPadView.swift 含邏輯與 UI**

建立 `personal_finance/Views/Components/NumberPadView.swift`：

```swift
import SwiftUI

enum NumberPadLogic {
    static func append(_ char: String, to text: inout String) {
        if char == "." {
            guard !text.contains(".") else { return }
            if text.isEmpty { text = "0" }
            text.append(".")
            return
        }

        // Check decimal places limit
        if let dotIndex = text.firstIndex(of: ".") {
            let decimalPart = text[text.index(after: dotIndex)...]
            guard decimalPart.count < 2 else { return }
        }

        // Handle leading zero
        if text == "0" {
            text = char
            return
        }

        // Check max amount (integer part <= 9999999)
        let candidate = text + char
        let integerPart = candidate.split(separator: ".").first.map(String.init) ?? candidate
        guard integerPart.count <= 7 else { return }

        text.append(char)
    }

    static func deleteLast(from text: inout String) {
        guard !text.isEmpty else { return }
        text.removeLast()
    }

    static func formatted(_ text: String) -> String {
        guard !text.isEmpty else { return "0" }

        let parts = text.split(separator: ".", maxSplits: 1)
        let integerPart = String(parts[0])

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","

        let formatted: String
        if let number = Int(integerPart) {
            formatted = formatter.string(from: NSNumber(value: number)) ?? integerPart
        } else {
            formatted = integerPart
        }

        if parts.count > 1 {
            return formatted + "." + parts[1]
        } else if text.hasSuffix(".") {
            return formatted + "."
        }
        return formatted
    }
}

struct NumberPadView: View {
    @Binding var text: String
    var onSave: () -> Void
    var canSave: Bool

    private let buttons: [[String]] = [
        ["7", "8", "9"],
        ["4", "5", "6"],
        ["1", "2", "3"],
        [".", "0", "⌫"],
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        NumberPadButton(key: key) {
                            handleTap(key)
                        } onLongPress: {
                            if key == "⌫" {
                                NumberPadLogic.deleteLast(from: &text)
                            }
                        }
                    }
                }
            }

            Button(action: onSave) {
                Text("儲存")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? AppTheme.primaryDark : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            }
            .disabled(!canSave)
            .padding(.top, 4)
        }
        .padding(.horizontal, AppTheme.horizontalPadding)
    }

    private func handleTap(_ key: String) {
        if key == "⌫" {
            NumberPadLogic.deleteLast(from: &text)
        } else {
            NumberPadLogic.append(key, to: &text)
        }
    }
}

struct NumberPadButton: View {
    let key: String
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var longPressTimer: Timer?

    var body: some View {
        Text(key == "⌫" ? "" : key)
            .font(.title2.weight(.medium))
            .overlay {
                if key == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.title3)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
            .opacity(isPressed ? 0.7 : 1.0)
            .onTapGesture {
                onTap()
            }
            .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
                isPressed = pressing
                if pressing && key == "⌫" {
                    longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                        onLongPress()
                    }
                } else {
                    longPressTimer?.invalidate()
                    longPressTimer = nil
                }
            }, perform: {})
    }
}
```

**Step 4: 執行測試確認通過**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 5: Commit**

```bash
git add personal_finance/Views/Components/NumberPadView.swift personal_financeTests/NumberPadTests.swift
git commit -m "feat: add NumberPadView component with input logic and tests"
```

---

## Task 5: 重寫 AddTransactionView

**Files:**
- Modify: `personal_finance/Views/AddTransactionView.swift` (完全重寫)

**Step 1: 重寫 AddTransactionView**

完全替換 `personal_finance/Views/AddTransactionView.swift`：

```swift
import SwiftUI
import SwiftData
import WidgetKit

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var selectedType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var date = Date.now
    @State private var note = ""
    @State private var showSavedFeedback = false
    @State private var showDatePicker = false
    @State private var isEditingNote = false

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    private var canSave: Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return selectedCategory != nil && selectedAccount != nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // === Upper section ===
                VStack(spacing: 12) {
                    typePicker
                    categoryScrollRow
                    accountChips
                    amountDisplay
                    dateNoteRow
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 8)

                Spacer(minLength: 8)

                // === Lower section: Number pad ===
                NumberPadView(
                    text: $amountText,
                    onSave: saveTransaction,
                    canSave: canSave
                )
                .padding(.bottom, 8)
            }

            if showSavedFeedback {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                savedOverlay
            }
        }
        .animation(.easeInOut, value: showSavedFeedback)
        .onAppear {
            if selectedAccount == nil {
                selectedAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first
            }
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        Picker("類型", selection: $selectedType) {
            Text("支出").tag(TransactionType.expense)
            Text("收入").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedType) {
            selectedCategory = nil
        }
    }

    // MARK: - Category Scroll Row

    private var categoryScrollRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(filteredCategories) { category in
                        categoryItem(category)
                            .id(category.id)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: selectedType) {
                if let first = filteredCategories.first {
                    withAnimation {
                        proxy.scrollTo(first.id, anchor: .leading)
                    }
                }
            }
        }
    }

    private func categoryItem(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        let color = Color(hex: category.colorHex)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.icon)
                        .font(.system(size: isSelected ? 28 : 22))
                        .foregroundStyle(color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(category.name)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.onBackground)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isSelected ? color : .clear)
                    .frame(width: 24, height: 3)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Account Chips

    private var accountChips: some View {
        HStack(spacing: 8) {
            ForEach(accounts) { account in
                let isSelected = selectedAccount?.id == account.id
                Button {
                    selectedAccount = account
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: account.icon)
                            .font(.caption)
                        Text(account.name)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isSelected ? AppTheme.primaryDark : AppTheme.surface)
                    .foregroundStyle(isSelected ? .white : AppTheme.onBackground)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text(selectedType == .expense ? "支出金額" : "收入金額")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Text("NT$ \(NumberPadLogic.formatted(amountText))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    amountText.isEmpty
                        ? AppTheme.secondaryText
                        : (selectedType == .expense ? AppTheme.expense : AppTheme.income)
                )
                .contentTransition(.numericText())
                .animation(.snappy, value: amountText)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Date + Note Row

    private var dateNoteRow: some View {
        HStack(spacing: 12) {
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(dateDisplayText)
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isEditingNote {
                TextField("備註", text: $note, onCommit: {
                    isEditingNote = false
                })
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
            } else {
                Button {
                    isEditingNote = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text(note.isEmpty ? "新增備註" : note)
                            .font(.subheadline)
                            .foregroundStyle(note.isEmpty ? AppTheme.secondaryText : AppTheme.onBackground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var dateDisplayText: String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("選擇日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .navigationTitle("選擇日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            showDatePicker = false
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Save

    private func saveTransaction() {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }
        let transaction = Transaction(
            amount: amount,
            type: selectedType,
            category: selectedCategory,
            account: selectedAccount,
            note: note,
            date: date
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)

        amountText = ""
        selectedCategory = nil
        note = ""
        date = .now
        isEditingNote = false

        withAnimation {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showSavedFeedback = false
            }
        }
    }

    // MARK: - Saved Overlay

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

**Step 2: 建置確認編譯通過**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 3: 執行所有測試確認不影響既有功能**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 4: Commit**

```bash
git add personal_finance/Views/AddTransactionView.swift
git commit -m "feat: redesign AddTransactionView with fixed numpad layout and horizontal category scroll"
```

---

## Task 6: 最終驗證與建置

**Files:** 無新檔案

**Step 1: 完整建置**

```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED

**Step 2: 執行全部測試**

```bash
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests 2>&1 | tail -20
```

Expected: ALL TESTS PASSED

**Step 3: 在模擬器上啟動 App 做人工驗證**

確認：
- [ ] 分類不再重複顯示
- [ ] 分類水平滾動正常
- [ ] 帳戶膠囊選擇正常
- [ ] 數字鍵盤輸入正常（含小數、刪除、上限）
- [ ] 儲存流程正常（含回饋動畫）
- [ ] 支出/收入切換正常
- [ ] 日期選擇正常
- [ ] 備註輸入正常
