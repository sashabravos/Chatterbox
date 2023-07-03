//
//  DatabaseManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 22.06.2023.
//

import Foundation
import FirebaseDatabase
import MessageKit

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    private init() {}
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    
    /// Returns dictionary node at child path
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK: - Account Management

extension DatabaseManager {
    
    /// if user already exists
    public func userExists(with email: String,
                           completion: @escaping ((Bool) -> Void)) {
        
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    /// Inserts new user to the database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void ) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.addUserToCollection(user: user) { success in
                completion(success)
            }
        }
    }
    
    private func addUserToCollection(user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            if var usersCollection = snapshot.value as? [[String: String]] {
                // Append to user dictionary
                let newElement = [
                    "name": user.firstName + " " + user.lastName,
                    "email": user.safeEmail
                ]
                usersCollection.append(newElement)
                
                self.database.child("users").setValue(usersCollection) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                }
            } else {
                // Create new collection
                let newCollection: [[String: String]] = [
                    [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                ]
                
                self.database.child("users").setValue(newCollection) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                }
            }
        }
    }
    
    // Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let usersDictionary = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(usersDictionary))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        
        public var localizedDescription: String {
            switch self {
            case .failedToFetch:
                return "This means blah failed"
            }
        }
    }
}

// MARK: - MessageKit

extension DatabaseManager {
    
    public func createNewConversation(name: String, with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    "name": name
                ]
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //append conversation if it's exist
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID,
                                                     firstMessage: firstMessage, completion: completion)                    }
                
            } else {
                // created conversation if it isn't exist
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID,
                                                     firstMessage: firstMessage, completion: completion)
                }
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        //        {
        //            "id": conversationID,
        //            "other_user_email": otherUserEmail,
        //            "latest_message": [
        //                "date": dateString,
        //                "is_read": false,
        //                "message": message
        //        }
        var messageContent = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            messageContent = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        let message: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": messageContent,
            "date": dateString,
            "sender_mail": safeEmail,
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
    
    
    public func getAllConversations(for email: String, completion: @escaping (Result <String, Error>) -> Void) {
        
    }
    
    
    public func sendMessage(
        to conversation: String,
        //        to recipientEmail: String,
        //        sender: Sender,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        
    }
    
    public func getAllMessagesForConversation(
        with conversationID: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value) { snapshot in
            guard let messagesData = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var messages: [Message] = []
            
            for messageData in messagesData {
                if let message = self.parseMessage(from: messageData) {
                    messages.append(message)
                }
            }
            
            completion(.success(messages))
        }
    }
    
    private func parseMessage(from messageData: [String: Any]) -> Message? {
        guard let messageId = messageData["id"] as? String,
              let messageTypeString = messageData["type"] as? String,
              let senderData = messageData["sender"] as? [String: Any],
              let senderId = senderData["senderId"] as? String,
              let senderName = senderData["displayName"] as? String,
              let sentDateTimestamp = messageData["sentDate"] as? TimeInterval
        else {
            return nil
        }
        
        let messageType = MessageKind.text(messageTypeString)
        let sender = Sender(photoURL: "https://img.stereo.ru/v3/news/2019/10/5eaff2b10dfdb20b3f73f15667dcd6e6.jpg", senderId: senderId, displayName: senderName)
        let sentDate = Date(timeIntervalSince1970: sentDateTimestamp)
        
        return Message(
            sender: sender, messageId: messageId,
            sentDate: sentDate, kind: .text("Test text")
        )
    }
}


