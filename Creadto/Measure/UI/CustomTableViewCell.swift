//
//  CustomTableViewCell.swift
//  Creadto
//
//  Created by 이상진 on 2022/12/30.
//

import UIKit

class CustomTableViewCell : UITableViewCell {
    var measurementLabel : UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpCell()
        setUpLabel()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpLabel()
        setUpCell()
    }
    
    func setUpCell() {
        measurementLabel = UILabel()
        measurementLabel.backgroundColor = UIColor(hue: 1, saturation: 0, brightness: 0.81, alpha: 1.0) /* #cecece */
        measurementLabel.numberOfLines = 4
        contentView.addSubview(measurementLabel)
        
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        measurementLabel.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        measurementLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        measurementLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor).isActive = true
        measurementLabel.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
    }
    
    func setUpLabel() {
        measurementLabel.textColor = .blue
        measurementLabel.font = UIFont.systemFont(ofSize: 12)
        measurementLabel.textAlignment = .center
    }
}
