//
//  ProfileCell.swift
//  Chatterbox
//
//  Created by Александра Кострова on 22.06.2023.
//

import UIKit

final class ProfileCell: UITableViewCell {
    
    static let identifier = "ProfileCell"
    
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

