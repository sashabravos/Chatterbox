//
//  NewChatCell.swift
//  Chatterbox
//
//  Created by Александра Кострова on 26.06.2023.
//

import UIKit

class NewChatCell: UITableViewCell {

    static let identifier = "NewChatCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - View Setup
    
    private func setupViews() {
                
        backgroundColor = .white
        
    
    }
}
