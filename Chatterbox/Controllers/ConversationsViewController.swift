//
//  ViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        validateAuth()
    }
    
    private func validateAuth() {
        if Auth.auth().currentUser == nil {
            let logVC = LoginViewController()
            let navVC = UINavigationController(rootViewController: logVC)
            
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: false)
        }
    }
}

