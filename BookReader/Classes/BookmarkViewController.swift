//
//  BookmarkViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
import PDFKit

public class BookmarkViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var pdfDocument: PDFDocument?
    var bookmarks = [Int]()

    weak var delegate: BookmarkViewControllerDelegate?

    let thumbnailCache = NSCache<NSNumber, UIImage>()
    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")

    func cellSize(for indexPath: IndexPath) -> CGSize {
        let pageNumber = bookmarks[indexPath.item]

        if let collectionView = collectionView,
            let page = pdfDocument?.page(at: pageNumber) {
            var width = collectionView.frame.width
            var height = collectionView.frame.height
            if width > height {
                swap(&width, &height)
            }
            
            let size = page.bounds(for: .cropBox)
            
            width = (width - 40 - 40) / 3
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

        NotificationCenter.default.addObserver(self, selector: #selector(userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: nil)
        refreshData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bookmarks.count
    }

    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ThumbnailGridCell

        let pageNumber = bookmarks[indexPath.item]
        if let page = pdfDocument?.page(at: pageNumber) {
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
        if let page = pdfDocument?.page(at: bookmarks[indexPath.item]) {
            delegate?.bookmarkViewController(self, didSelectPage: page)
        }
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cellSize(for: indexPath)
    }

    private func refreshData() {
        if let documentURL = pdfDocument?.documentURL?.absoluteString,
            let bookmarks = UserDefaults.standard.array(forKey: documentURL) as? [Int] {
            self.bookmarks = bookmarks
            collectionView?.reloadData()
        }
    }

    @objc func userDefaultsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.refreshData()
        }
    }
}

protocol BookmarkViewControllerDelegate: AnyObject {
    func bookmarkViewController(_ bookmarkViewController: BookmarkViewController, didSelectPage page: PDFPage)
}
