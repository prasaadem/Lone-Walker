//
//  DistanceInfoTableViewCell.swift
//  Lone Walker
//
//  Created by Aditya Emani on 9/19/17.
//  Copyright © 2017 Aditya Emani. All rights reserved.
//

import UIKit

class DistanceInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!
    @IBOutlet weak var precipitationLabel: UILabel!
    @IBOutlet weak var windLabel: UILabel!
    @IBOutlet weak var climateLabel: UILabel!
    @IBOutlet weak var climateImageView: UIImageView!
    @IBOutlet weak var expectedArrivalDay: UILabel!
    @IBOutlet weak var expectedArrivalTime: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
