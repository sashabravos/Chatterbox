//
//  ContactsViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 28.06.2023.
//

import UIKit

class ContactsViewController: UIViewController {
    
    var tableView = UITableView()
    var contactsData = [[String: String]]()
    private var contacts = [Contacts]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Contacts"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        
        setupTableView()
        getUsersList()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ContactCell.self, forCellReuseIdentifier: ContactCell.identifier)
        
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    func getUsersList() {
        DatabaseManager.shared.getAllUsers { [weak self] result in
            switch result {
            case .success(let userCollection):
                self?.contactsData = userCollection
                self?.prepareData()
            case .failure(let error):
                print("Failed to get users: \(error)")
            }
        }
    }
    
    func prepareData() {

        let contacts: [Contacts] = contactsData.compactMap({ data in
            guard let email = data["email"], let name = data["name"] else {
                return nil
            }
            return Contacts(name: name, email: email)
        })
        self.contacts = contacts
        tableView.reloadData()
    }
    
    @objc private func didTapComposeButton() {
        let newConversationVC = NewConversationViewController()
        let navVC = UINavigationController(rootViewController: newConversationVC)
        present(navVC, animated: true)
    }
    
}

extension ContactsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactCell.identifier, for: indexPath) as! ContactCell

        let info = contacts[indexPath.row]
        cell.configure(username: info.name, email: info.email)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // open chat with selected user
        print("Start chat with: \(contacts[indexPath.row].name)")

    }
}
