//
//  ConversationCell.swift
//  Chatterbox
//
//  Created by Александра Кострова on 27.06.2023.
//

import UIKit
import SDWebImage

class ConversationCell: UITableViewCell {

    static let identifier = "ConversationCell"

    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 45
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()

    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private let messageTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()
    
    private let onlineStatusPoint: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "circle.fill")?
            .withTintColor( .systemGreen, renderingMode: .alwaysOriginal)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        imageView.layer.masksToBounds = true
        return imageView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [userImageView, userNameLabel, userMessageLabel, messageTimeLabel, onlineStatusPoint].forEach {
            contentView.addSubview($0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        userImageView.frame = CGRect(x: 10,
                                     y: 8,
                                     width: 90,
                                     height: 90)

        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height-20)/2)

        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: userNameLabel.bottom + 10,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: (contentView.height-20)/2)
        
        messageTimeLabel.frame = CGRect(x: contentView.frame.width - messageTimeLabel.frame.width - 20,
                                        y: 0,
                                        width: 150,
                                        height: 50)
        
        onlineStatusPoint.frame = CGRect(x: 80,
                                        y: 78,
                                        width: 20,
                                        height: 20)

    }

    public func configure(with conversationModel: Conversation) {

        contentView.backgroundColor = conversationModel.latestMessage.isRead ? UIColor.systemBackground : UIColor.systemBackground.withAlphaComponent(0.5)
//        onlineStatusPoint.isHidden = !isOnline
        userNameLabel.text = conversationModel.name
        userMessageLabel.text = conversationModel.latestMessage.text
        messageTimeLabel.text = conversationModel.latestMessage.date

        let path = "images/\(conversationModel.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url):

                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }

            case .failure(let error):
                self?.userImageView.image = UIImage(systemName: "person.fill")
                //print("failed to get image url for ConversationCell: \(error)")
            }
        })
    }
}
