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
    
    private var storage = Storage.storage().reference()
    
    /*
     /images/z
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping  UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, completion: {metadata, error in
            guard error == nil else {
                // failed
                print ("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print ("Failed to get download url")
                    completion(.failure(StorageError.failToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("downloads url returned: \(urlString)")
                completion(.success(urlString))
            }
            
        })
    }
    
    public enum StorageError: Error {
        case failedToUpload
        case failToGetDownloadUrl
    }
}
