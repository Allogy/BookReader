//
//  ThumbnailGridCell.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit

public class ThumbnailGridCell: UICollectionViewCell {
    override public var isHighlighted: Bool {
        didSet {
            imageView.alpha = isHighlighted ? 0.8 : 1
        }
    }
    var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }
    var pageNumber = 0 {
        didSet {
            pageNumberLabel.text = " \(String(pageNumber + 1)) "
            pageNumberLabel.isHidden = false
        }
    }
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var pageNumberLabel: UILabel!

    override public func awakeFromNib() {
        super.awakeFromNib()
        pageNumberLabel.isHidden = true
        self.imageView.layer.borderColor = UIColor.systemFill.cgColor
        self.imageView.layer.borderWidth = 1.0
    }

    override public func prepareForReuse() {
        imageView.image = nil
    }
}
