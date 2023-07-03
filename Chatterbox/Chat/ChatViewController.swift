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
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        formatter.locale = Locale(identifier: "en_US")
        return formatter
    }()

    public var isNewConversation = false
    public let otherUserEmail: String
    
    private var messages = [Message]()

    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
       return Sender(photoURL: "",
               senderId: email,
               displayName: "")
    }

    var sender = Sender(photoURL: "",
                                  senderId: "",
                                  displayName: "")
    
    var message: Message {
        return Message(sender: sender,
                       messageId: UUID().uuidString,
                       sentDate: Date(),
                       kind: .text(""))
    }
    
    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemPink
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        view.addSubview(messagesCollectionView)
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
            
        
        print(text)
        
        if isNewConversation {
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(name: self.title ?? "Unknown user", with: otherUserEmail,
                                                         firstMessage: message, completion: {
                success in
                if success {
                    print("Success sending")
                } else {
                    print("Failed ti send")
                }
            })
        } else {
            
        }
        

//        DatabaseManager.shared.sendMessage(to: "recipientID",
//                                           sender: sender,
//                                           message: message) { success in
//            if success {
//                print("Message sent successfully.")
//            } else {
//                print("Failed to send message.")
//            }
//        }

        inputBar.inputTextView.text = ""
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
        return Sender(photoURL: "", senderId: "123", displayName: "")
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
