//
//  ViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FirebaseAuth
import NVActivityIndicatorView

class ConversationsViewController: UIViewController {
        
    private let spinner = NVActivityIndicatorView(frame: .init(origin: .zero, size: CGSize(width: 20.0, height: 20.0)),
                                                  type: .ballScaleMultiple,
                                                  color: .darkGray)
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = false
        table.register(ConversationCell.self,
                       forCellReuseIdentifier: ConversationCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)

        setupTableView()
        
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    
    @objc private func didTapComposeButton() {
        let newConversationVC = NewConversationViewController()
        let navVC = UINavigationController(rootViewController: newConversationVC)
        present(navVC, animated: true)
    }
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        validateAuth()
    }
    
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10,
                                            y: (view.height-100)/2,
                                            width: view.width-20,
                                            height: 100)
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
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

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.identifier, for: indexPath) as! ConversationCell

        cell.configure(username: "amigo", message: "message here", email: "123123123", senderTime: "10:10", isOnline: true)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let cell = tableView.cellForRow(at: indexPath) as? ConversationCell {
            let ChatVC = ChatViewController()
            ChatVC.title = cell.getConversationName()
            ChatVC.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(ChatVC, animated: true)
            
        } else {
            print("Failed to get ConversationCell")
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
}
