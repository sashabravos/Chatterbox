//
//  ContactCell.swift
//  Chatterbox
//
//  Created by Александра Кострова on 28.06.2023.
//

import UIKit
import SDWebImage

class ContactCell: UITableViewCell {

    static let identifier = "ContactCell"

    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 25
        imageView.layer.masksToBounds = true
        imageView.tintColor = .darkGray
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

        userImageView.frame = CGRect(x: 25,
                                     y: 25,
                                     width: 50,
                                     height: 50)

        userNameLabel.frame = CGRect(x: userImageView.right + 20,
                                     y: 40,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height-20)/2)
    }

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
                //print("failed to get image url for ContactCell: \(error)")
            }
        })
    }
}
