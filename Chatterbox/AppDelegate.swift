//
//  AppDelegate.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FBSDKCoreKit
import GoogleSignIn

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    public var signInConfig: GIDConfiguration?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
//        // Facebook login
//        ApplicationDelegate.shared.application(
//            application,
//            didFinishLaunchingWithOptions: launchOptions
//        )

        GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in

            if let user = user, error == nil {
                self?.handleSessionRestore(user: user)
            }
        }
        
        if let clientId = FirebaseApp.app()?.options.clientID {
            signInConfig = GIDConfiguration.init(clientID: clientId)
        }
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        
//        ApplicationDelegate.shared.application(
//            app,
//            open: url,
//            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
//            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
//        )
        
        // google auth
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    func handleSessionRestore(user: GIDGoogleUser) {
        guard let email = user.profile?.email,
              let firstName = user.profile?.givenName,
              let lastName = user.profile?.familyName else {
            return
        }
        
        UserDefaults.standard.set(email, forKey: "email")
        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
        
        DatabaseManager.shared.userExists(with: email, completion: { exists in
            if !exists {
                
                // insert to database
                let chatUser = ChatAppUser(
                    firstName: firstName,
                    lastName: lastName,
                    emailAddress: email
                )
                DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                    if success {
                        
                        // upload image
                        if user.profile?.hasImage == true {
                            guard let url = user.profile?.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else {
                                    return
                                }
                                
                                let filename = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }) .resume()
                        }
                    }
                })
            }
        })
        
        guard let idToken = user.idToken else {
            return
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken.tokenString,
            accessToken: user.accessToken.tokenString
        )
        
        Auth.auth().signIn(with: credential, completion: { authResult, error in
            guard authResult != nil, error == nil else {
                print("failed to log in with google credential")
                return
            }
            
            print("Successfully signed in with Google cred.")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
        })
    }
}


