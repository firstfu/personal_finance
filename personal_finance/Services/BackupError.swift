// ============================================================================
// MARK: - BackupError.swift
// 模組：Services
//
// 功能說明：
//   這個檔案定義了備份與還原流程中可能發生的錯誤類型。透過遵循
//   LocalizedError 協定，每個錯誤案例都提供繁體中文的使用者友善錯誤訊息。
//
// 主要職責：
//   - 統一定義備份/還原相關的錯誤列舉
//   - 提供本地化的錯誤描述，方便 UI 層直接顯示
//
// 關鍵案例：
//   - encodingFailed: 備份資料編碼（序列化）失敗
//   - decodingFailed: 備份資料解碼（反序列化）失敗
//   - fileReadFailed: 備份檔案讀取失敗
//   - fileNotFound: 找不到備份檔案
//   - versionIncompatible: 備份檔案版本與目前 App 不相容
//   - restoreFailed: 還原過程發生錯誤
//
// 注意事項：
//   - 所有錯誤訊息皆為繁體中文
//   - 部分案例包含關聯值（Error 或 Int），可提供更詳細的錯誤資訊
// ============================================================================

import Foundation

enum BackupError: LocalizedError {
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileReadFailed(Error)
    case fileNotFound
    case versionIncompatible(Int)
    case restoreFailed(Error)

    var errorDescription: String? {
        switch self {
        case .encodingFailed(let error):
            return "備份資料編碼失敗：\(error.localizedDescription)"
        case .decodingFailed(let error):
            return "備份資料解碼失敗：\(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "備份檔案讀取失敗：\(error.localizedDescription)"
        case .fileNotFound:
            return "找不到備份檔案。"
        case .versionIncompatible(let version):
            return "備份版本 \(version) 與目前 App 不相容。請更新 App 後再試。"
        case .restoreFailed(let error):
            return "還原失敗：\(error.localizedDescription)"
        }
    }
}
