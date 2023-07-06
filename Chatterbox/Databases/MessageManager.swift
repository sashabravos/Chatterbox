//
//  MessageManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 05.07.2023.
//

import Foundation
import MessageKit
import FirebaseDatabase

final class MessageManager {
    
    static let shared = MessageManager()
    private let database = Database.database().reference()
    private let currentUserEmail: String
    
    private init() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            fatalError("Current user email not found in UserDefaults")
        }
        self.currentUserEmail = email
    }
}

extension MessageManager {
    
// MARK: - New conversation
    public func createNewConversation(name: String, with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            completion(false)
            return
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let ref = database.child(safeCurrentEmail)
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            if case let .text(messageText) = firstMessage.kind {
                message = messageText
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            let recipientConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeCurrentEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ]
            ]
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipientConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientConversationData])
                }
            })
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //append conversation if it exists
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
            } else {
                // create conversation if it doesn't exist
                userNode["conversations"] = [newConversationData]
            }
            
            ref.setValue(userNode) { [weak self] error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                self?.finishCreatingConversation(name: name,
                                                 conversationID: conversationID,
                                                 firstMessage: firstMessage,
                                                 completion: completion)
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        var messageContent = ""
        
        if case let .text(messageText) = firstMessage.kind {
            messageContent = messageText
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        let message: [String: Any] = [
            "name": name,
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messageContent,
            "date": dateString,
            "sender_mail": safeCurrentEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [
                message
            ]
        ]
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    // MARK: - Send message
    public func sendMessage(
        to conversation: String,
        otherUserEmail: String,
        name: String,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self,
                  var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: strongSelf.currentUserEmail)
            
            var messageContent = ""
            
            if case let .text(messageText) = message.kind {
                messageContent = messageText
            }
            
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            let newMessageEntry: [String: Any] = [
                "name": name,
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "content": messageContent,
                "date": dateString,
                "sender_mail": safeCurrentEmail,
                "is_read": false
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(safeCurrentEmail)/conversations").observeSingleEvent(of: .value) { _ in
                    // Perform any desired actions after sending the message
                }
            }
        })
    }
    
    // MARK: - Get all conversations
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        
        database.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date,
                                                        text: message,
                                                        isRead: isRead)
                return Conversation(id: conversationID,
                                    name: name,
                                    otherUserEmail: otherUserEmail,
                                    latestMessage: latestMessageObject)
            })
            completion(.success(conversations))
        }
    }
    
    // MARK: - Get all messages
    public func getAllMessagesForConversation(
        with conversationID: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        database.child("\(conversationID)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let messageID = dictionary["id"] as? String,
                      let type = dictionary["type"] as? String,
                      let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let senderEmail = dictionary["sender_mail"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    return nil
                }
                
                let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
                let path = "images/\(safeSenderEmail)_profile_picture.png"
                
                let sender = Sender(photoURL: path,
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            }
            
            completion(.success(messages))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "Failed to fetch data from the database"
            }
        }
    }
}
