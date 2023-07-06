//
//  AuthManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 29.06.2023.
//

import Foundation
import FirebaseAuth

final class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {}
    
    var currentUserEmail: String? {
        return Auth.auth().currentUser?.email
    }
    
    // Firebase Sign Up
    func registerUser(firstName: String, lastName: String, email: String, password: String, image: UIImage?, completion: @escaping (Bool) -> Void) {

        DatabaseManager.shared.userExists(with: email) { exists in
                guard !exists else {
                    // User already exists
                    completion(false)
                    return
                }
                
                Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                    if let error = error, authResult != nil {
                        print("Error creating user:", error.localizedDescription)
                        completion(false)
                        return
                    }
                    
                    UserDefaults.standard.setValue(email, forKey: "email")
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                    
                    let chatUser = ChatterboxUser(firstName: firstName, lastName: lastName, emailAddress: email)
                    
                    self.addUserToDatabase(chatUser: chatUser) { success in
                        if success {
                            if let image = image {
                                self.uploadProfilePicture(image: image, chatUser: chatUser) { result in
                                    switch result {
                                    case .success(let downloadURLString):
                                        UserDefaults.standard.set(downloadURLString, forKey: "profile_picture_url")
                                        print(downloadURLString)
                                        completion(true)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                        completion(false)
                                    }
                                }
                            } else {
                                completion(true)
                            }
                        } else {
                            completion(false)
                        }
                    }
                }
            }
        }
        
    // Firebase login
    func loginUser(withEmail email: String, password: String, completion: @escaping (Bool) -> Void) {
            Auth.auth().signIn(withEmail: email, password: password) { authResult, error in

                guard let result = authResult, error == nil else {
                                print("Failed to log in user with email: \(email)")
                                        completion(false)
                                return
                            }
                
                let user = result.user
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                           DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                               switch result {
                               case .success(let data):
                                   guard let userData = data as? [String: Any],
                                       let firstName = userData["first_name"] as? String,
                                       let lastName = userData["last_name"] as? String else {
                                           return
                                   }
                                   UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

                               case .failure(let error):
                                   print("Failed to read data with error \(error)")
                               }
                           })

                                UserDefaults.standard.set(email, forKey: "email")

                print("Logged user: \(user)")
                completion(true)
            }
        }
    
    // Firebase logout
    func logoutUser(completion: @escaping (Bool) -> Void) {
        do {
            try Auth.auth().signOut()
            completion(true)
        } catch {
            print("Failed to log out")
            completion(false)
        }
    }
}

// MARK: - Error extension
extension AuthManager {
    public enum AuthError: Error {
        case invalidImage
    }
}

// MARK: - Support Methods
extension AuthManager {
    private func uploadProfilePicture(image: UIImage, chatUser: ChatterboxUser, completion: @escaping (Result<String, Error>) -> Void) {
        guard let data = image.pngData() else {
            completion(.failure(AuthError.invalidImage))
            return
        }
        
        let fileName = chatUser.profilePictureFileName
        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
            switch result {
            case .success(let downloadURLString):
                completion(.success(downloadURLString))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func addUserToDatabase(chatUser: ChatterboxUser, completion: @escaping (Bool) -> Void) {
        DatabaseManager.shared.insertUser(with: chatUser) { success in
            completion(success)
        }
    }
}
