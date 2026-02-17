# Widget 桌面小工具 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add iOS WidgetKit home screen widgets (small/medium/large) showing monthly finance summary, powered by shared SwiftData via App Group.

**Architecture:** Widget Extension reads from the same SwiftData store as the main app via App Group shared container. Main app triggers widget refresh on data changes. Three widget sizes display progressively more detail.

**Tech Stack:** Swift, SwiftUI, WidgetKit, SwiftData, App Groups

---

### Task 1: Create Widget Extension target via Xcode project file

**Files:**
- Create: `personal_finance_Widget/personal_finance_Widget.swift`
- Create: `personal_finance_Widget/personal_finance_Widget.entitlements`
- Create: `personal_finance_Widget/Info.plist`
- Create: `personal_finance_Widget/Assets.xcassets/Contents.json`
- Create: `personal_finance_Widget/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `personal_finance_Widget/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `personal_finance_Widget/Assets.xcassets/WidgetBackground.colorset/Contents.json`
- Modify: `personal_finance.xcodeproj/project.pbxproj`
- Modify: `personal_finance/personal_finance.entitlements`

**Step 1: Create the Widget Extension directory and stub files**

Create `personal_finance_Widget/personal_finance_Widget.swift`:

```swift
import WidgetKit
import SwiftUI

struct FinanceWidgetEntry: TimelineEntry {
    let date: Date
    let monthlyIncome: Decimal
    let monthlyExpense: Decimal
    let monthlyBalance: Decimal
    let topCategories: [CategorySummary]
    let recentTransactions: [WidgetTransaction]
    let accounts: [AccountSummary]
    let displayMonth: String

    struct CategorySummary {
        let name: String
        let icon: String
        let colorHex: String
        let percentage: Double
    }

    struct WidgetTransaction {
        let categoryIcon: String
        let categoryName: String
        let note: String
        let amount: Decimal
        let isIncome: Bool
    }

    struct AccountSummary {
        let name: String
        let icon: String
        let balance: Decimal
    }

    static let placeholder = FinanceWidgetEntry(
        date: .now,
        monthlyIncome: 45000,
        monthlyExpense: 32650,
        monthlyBalance: 12350,
        topCategories: [
            .init(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", percentage: 35),
            .init(name: "交通", icon: "car.fill", colorHex: "#2196F3", percentage: 20),
            .init(name: "娛樂", icon: "gamecontroller.fill", colorHex: "#9C27B0", percentage: 15),
        ],
        recentTransactions: [
            .init(categoryIcon: "fork.knife", categoryName: "飲食", note: "午餐", amount: 120, isIncome: false),
            .init(categoryIcon: "car.fill", categoryName: "交通", note: "捷運", amount: 500, isIncome: false),
            .init(categoryIcon: "briefcase.fill", categoryName: "薪資", note: "2月薪水", amount: 45000, isIncome: true),
        ],
        accounts: [
            .init(name: "現金", icon: "banknote.fill", balance: 2350),
            .init(name: "銀行存款", icon: "building.columns.fill", balance: 8000),
            .init(name: "信用卡", icon: "creditcard.fill", balance: -2000),
        ],
        displayMonth: "2月"
    )
}

struct FinanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FinanceWidgetEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceWidgetEntry>) -> Void) {
        // TODO: Task 3 will implement SwiftData query
        let entry = FinanceWidgetEntry.placeholder
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct personal_finance_Widget: Widget {
    let kind: String = "personal_finance_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceTimelineProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("月收支摘要")
        .description("查看本月收入、支出和餘額")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

Create `personal_finance_Widget/personal_finance_Widget.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.firstfu.personal-finance</string>
    </array>
</dict>
</plist>
```

Create `personal_finance_Widget/Info.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
```

Create asset catalog files:

`personal_finance_Widget/Assets.xcassets/Contents.json`:
```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`personal_finance_Widget/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`personal_finance_Widget/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

`personal_finance_Widget/Assets.xcassets/WidgetBackground.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

**Step 2: Add App Group entitlement to main app**

Modify `personal_finance/personal_finance.entitlements` to add the App Group:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>aps-environment</key>
    <string>development</string>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.firstfu.com.personal-finance</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudDocuments</string>
    </array>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.firstfu.personal-finance</string>
    </array>
</dict>
</plist>
```

