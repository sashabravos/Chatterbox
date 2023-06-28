//
//  ProfileViewController.swift
//  Chatterbox
//
//  Created by Александра Кострова on 21.06.2023.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import SDWebImage

class ProfileViewController: UIViewController {

    var data = [ProfileViewModel]()
    
    let tableView = UITableView()
    
    var profilePicture: UIImageView = {
            let picture = UIImageView()
            picture.contentMode = .scaleAspectFill
            picture.backgroundColor = .white
            picture.layer.borderColor = UIColor.white.cgColor
            picture.layer.borderWidth = 3
            picture.layer.masksToBounds = true
            picture.layer.cornerRadius = 125
            return picture
        }()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        title = "Profile"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupTableView()
        configProfileModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.frame = view.bounds
        
        profilePicture.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profilePicture.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            profilePicture.heightAnchor.constraint(equalToConstant: 250),
            profilePicture.widthAnchor.constraint(equalToConstant: 250),
            profilePicture.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 20)
        ])
    }

    func createTableViewHeader() -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.addSubview(profilePicture)
        headerView.backgroundColor = UIColor(patternImage: setUserImage()).withAlphaComponent(0.1)
                
        return headerView
    }
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableViewHeader()
        tableView.register(ProfileCell.self, forCellReuseIdentifier: ProfileCell.identifier)
        
        view.addSubview(tableView)
        tableView.reloadData()
    }
    
    func setUserImage() -> UIImage {
        let defaultImage = UIImage(systemName: "person")!
        // download userProfile image from Storage
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return defaultImage
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result {
            case .success(let url):
                self.profilePicture.sd_setImage(with: url, completed: nil)
            case .failure(let error):
                print("Failed to get download url ProfilePicture: \(error)")
            }
        })
        return defaultImage
    }
    
    func configProfileModel() {
        data.append(ProfileViewModel(viewModelType: .changeAvatar,
                                     title: "Change the avatar",
                                     handler: { [weak self] in
            self?.presentPhotoActionSheet()
        }))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name: \(UserDefaults.standard.value(forKey:"name") as? String ?? "Unknown")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email: \(UserDefaults.standard.value(forKey:"email") as? String ?? "Unknown")",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .logout, title: "Log Out", handler: { [weak self] in
            
            guard let strongSelf = self else {
                return
            }
            
            let actionSheet = UIAlertController(title: "",
                                                message: "",
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Log Out",
                                                style: .destructive,
                                                handler: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                // Log Out facebook
//                FBSDKLoginKit.LoginManager().logOut()
                
                // Google Log out
                GIDSignIn.sharedInstance.signOut()
                
                do {
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    let logVC = LoginViewController()
                    let navVC = UINavigationController(rootViewController: logVC)
                    
                    navVC.modalPresentationStyle = .fullScreen
                    strongSelf.present(navVC, animated: true)
                }
                catch {
                    print("Failed to log out")
                }
                
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel",
                                                style: .cancel,
                                                handler: nil))
            
            strongSelf.present(actionSheet, animated: true)
        }))
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileCell.identifier,
                                                 for: indexPath) as! ProfileCell
        cell.setUp(with: viewModel)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }

}

extension ProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "Profile picture",
                                            message: "How would you like select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentCamera()

        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoPicker()

        }))

        present(actionSheet, animated: true)
    }

    func presentCamera() {
        let pickerVC = UIImagePickerController()
        pickerVC.sourceType = .camera
        pickerVC.delegate = self
        pickerVC.allowsEditing = true
        present(pickerVC, animated: true)
    }

    func presentPhotoPicker() {
        let pickerVC = UIImagePickerController()
        pickerVC.sourceType = .photoLibrary
        pickerVC.delegate = self
        pickerVC.allowsEditing = true
        present(pickerVC, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }

        self.profilePicture.image = selectedImage

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

