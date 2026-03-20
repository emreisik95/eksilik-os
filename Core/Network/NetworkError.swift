import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case notFound
    case decodingFailed
    case noData
    case unauthorized
    case rateLimited
    case cloudflareBlocked
    case paywall
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "geçersiz adres"
        case .requestFailed(let code): return "bir hata oluştu (kod: \(code))"
        case .notFound: return "aradığınız başlık bulunamadı"
        case .decodingFailed: return "sayfa okunamadı"
        case .noData: return "veri alınamadı"
        case .unauthorized: return "giriş yapmanız gerekiyor"
        case .rateLimited: return "çok fazla istek gönderildi, biraz bekleyin"
        case .cloudflareBlocked: return "bağlantı kurulamadı, giriş sayfasından oturum açın"
        case .paywall: return "bu özelliği kullanmak için reklamsız üyeliğe sahip olmanız gerekmektedir"
        case .unknown(let error): return error.localizedDescription
        }
    }
}
