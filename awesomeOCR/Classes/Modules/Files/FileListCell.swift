//
//  FileListCell.swift
//  awesomeOCR
//
//  Created by maRk'sTheme on 2019/7/1.
//  Copyright © 2019 maRk. All rights reserved.
//

import UIKit

class FileListCell: UITableViewCell {

    @IBOutlet weak var icon: UIView!

    @IBOutlet weak var titleLabel: UILabel!

    @IBOutlet weak var timeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
