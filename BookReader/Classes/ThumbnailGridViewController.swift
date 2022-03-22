//
//  ThumbnailGridViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

public class ThumbnailGridViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var pdfDocument: PDFDocument?
    weak var delegate: ThumbnailGridViewControllerDelegate?

    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")
    let thumbnailCache = NSCache<NSNumber, UIImage>()

    func cellSize(for indexPath: IndexPath) -> CGSize {
        if let collectionView = collectionView,
            let page = pdfDocument?.page(at: indexPath.item) {
            var width = collectionView.frame.width
            var height = collectionView.frame.height
            if width > height {
                swap(&width, &height)
            }
            
            let size = page.bounds(for: .cropBox)
            
            width = (width - 80) / 3
            height = (width / size.width) * size.height
            
            return CGSize(width: width, height: height)
        }
        return .zero
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        let backgroundView = UIView()
        collectionView?.backgroundView = backgroundView
        
        let bundle = Bundle.bookReader
        collectionView?.register(UINib(nibName: String(describing: ThumbnailGridCell.self), bundle: bundle), forCellWithReuseIdentifier: "Cell")
    }

    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pdfDocument?.pageCount ?? 0
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ThumbnailGridCell

        if let page = pdfDocument?.page(at: indexPath.item) {
            let pageNumber = indexPath.item
            cell.pageNumber = pageNumber

            let key = NSNumber(value: pageNumber)
            if let thumbnail = thumbnailCache.object(forKey: key) {
                cell.image = thumbnail
            } else {
                let size = cellSize(for: indexPath)
                downloadQueue.async { [weak self] in
                    let thumbnail = page.thumbnail(of: size, for: .cropBox)
                    self?.thumbnailCache.setObject(thumbnail, forKey: key)
                    if cell.pageNumber == pageNumber {
                        DispatchQueue.main.async {
                            cell.image = thumbnail
                        }
                    }
                }
            }
        }

        return cell
    }

    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let page = pdfDocument?.page(at: indexPath.item) {
            delegate?.thumbnailGridViewController(self, didSelectPage: page)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.cellSize(for: indexPath)
    }
}

protocol ThumbnailGridViewControllerDelegate: AnyObject {
    func thumbnailGridViewController(_ thumbnailGridViewController: ThumbnailGridViewController, didSelectPage page: PDFPage)
}
