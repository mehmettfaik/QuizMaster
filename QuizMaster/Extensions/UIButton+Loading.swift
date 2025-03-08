import UIKit

extension UIButton {
    private static var activityIndicatorAssociatedKey = "ActivityIndicatorAssociatedKey"
    
    private var activityIndicator: UIActivityIndicatorView? {
        get {
            return objc_getAssociatedObject(self, &UIButton.activityIndicatorAssociatedKey) as? UIActivityIndicatorView
        }
        set {
            objc_setAssociatedObject(self, &UIButton.activityIndicatorAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    var isLoading: Bool {
        get {
            return activityIndicator != nil
        }
        set {
            if newValue {
                if activityIndicator == nil {
                    let indicator = UIActivityIndicatorView(style: .medium)
                    indicator.color = titleColor(for: .normal)
                    indicator.hidesWhenStopped = true
                    
                    addSubview(indicator)
                    indicator.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        indicator.centerXAnchor.constraint(equalTo: centerXAnchor),
                        indicator.centerYAnchor.constraint(equalTo: centerYAnchor)
                    ])
                    
                    titleLabel?.alpha = 0
                    imageView?.alpha = 0
                    indicator.startAnimating()
                    
                    activityIndicator = indicator
                    isEnabled = false
                }
            } else {
                activityIndicator?.removeFromSuperview()
                activityIndicator = nil
                titleLabel?.alpha = 1
                imageView?.alpha = 1
                isEnabled = true
            }
        }
    }
} 