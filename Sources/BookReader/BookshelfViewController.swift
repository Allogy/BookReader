//
//  BookshelfViewController.swift
//  BookReader
//
//  Created by Kishikawa Katsumi on 2017/07/03.
//  Copyright © 2017 Kishikawa Katsumi. All rights reserved.
//

import UIKit
@preconcurrency import PDFKit

extension Notification.Name {
    public static let documentDirectoryDidChange = Notification.Name("documentDirectoryDidChange")
}

@MainActor
public class BookshelfViewController: UITableViewController {
    var documents = [PDFDocument]()

    let thumbnailCache = NSCache<NSURL, UIImage>()
    private let downloadQueue = DispatchQueue(label: "com.kishikawakatsumi.pdfviewer.thumbnail")

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorInset.left = 56
        tableView.tableFooterView = UIView()
        refreshData()
        NotificationCenter.default.addObserver(self, selector: #selector(documentDirectoryDidChange(_:)), name: .documentDirectoryDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? BookViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            viewController.pdfDocument = documents[indexPath.row]
        }
    }

    override public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! BookshelfCell

        let document = documents[indexPath.row]
        if let documentAttributes = document.documentAttributes {
            if let title = documentAttributes["Title"] as? String {
                cell.title = title
            }
            if let author = documentAttributes["Author"] as? String {
                cell.author = author
            }
            if document.pageCount > 0 {
                if let page = document.page(at: 0), let key = document.documentURL as NSURL? {
                    cell.url = key

                    if let thumbnail = thumbnailCache.object(forKey: key) {
                        cell.thumbnail = thumbnail
                    } else {
                        // Generate thumbnail on background queue without capturing PDFPage
                        Task.detached(priority: .utility) { [weak self, weak cell] in
                            let thumbnail = page.thumbnail(of: CGSize(width: 40, height: 60), for: .cropBox)
                            await MainActor.run { [weak self, weak cell] in
                                self?.thumbnailCache.setObject(thumbnail, forKey: key)
                                if cell?.url == key {
                                    cell?.thumbnail = thumbnail
                                }
                            }
                        }
                    }
                }
            }
        }
        return cell
    }

    private func refreshData() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let contents = try! fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        documents = contents.compactMap { PDFDocument(url: $0) }

        tableView.reloadData()
    }

    @objc func documentDirectoryDidChange(_ notification: Notification) {
        refreshData()
    }
}
