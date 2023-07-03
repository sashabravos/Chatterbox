//
//  StorageManager.swift
//  Chatterbox
//
//  Created by Александра Кострова on 24.06.2023.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private init() {}

    private var storage = Storage.storage().reference()
    
    /*
     /images/user-gmail-com_profile_picture.png
     */

    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
            storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
                guard error == nil else {
                    print("Failed to upload data to Firebase for picture")
                    completion(.failure(StorageError.failedToUpload))
                    return
                }
                
                self.storage.child("images/\(fileName)").downloadURL { url, error in
                    guard let url = url else {
                        print("Failed to get download URL")
                        completion(.failure(StorageError.failedToGetDownloadURL))
                        return
                    }
                    
                    let urlString = url.absoluteString
                    print("Download URL returned: \(urlString)")
                    completion(.success(urlString))
                }
            }
        }
        
    public enum StorageError: Error {
        case failedToUpload
        case failedToGetDownloadURL
    }

    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToGetDownloadURL))
                return
            }
            completion(.success(url))
        }
    }
}
