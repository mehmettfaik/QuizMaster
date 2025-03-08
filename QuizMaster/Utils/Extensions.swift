import UIKit

extension UIView {
    func addShadow(opacity: Float = 0.2, radius: CGFloat = 3, offset: CGSize = .zero) {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = opacity
        layer.shadowRadius = radius
        layer.shadowOffset = offset
        layer.masksToBounds = false
    }
    
    func roundCorners(radius: CGFloat = 8) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
    }
}

extension UIColor {
    static let primaryPurple = UIColor(red: 0.53, green: 0.23, blue: 0.87, alpha: 1.0)
    static let secondaryPurple = UIColor(red: 0.45, green: 0.31, blue: 0.95, alpha: 1.0)
    static let backgroundPurple = UIColor(red: 0.96, green: 0.95, blue: 1.0, alpha: 1.0)
}

extension UIViewController {
    func showAlert(title: String, message: String, action: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            action?()
        })
        present(alert, animated: true)
    }
    
    func showError(_ error: Error) {
        showAlert(title: "Error", message: error.localizedDescription)
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
} 