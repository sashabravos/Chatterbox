//
//  TabBarViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 22.06.2023.
//

import UIKit

class TabBarViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let chats = ConversationsViewController()
        let profile = ProfileViewController()

        viewControllers = [
            generateNavigationController(rootViewController: chats, title: "Chats", image: UIImage(systemName: "circle") ?? UIImage()),
            generateNavigationController(rootViewController: profile, title: "Profile", image: UIImage(systemName: "circle") ?? UIImage())
        ]
    }
    
    private func generateNavigationController(rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationVC = UINavigationController(rootViewController: rootViewController)
        navigationVC.tabBarItem.title = title
        navigationVC.tabBarItem.image = image
        return navigationVC
    } 
}
