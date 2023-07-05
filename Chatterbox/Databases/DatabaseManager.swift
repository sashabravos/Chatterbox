//
//  DatabaseManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 22.06.2023.
//

import Foundation
import FirebaseDatabase

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
    
    // MARK: - Data Retrieval
    
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
    
    // MARK: - Account Management
    
    /// Check if a user with the given email already exists
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            let userExists = snapshot.value as? [String: Any] != nil
            completion(userExists)
        }
    }
    
    /// Inserts a new user to the database
    public func insertUser(with user: ChatterboxUser, completion: @escaping (Bool) -> Void ) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ]) { [weak self] error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self?.addUserToCollection(user: user, completion: completion)
        }
    }
    
    private func addUserToCollection(user: ChatterboxUser, completion: @escaping (Bool) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { [weak self] snapshot in
            var usersCollection = snapshot.value as? [[String: String]] ?? []
            
            let newElement = [
                "name": user.firstName + " " + user.lastName,
                "email": user.safeEmail
            ]
            usersCollection.append(newElement)
            
            self?.database.child("users").setValue(usersCollection) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                completion(true)
            }
        }
    }
    
    // Gets all users from the database
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let usersDictionary = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            completion(.success(usersDictionary))
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
