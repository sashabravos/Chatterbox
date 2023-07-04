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
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        let ref = database.child("\(safeCurrentEmail)")
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ] as [String : Any]
            ]
            
            let recipientConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeCurrentEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                ] as [String : Any]
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
                //append conversation if it's exist
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)                    }
                
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
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationID,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
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
    
    
    public func getAllConversations(for email: String, completion: @escaping (Result <[Conversation], Error>) -> Void) {
        
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
    
    public func sendMessage(
        to conversation: String,
        otherUserEmail: String,
        name: String,
        message: Message,
        completion: @escaping (Bool) -> Void
    ) {
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
            
            var messageContent = ""
            
            switch message.kind {
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
                
                strongSelf.database.child("\(safeCurrentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in

                })
            }
        })
    }
    
    public func getAllMessagesForConversation(
        with conversationID: String,
        completion: @escaping (Result<[Message], Error>) -> Void
    ) {
        
        database.child("\(conversationID)/messages").observe(.value, with: { snapshot  in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
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
                
                let path = "images/\(senderEmail)_profile_picture.png"
                //                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                //                    switch result {
                //                    case .success(let url):
                //
                //                        DispatchQueue.main.async {
                //                            self?.userImageView.sd_setImage(with: url, completed: nil)
                //                        }
                //
                //                    case .failure(let error):
                //                        self?.userImageView.image = UIImage(systemName: "person.fill")
                //                        print("failed to get image url for DatabaseManager: \(error)")
                //                    }
                //                })
                
                let sender = Sender(photoURL: path,
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: .text(content))
            })
            completion(.success(messages))
        })
    }
}