**Step 3: Add Widget Extension target to `project.pbxproj`**

This is the most complex step. The `project.pbxproj` must be updated to add:
- A new `PBXNativeTarget` for `personal_finance_WidgetExtension` (product type `com.apple.product-type.app-extension`)
- `PBXGroup` entries for the Widget files
- `PBXBuildFile` entries for all Widget source files AND shared source files (Models, Theme, Helpers)
- `PBXFileReference` entries for all new files
- A `PBXSourcesBuildPhase` including Widget source + shared Models/Theme/Helpers
- A `PBXResourcesBuildPhase` for the Widget's Assets.xcassets
- A `PBXFrameworksBuildPhase` linking WidgetKit.framework and SwiftUI.framework
- `XCBuildConfiguration` entries (Debug + Release) with:
  - `PRODUCT_BUNDLE_IDENTIFIER = com.firstfu.com.personal-finance.Widget`
  - `INFOPLIST_FILE = personal_finance_Widget/Info.plist`
  - `CODE_SIGN_ENTITLEMENTS = personal_finance_Widget/personal_finance_Widget.entitlements`
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  - `DEVELOPMENT_TEAM = WY468E45SJ`
  - `IPHONEOS_DEPLOYMENT_TARGET = 26.2`
  - `GENERATE_INFOPLIST_FILE = YES`
  - `CURRENT_PROJECT_VERSION = 1`
  - `MARKETING_VERSION = 1.0`
- A `PBXCopyFilesBuildPhase` (embed app extensions) in the main app target
- Add the Widget extension to the main app's `dependencies`

