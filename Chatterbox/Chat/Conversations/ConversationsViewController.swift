//
//  ViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FirebaseAuth

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
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
        
        startListeningForConversations()
        
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    private func startListeningForConversations() {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)

        MessageManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("Failed to download conversations: \(error)")
            }
        }
    }
    
    @objc private func didTapComposeButton() {
        let newConversationVC = NewConversationViewController()
        newConversationVC.completion = {[weak self] result in
            self?.createNewChat(with: result)
        }
        let navVC = UINavigationController(rootViewController: newConversationVC)
        present(navVC, animated: true)
    }
    
    func createNewChat(with contact: SearchResult) {
        let chatViewController = ChatViewController(with: contact.email, id: nil)
        chatViewController.isNewConversation = true
        chatViewController.title = contact.name
        
        navigationController?.pushViewController(chatViewController, animated: true)
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
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.identifier, for: indexPath) as! ConversationCell

        let info = conversations[indexPath.row]
//        cell.configure(with: Conversation(id: info.id, name: info.name, otherUserEmail: info.otherUserEmail, latestMessage: info.latestMessage))
        cell.configure(with: info)


        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let info = conversations[indexPath.row]

        let ChatVC = ChatViewController(with: info.otherUserEmail, id: info.id)
            ChatVC.title = info.name
            ChatVC.navigationItem.largeTitleDisplayMode = .never
            navigationController?.pushViewController(ChatVC, animated: true)
    }
}
