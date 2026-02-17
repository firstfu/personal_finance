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
