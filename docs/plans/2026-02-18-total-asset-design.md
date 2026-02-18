# 總資產顯示修正與分析頁增強設計

日期：2026-02-18

## 問題

1. 首頁「總資產」數字可能包含 demo 交易資料，導致 `showDemoData = false` 時數字不正確
2. 分析頁缺少總資產資訊
3. 趨勢圖的「淨額」線應改為「總資產」線

## 設計

### 1. Model 修正：Account.currentBalance

- `currentBalance` 過濾掉 `isDemoData == true` 的交易
- `demoBalance` 邏輯維持不變

### 2. 分析頁摘要卡片：新增「總資產」

- 在 `spendingSummaryCard` 的「淨額」下方加一條 Divider + 「總資產」欄位
- AnalyticsView 加入 `@Query accounts` 取得帳戶資料
- 總資產 = 所有帳戶 currentBalance 加總（與首頁相同邏輯）

### 3. 趨勢圖：「淨額」→「總資產」

- `showNetLine` → `showAssetLine`
- 膠囊篩選器標籤「淨額」→「總資產」
- 每天的總資產 = 帳戶初始餘額加總 + 到該天為止的累計淨收支
- 標記文字「淨額」→「總資產」

### 4. 影響檔案

- `Account.swift`：修正 currentBalance 過濾 demo 交易
- `AnalyticsView.swift`：加 accounts query、更新摘要卡片、修改趨勢線
- `HomeView.swift`：無需改動
