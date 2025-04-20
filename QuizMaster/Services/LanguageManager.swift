import Foundation

class LanguageManager {
    static let shared = LanguageManager()
    
    private let languageKey = "AppLanguage"
    private let notificationCenter = NotificationCenter.default
    
    var currentLanguage: String {
        get {
            return UserDefaults.standard.string(forKey: languageKey) ?? "en"
        }
        set {
            UserDefaults.standard.set(newValue, forKey: languageKey)
            UserDefaults.standard.synchronize()
            updateLanguage()
        }
    }
    
    private init() {}
    
    func updateLanguage() {
        // Dil değişikliği bildirimini yayınla
        notificationCenter.post(name: Notification.Name("LanguageChanged"), object: nil)
        
        // Bundle'ı güncelle
        if let languagePath = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
           let bundle = Bundle(path: languagePath) {
            UserDefaults.standard.set([currentLanguage], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
    }
    
    func localizedString(for key: String) -> String {
        let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj")
        let bundle = Bundle(path: path!)
        return NSLocalizedString(key, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
} 