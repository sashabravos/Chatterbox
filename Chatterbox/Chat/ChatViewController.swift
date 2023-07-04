//
//  ChatViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 24.06.2023.
//

import UIKit
import MessageKit
import SDWebImage
import InputBarAccessoryView

final class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private var conversationID: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    
    init(with email: String, id: String?) {
        self.otherUserEmail = email
        self.conversationID = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        view.addSubview(messagesCollectionView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationID = conversationID {
            listenForMessages(id: conversationID, shouldScrollToBottom: true)
        }
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToBottom()
                    }
                }
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        }
    }
}

// MARK: - InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        if isNewConversation {
            
            DatabaseManager.shared.createNewConversation(name: self.title ?? "Unknown user", with: otherUserEmail,
                                                         firstMessage: message, completion: { [weak self]
                success in
                if success {
                    print("Success sending")
                    self?.isNewConversation = false
                    let newConversationID = "conversation_\(message.messageId)"
                                        self?.conversationID = newConversationID
                                        self?.listenForMessages(id: newConversationID, shouldScrollToBottom: true)
                                        self?.messageInputBar.inputTextView.text = nil
                } else {
                    print("Failed to send")
                }
            })
        } else {
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationID,
                                               otherUserEmail: otherUserEmail,
                                               name: name,
                                               message: message) { [weak self] success in
                if success {
//                    self?.messageInputBar.inputTextView.text = nil
                    print("Message sent successfully.")
                } else {
                    print("Failed to send message.")
                }
            }
        }
        
//        inputBar.inputTextView.text = ""
    }
    
    private func createMessageId() -> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeEmail)_\(dateString)"
        print(newIdentifier)
        return newIdentifier
    }
}


// MARK: - MessagesDataSource
extension ChatViewController: MessagesDataSource {
    
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self sender is nil")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
}

// MARK: - MessagesDisplayDelegate, MessagesLayoutDelegate
extension ChatViewController: MessagesDisplayDelegate, MessagesLayoutDelegate {
    func textColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func backgroundColor(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> UIColor {
        isFromCurrentSender(message: message) ? .systemBlue : UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) -> MessageStyle {
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at _: IndexPath, in _: MessagesCollectionView) {
        
        let senderId = message.sender.senderId
        
        let avatarPath = "avatars/\(senderId).png"
        
        StorageManager.shared.downloadURL(for: avatarPath) { result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    avatarView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get avatar download URL: \(error)")
            }
        }
    }
}
