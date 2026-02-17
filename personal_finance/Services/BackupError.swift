import Foundation

enum BackupError: LocalizedError {
    case iCloudNotAvailable
    case directoryCreationFailed
    case encodingFailed(Error)
    case decodingFailed(Error)
    case fileWriteFailed(Error)
    case fileReadFailed(Error)
    case fileNotFound
    case versionIncompatible(Int)
    case restoreFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud 不可用。請確認已登入 iCloud 帳號，並在設定中啟用 iCloud Drive。"
        case .directoryCreationFailed:
            return "無法建立備份資料夾。"
        case .encodingFailed(let error):
            return "備份資料編碼失敗：\(error.localizedDescription)"
        case .decodingFailed(let error):
            return "備份資料解碼失敗：\(error.localizedDescription)"
        case .fileWriteFailed(let error):
            return "備份檔案寫入失敗：\(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "備份檔案讀取失敗：\(error.localizedDescription)"
        case .fileNotFound:
            return "找不到備份檔案。"
        case .versionIncompatible(let version):
            return "備份版本 \(version) 與目前 App 不相容。請更新 App 後再試。"
        case .restoreFailed(let error):
            return "還原失敗：\(error.localizedDescription)"
        case .deleteFailed(let error):
            return "刪除備份失敗：\(error.localizedDescription)"
        }
    }
}
