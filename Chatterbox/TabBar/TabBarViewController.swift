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
        
        view.backgroundColor = .systemBackground

        let contacts = ContactsViewController()
        let chats = ConversationsViewController()
        let profile = ProfileViewController()

        viewControllers = [
            generateNavigationController(rootViewController: contacts,
                                         title: "Contacts",
                                         image: UIImage(systemName: "person.crop.circle") ?? UIImage()),
            
            generateNavigationController(rootViewController: chats,
                                         title: "Chats",
                                         image: UIImage(systemName: "bubble.left.and.bubble.right.fill") ?? UIImage()),
            
            generateNavigationController(rootViewController: profile,
                                         title: "Settings",
                                         image: UIImage(systemName: "gear") ?? UIImage())
        ]
        
        //  index of the controller that starts first when the application starts
        // 0 - contacts, 1 - chats, 2 - profile settings
        selectedIndex = 1
    }
    
    private func generateNavigationController(rootViewController: UIViewController, title: String, image: UIImage) -> UIViewController {
        let navigationVC = UINavigationController(rootViewController: rootViewController)
        navigationVC.tabBarItem.title = title
        navigationVC.tabBarItem.image = image
        return navigationVC
    } 
}
