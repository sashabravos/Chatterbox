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
        table.isHidden = true
        table.register(UITableViewCell.self,
                       forCellReuseIdentifier: "ChatCell")
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
        
        fetchConversations()
        
        title = "Chats"
        navigationController?.navigationBar.prefersLargeTitles = true
        
    }
    
    @objc private func didTapComposeButton() {
        let newConversationVC = NewConversationViewController()
        newConversationVC.completion = { [weak self] result  in
            print("\(result)")
        }
        let navVC = UINavigationController(rootViewController: newConversationVC)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result: [String: String]) {
        let ChatVC = ChatViewController()
        ChatVC.title = "Jenny Smith"
        ChatVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(ChatVC, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
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
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        cell.textLabel?.text = "Hi"
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let ChatVC = ChatViewController()
        ChatVC.title = "Jenny Smith"
        ChatVC.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(ChatVC, animated: true)
    }
}
