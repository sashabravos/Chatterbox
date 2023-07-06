//
//  NewChatCell.swift
//  Chatterbox
//
//  Created by Александра Кострова on 26.06.2023.
//

import UIKit
import SDWebImage

class NewConversation: UITableViewCell {

    static let identifier = "NewChatCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 35
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        userImageView.frame = CGRect(x: 10,
                                     y: 10,
                                     width: 70,
                                     height: 70)

        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 20,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: 50)
    }

//    public func configure() {
//        userNameLabel.text = "Username"
//        userImageView.image = UIImage(systemName: "cloud")

//        let path = "images/\(model.email)_profile_picture.png"
//        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
//            switch result {
//            case .success(let url):
//
//                DispatchQueue.main.async {
//                    self?.userImageView.sd_setImage(with: url, completed: nil)
//                }
//
//            case .failure(let error):
//                print("failed to get image url2: \(error)")
//            }
//        })
//    }
    public func configure(username: String, email: String) {
        userNameLabel.text = username

        let path = "images/\(email)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):

                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }

            case .failure(let error):
                self?.userImageView.image = UIImage(systemName: "person.fill")
                //print("failed to get image url for NewConversationCell: \(error)")
            }
        })
    }
}