**Important:** The shared source files (Models/*.swift, Theme/*.swift, Helpers/CurrencyFormatter.swift) must be added to BOTH targets' `PBXSourcesBuildPhase`. Do NOT physically move them — just add build file references for the Widget target. The files stay in their current directories.

**Step 4: Build to verify target setup**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add personal_finance_Widget/ personal_finance/personal_finance.entitlements personal_finance.xcodeproj/project.pbxproj
git commit -m "feat: add Widget Extension target with App Group and stub files"
```

---

### Task 2: Migrate ModelContainer to App Group shared directory

**Files:**
- Modify: `personal_finance/personal_financeApp.swift`

**Step 1: Update ModelContainer to use App Group URL**

Replace the entire `personal_financeApp.swift` with:

```swift
import SwiftUI
import SwiftData
import WidgetKit

@main
struct personal_financeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
        ])

        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.firstfu.personal-finance")!
            .appending(path: "default.store")

        // Migrate existing data from old location if needed
        let oldURL = URL.applicationSupportDirectory
            .appending(path: "default.store")
        if FileManager.default.fileExists(atPath: oldURL.path())
            && !FileManager.default.fileExists(atPath: appGroupURL.path()) {
            try? FileManager.default.copyItem(at: oldURL, to: appGroupURL)
            // Also copy WAL and SHM files if they exist
            let walURL = oldURL.deletingPathExtension().appendingPathExtension("store-wal")
            let shmURL = oldURL.deletingPathExtension().appendingPathExtension("store-shm")
            let newWal = appGroupURL.deletingPathExtension().appendingPathExtension("store-wal")
            let newShm = appGroupURL.deletingPathExtension().appendingPathExtension("store-shm")
            if FileManager.default.fileExists(atPath: walURL.path()) {
                try? FileManager.default.copyItem(at: walURL, to: newWal)
            }
            if FileManager.default.fileExists(atPath: shmURL.path()) {
                try? FileManager.default.copyItem(at: shmURL, to: newShm)
            }
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: appGroupURL,
            allowsSave: true
        )

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
                    let context = sharedModelContainer.mainContext
                    DefaultCategories.seed(into: context)
                    DefaultCategories.seedAccounts(into: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 2: Build and run to verify migration works**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add personal_finance/personal_financeApp.swift
git commit -m "feat: migrate ModelContainer to App Group shared directory"
```

---

### Task 3: Implement WidgetDataProvider with SwiftData queries

**Files:**
- Create: `personal_finance_Widget/WidgetDataProvider.swift`
- Modify: `personal_finance_Widget/personal_finance_Widget.swift`

**Step 1: Create WidgetDataProvider**

Create `personal_finance_Widget/WidgetDataProvider.swift`:

```swift
import Foundation
import SwiftData

enum WidgetDataProvider {
    static func fetchEntry() -> FinanceWidgetEntry {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
        ])

        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.firstfu.personal-finance")!
            .appending(path: "default.store")

        let config = ModelConfiguration(
            schema: schema,
            url: appGroupURL,
            allowsSave: false
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .placeholder
        }

        let context = ModelContext(container)
        context.autosaveEnabled = false

        let calendar = Calendar.current
        let now = Date.now
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        // Fetch all transactions for current month
        let monthPredicate = #Predicate<Transaction> {
            $0.date >= startOfMonth && $0.date < endOfMonth
        }
        var descriptor = FetchDescriptor<Transaction>(
            predicate: monthPredicate,
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        )

        guard let monthTransactions = try? context.fetch(descriptor) else {
            return .placeholder
        }

        let monthlyIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let monthlyExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }

        // Top 3 expense categories
        let expenseTransactions = monthTransactions.filter { $0.type == .expense }
        var categoryTotals: [String: (name: String, icon: String, colorHex: String, total: Decimal)] = [:]
        for tx in expenseTransactions {
            let name = tx.category?.name ?? "其他"
            let icon = tx.category?.icon ?? "ellipsis.circle.fill"
            let colorHex = tx.category?.colorHex ?? "#607D8B"
            let key = name
            if var existing = categoryTotals[key] {
                existing.total += tx.amount
                categoryTotals[key] = existing
            } else {
                categoryTotals[key] = (name: name, icon: icon, colorHex: colorHex, total: tx.amount)
            }
        }
        let totalExpenseForPercent = monthlyExpense > 0 ? monthlyExpense : 1
        let topCategories = categoryTotals.values
            .sorted { $0.total > $1.total }
            .prefix(3)
            .map { cat in
                FinanceWidgetEntry.CategorySummary(
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    percentage: Double(truncating: (cat.total / totalExpenseForPercent * 100) as NSDecimalNumber)
                )
            }

        // Recent 5 transactions (all types)
        let recentTransactions = Array(monthTransactions.prefix(5)).map { tx in
            FinanceWidgetEntry.WidgetTransaction(
                categoryIcon: tx.category?.icon ?? "ellipsis.circle.fill",
                categoryName: tx.category?.name ?? "其他",
                note: tx.note,
                amount: tx.amount,
                isIncome: tx.type == .income
            )
        }

        // Accounts
        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\Account.sortOrder)])
        let accounts = (try? context.fetch(accountDescriptor)) ?? []
        let accountSummaries = accounts.map { account in
            FinanceWidgetEntry.AccountSummary(
                name: account.name,
                icon: account.icon,
                balance: account.currentBalance
            )
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "zh_TW")
        monthFormatter.dateFormat = "M月"

        return FinanceWidgetEntry(
            date: now,
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
            monthlyBalance: monthlyIncome - monthlyExpense,
            topCategories: topCategories,
            recentTransactions: recentTransactions,
            accounts: accountSummaries,
            displayMonth: monthFormatter.string(from: now)
        )
    }
}
```

**Step 2: Update TimelineProvider to use real data**

In `personal_finance_Widget/personal_finance_Widget.swift`, replace the `getTimeline` method:

```swift
func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceWidgetEntry>) -> Void) {
    let entry = WidgetDataProvider.fetchEntry()
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
}
```

Also update `getSnapshot`:

```swift
func getSnapshot(in context: Context, completion: @escaping (FinanceWidgetEntry) -> Void) {
    if context.isPreview {
        completion(.placeholder)
    } else {
        completion(WidgetDataProvider.fetchEntry())
    }
}
```

**Step 3: Add WidgetDataProvider.swift to Widget target in project.pbxproj**

Add `PBXBuildFile` and `PBXFileReference` for `WidgetDataProvider.swift` in the Widget Extension target's sources build phase.

**Step 4: Build to verify**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add personal_finance_Widget/WidgetDataProvider.swift personal_finance_Widget/personal_finance_Widget.swift personal_finance.xcodeproj/project.pbxproj
git commit -m "feat: implement WidgetDataProvider with SwiftData queries"
```

---

### Task 4: Build SmallWidgetView

**Files:**
- Create: `personal_finance_Widget/Views/SmallWidgetView.swift`

**Step 1: Create SmallWidgetView**

Create `personal_finance_Widget/Views/SmallWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                Text("本月餘額")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text(CurrencyFormatter.format(entry.monthlyBalance))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 8))
                        Text("收入")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    Text(CurrencyFormatter.format(entry.monthlyIncome))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 8))
                        Text("支出")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    Text(CurrencyFormatter.format(entry.monthlyExpense))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }
}
```

**Step 2: Add to project.pbxproj Widget target sources**

Add `PBXFileReference` and `PBXBuildFile` for `SmallWidgetView.swift` in the Widget Extension target.

**Step 3: Build to verify**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add personal_finance_Widget/Views/SmallWidgetView.swift personal_finance.xcodeproj/project.pbxproj
git commit -m "feat: add SmallWidgetView with monthly balance summary"
```

---

### Task 5: Build MediumWidgetView

**Files:**
- Create: `personal_finance_Widget/Views/MediumWidgetView.swift`
- Modify: `personal_finance_Widget/personal_finance_Widget.swift`

**Step 1: Create MediumWidgetView**

Create `personal_finance_Widget/Views/MediumWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                    Text("本月收支")
                        .font(.caption)
                    Spacer()
                    Text(entry.displayMonth)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.85))

                Text(CurrencyFormatter.format(entry.monthlyBalance))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("本月餘額")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 8))
                            Text("收入")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        Text(CurrencyFormatter.format(entry.monthlyIncome))
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 8))
                            Text("支出")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        Text(CurrencyFormatter.format(entry.monthlyExpense))
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Top categories
            VStack(alignment: .leading, spacing: 6) {
                Text("支出分類")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

                if entry.topCategories.isEmpty {
                    Text("尚無資料")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(Array(entry.topCategories.enumerated()), id: \.offset) { _, cat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 8, height: 8)
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                            Text(cat.name)
                                .font(.system(size: 11))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(cat.percentage))%")
                                .font(.system(size: 11, design: .rounded, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }
}
```

**Step 2: Update Widget body to switch on family**

In `personal_finance_Widget/personal_finance_Widget.swift`, update the Widget body to use `@Environment(\.widgetFamily)`:

```swift
struct personal_finance_WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FinanceWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}
```

Update the Widget configuration to use this entry view:

```swift
struct personal_finance_Widget: Widget {
    let kind: String = "personal_finance_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceTimelineProvider()) { entry in
            personal_finance_WidgetEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("月收支摘要")
        .description("查看本月收入、支出和餘額")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

**Step 3: Also update SmallWidgetView — move `.containerBackground` there**

Since the entry view now uses `.containerBackground(.clear)`, each size view handles its own background.

**Step 4: Add to project.pbxproj and build**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 5: Commit**

```bash
git add personal_finance_Widget/Views/MediumWidgetView.swift personal_finance_Widget/personal_finance_Widget.swift personal_finance.xcodeproj/project.pbxproj
git commit -m "feat: add MediumWidgetView with category breakdown"
```

---

### Task 6: Build LargeWidgetView

**Files:**
- Create: `personal_finance_Widget/Views/LargeWidgetView.swift`

**Step 1: Create LargeWidgetView**

Create `personal_finance_Widget/Views/LargeWidgetView.swift`:

```swift
import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            // Top: Summary with gradient
            summarySection
                .padding(.bottom, 10)

            Divider()
                .overlay(Color.white.opacity(0.2))

            // Middle: Recent transactions
            transactionsSection
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.white.opacity(0.2))

            // Bottom: Account balances
            accountsSection
                .padding(.top, 6)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }

    private var summarySection: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                Text("本月收支摘要")
                    .font(.caption)
                Spacer()
                Text(entry.displayMonth)
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline) {
                Text(CurrencyFormatter.format(entry.monthlyBalance))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("本月餘額")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 10))
                    Text(CurrencyFormatter.format(entry.monthlyIncome))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                    Text(CurrencyFormatter.format(entry.monthlyExpense))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)

                Spacer()
            }
        }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近交易")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if entry.recentTransactions.isEmpty {
                Text("尚無交易紀錄")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(Array(entry.recentTransactions.enumerated()), id: \.offset) { _, tx in
                    HStack(spacing: 8) {
                        Image(systemName: tx.categoryIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 20)
                        Text(tx.categoryName)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.9))
                        if !tx.note.isEmpty {
                            Text(tx.note)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(tx.isIncome ? "+" : "-")\(CurrencyFormatter.format(tx.amount))")
                            .font(.system(size: 11, design: .rounded, weight: .medium))
                            .foregroundStyle(tx.isIncome ? Color(hex: "#C8E6C9") : Color(hex: "#FFCDD2"))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("帳戶餘額")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if entry.accounts.isEmpty {
                Text("尚無帳戶")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(entry.accounts.enumerated()), id: \.offset) { _, account in
                        HStack(spacing: 4) {
                            Image(systemName: account.icon)
                                .font(.system(size: 10))
                            Text(account.name)
                                .font(.system(size: 10))
                            Text(CurrencyFormatter.format(account.balance))
                                .font(.system(size: 10, design: .rounded, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                }
            }
        }
    }
}
```

**Step 2: Add to project.pbxproj and build**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add personal_finance_Widget/Views/LargeWidgetView.swift personal_finance.xcodeproj/project.pbxproj
git commit -m "feat: add LargeWidgetView with transactions and accounts"
```

---

### Task 7: Add Widget reload triggers in main App

**Files:**
- Modify: `personal_finance/Views/AddTransactionView.swift`
- Modify: `personal_finance/Views/SettingsView.swift`

**Step 1: Add WidgetKit import and reload call to AddTransactionView**

In `personal_finance/Views/AddTransactionView.swift`, add at the top:

```swift
import WidgetKit
```

In the `saveTransaction()` function, after `try? modelContext.save()`, add:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

**Step 2: Add WidgetKit import and reload call to SettingsView**

In `personal_finance/Views/SettingsView.swift`, add at the top:

```swift
import WidgetKit
```

In the `resetAllData()` function, at the end (after `DefaultCategories.seedAccounts`), add:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

Also in `deleteAccounts(offsets:)` and `deleteCategories(offsets:type:)`, add at the end of each function:

```swift
WidgetCenter.shared.reloadAllTimelines()
```

**Step 3: Build to verify**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 4: Commit**

```bash
git add personal_finance/Views/AddTransactionView.swift personal_finance/Views/SettingsView.swift
git commit -m "feat: trigger widget reload on transaction save and data changes"
```

---

### Task 8: Add Deep Link handling in ContentView

**Files:**
- Modify: `personal_finance/ContentView.swift`

**Step 1: Add `.onOpenURL` handler**

In `personal_finance/ContentView.swift`, add an `@State` for tab selection and an `.onOpenURL` modifier:

```swift
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @State private var selectedTab = 0

    private var colorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onOpenURL { url in
            if url.scheme == "personalfinance" {
                selectedTab = 0
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
                .tag(0)

            AddTransactionView()
                .tabItem {
                    Label("記帳", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primaryDark)
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 3: Commit**

```bash
git add personal_finance/ContentView.swift
git commit -m "feat: add deep link handling for widget tap navigation"
```

---

### Task 9: Run tests and final verification

**Files:** None (verification only)

**Step 1: Run unit tests**

Run: `xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' -only-testing:personal_financeTests 2>&1 | tail -20`

Expected: All tests pass.

**Step 2: Full build**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: `BUILD SUCCEEDED`

**Step 3: Update version in SettingsView**

In `personal_finance/Views/SettingsView.swift`, update the version string from `"1.1.0"` to `"2.0.0"`.

**Step 4: Commit**

```bash
git add personal_finance/Views/SettingsView.swift
git commit -m "chore: bump version to 2.0.0 for widget feature release"
```
