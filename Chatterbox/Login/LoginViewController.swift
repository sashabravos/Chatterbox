//
//  LoginViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FBSDKLoginKit
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 30, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.text = "Welcome to Chatterbox"
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email address..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        return textField
    }()
    
    private let passwordField: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .white
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let noAccountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.text = "Don't have an account?"
        return label
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
                        
        addLoginObserver()
        addButtonsConfig()
        viewConfig()

        // delegates
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = view.width/3
        
        titleLabel.frame = CGRect(x: 30,
                                  y: 20,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        imageView.frame = CGRect(x: (view.width - size)/2,
                                 y: titleLabel.bottom + 10,
                                 width: size,
                                 height: size)
        
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        noAccountLabel.frame = CGRect(x: 30,
                                   y: loginButton.bottom + 80,
                                   width: scrollView.width - 60,
                                   height: 52)
        
        signUpButton.frame = CGRect(x: 30,
                                   y: noAccountLabel.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
                
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: signUpButton.bottom + 10,
                                           width: scrollView.width - 60,
                                           height: 52)
        
        //without FB button
//        googleLogInButton.frame = CGRect(x: 30,
//                                         y: signUpButton.bottom + 10,
//                                         width: scrollView.width - 60,
//                                         height: 52)
        googleLogInButton.frame = CGRect(x: 30,
                                         y: facebookLoginButton.bottom + 10,
                                         width: scrollView.width - 60,
                                         height: 52)
        
    }
    
    private func addLoginObserver() {
        loginObserver = NotificationCenter.default.fb_addObserver(forName: .didLogInNotification,
                                                  object: nil,
                                                  queue: .main,
                                                  using: { [weak self] _ in

            guard let strongSelf = self else {
                return
            }

            strongSelf.navigationController?.dismiss(animated: true)
        })
    }
    
    private func addButtonsConfig() {
        signUpButton.addTarget(self,
                              action: #selector(didTapRegister),
                              for: .touchUpInside)
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        googleLogInButton.addTarget(self, action: #selector(googleSignInButtonTapped), for: .touchUpInside)
    }
    
    func viewConfig() {
        view.backgroundColor = .systemBackground
        //Add subviews
        //without FB button
//        view.addSubview(scrollView)
//        [titleLabel, imageView, emailField, passwordField, loginButton, noAccountLabel, signUpButton, googleLogInButton].forEach {
//            scrollView.addSubview($0)
//        }
        
        //Add subviews
        //With FB button
        view.addSubview(scrollView)
        [titleLabel, imageView, emailField, passwordField, loginButton, noAccountLabel, signUpButton, facebookLoginButton, googleLogInButton].forEach {
            scrollView.addSubview($0)
        }
    }
    
    @objc private func loginButtonTapped() {

        [emailField, passwordField].forEach {
            $0.resignFirstResponder()
        }

        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }

        showSpinner()

        AuthManager.shared.loginUser(withEmail: email, password: password) { [weak self] success in
            guard let strongSelf = self else {
                return
            }

            strongSelf.hideSpinner()

            if success {
                strongSelf.navigationController?.dismiss(animated: true)
            } else {
                print("Failed to log in user")
            }
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let registerVC = RegisterViewController()
        registerVC.title = "Create account"
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @objc private func googleSignInButtonTapped() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) {_,_ in
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                
                if let user = user, error == nil {
                    appDelegate.handleSessionRestore(user: user)
                }
            }
        }
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }

    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }

        let facebookRequest = GraphRequest(graphPath: "/me",
                                                parameters: ["fields": "id, first_name, last_name, picture{url}"], httpMethod: .get)

        facebookRequest.start(completion: {_, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }

            print(result)

            guard let firstName = result["first_name"] as? String,
                      let lastName = result["last_name"] as? String,
                      let email = result["email"] as? String,
                      let picture = result["picture"] as? [String: Any],
                      let data = picture["data"]  as? [String: Any],
                      let pictureURL = data["url"] as? String else {
                        print("Failed to get email and name from fb result")
                        return
                }

            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists {
                    let chatUser =  ChatterboxUser(firstName: firstName,
                                                                         lastName: lastName,
                                                                         emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {

                            guard let url = URL(string: pictureURL) else {
                                return
                            }

                            print ("Downloading data from facebook image")

                            URLSession.shared.dataTask(with: url) { data, _, error in
                                guard let data = data else {
                                    print ("Failed to get data from facebook")
                                    return
                                }
                                print("got data from FB, uploading...")

                                //upload image
                                let fileName = chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfilePicture(with: data,
                                                                           fileName: fileName) { result in
                                    switch result {
                                    case .success(let downloadURL):
                                        UserDefaults.standard.set(downloadURL, forKey: "profile_picture_url")
                                        print(downloadURL)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                }
                            } .resume()
                        }
                    }
                }
            })

            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }

                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed - \(error)")
                    }
                    return
                }
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true)
            })
        })
    }
}
