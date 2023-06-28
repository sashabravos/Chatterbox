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
    public func uploadProfilePicture(with data: Data,
                                     fileName: String,
                                     completion: @escaping  UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, completion: { [weak self] metadata, error in

            guard let strongSelf = self else {
                return
            }

            guard error == nil else {
                // failed
                print ("failed to upload data to firebase for picture")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print ("Failed to get download url1")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
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
        case failedToGetDownloadUrl
    }

    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storage.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        }
    }
}
