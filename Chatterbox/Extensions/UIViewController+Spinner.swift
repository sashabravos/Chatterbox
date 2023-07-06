//
//  UIViewController+Spinner.swift
//  Chatterbox
//
//  Created by Александра Кострова on 29.06.2023.
//

import UIKit
import NVActivityIndicatorView

extension UIViewController {
    private struct AssociatedKeys {
        static var spinnerKey = "spinnerKey"
    }
    
    private var spinner: NVActivityIndicatorView {
        get {
            if let existingSpinner = objc_getAssociatedObject(self, &AssociatedKeys.spinnerKey) as? NVActivityIndicatorView {
                return existingSpinner
            }
            
            let newSpinner = NVActivityIndicatorView(frame: .zero, type: .ballSpinFadeLoader, color: .black)
            objc_setAssociatedObject(self, &AssociatedKeys.spinnerKey, newSpinner, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return newSpinner
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.spinnerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func showSpinner() {
        DispatchQueue.main.async {
            
            self.view.addSubview(self.spinner)
            self.spinner.translatesAutoresizingMaskIntoConstraints = false
            
                NSLayoutConstraint.activate ([
                    self.spinner.widthAnchor.constraint(equalToConstant: 40.0),
                    self.spinner.heightAnchor.constraint(equalToConstant: 40.0),
                    self.spinner.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                    self.spinner.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
                ])
            
            self.spinner.startAnimating()
        }
    }
    
    func hideSpinner() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.spinner.removeFromSuperview()
        }
    }
}

