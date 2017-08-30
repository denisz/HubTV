//
//  MainViewController.swift
//  PiP
//
//  Created by denis zaytcev on 1/31/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa
import PIPContainer
import Alamofire
import SwiftyJSON

class MySearchField: NSSearchField {
}

class MySplitView: NSSplitView {
    override var dividerThickness:CGFloat
        {
        get { return 0.0 }
    }
}

class MainViewController: NSViewController {
    @IBOutlet weak var clipView: NSScrollView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSCollectionView!
    @IBOutlet weak var textField: MySearchField!
    @IBOutlet weak var splitView: MySplitView!
    @IBOutlet weak var movieView: MovieView!
    
    
    var movies: [JSON]?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let flowLayout = NSCollectionViewFlowLayout()
//        flowLayout.itemSize = NSSize(width: 134, height: 200.0)
        flowLayout.itemSize = NSSize(width: 167, height: 245)
        flowLayout.sectionInset = EdgeInsets(top: 10.0, left: 20.0, bottom: 20.0, right: 30.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 30.0
        
        self.tableView.collectionViewLayout = flowLayout
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.wantsLayer = true
        self.scrollView.wantsLayer = true
        self.clipView.wantsLayer = true
        self.tableView.backgroundColors = [NSColor(red:0.12, green:0.12, blue:0.12, alpha:0.00)]

        
        self.textField.wantsLayer = true
        self.textField.drawsBackground = true
        self.textField.delegate = self
        self.textField.sendsWholeSearchString = false
        self.textField.sendsSearchStringImmediately = true
        
        self.splitView.delegate = self
    }
    
    func objectAtRow (_ row: Int) -> JSON? {
        if let movies = self.movies {
            return movies[row]
        }
        
        return nil
    }
    
    func objectAtIndexPath(_ indexPath: IndexPath) -> JSON? {
        return self.objectAtRow(indexPath.item)
    }
}

extension MainViewController: NSCollectionViewDataSource, NSCollectionViewDelegate {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movies = self.movies {
            return movies.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first,
            let data = self.objectAtIndexPath(indexPath) else {
            return
        }
        
        self.movieView.LoadMovie(data, torrent: nil)
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: "MovieCell", for: indexPath)
        guard let collectionViewItem = item as? MovieCell else {
            return item
        }
        
        if let data = self.objectAtIndexPath(indexPath) {
            collectionViewItem.picture.downloadImageFromURL(
                data["Poster"].stringValue,
                placeHolderImage: nil,
                errorImage: nil,
                usesSpinningWheel: false)
            
            collectionViewItem.rating.stringValue   = data["Rating"].stringValue
            collectionViewItem.year.stringValue     = data["Year"].stringValue
            collectionViewItem.textField?.stringValue    = data["Title"].stringValue
        }
        
        return collectionViewItem
    }
}

extension MainViewController : NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, shouldHideDividerAt dividerIndex: Int) -> Bool {
        return true
    }
    
    func splitView(_ splitView: NSSplitView, additionalEffectiveRectOfDividerAt dividerIndex: Int) -> NSRect {
        return NSRect.init()
    }
    
    func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect, forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        return NSRect.init()
    }
}

extension MainViewController: NSSearchFieldDelegate {
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        return true
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let keywords = self.textField.stringValue
        
        Alamofire.request(Router.listMovies(keywords, 0))
            .LogRequest()
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    self.movies = json["Movies"].arrayValue
                    self.tableView.reloadData()
                case .failure(let error):
                    Swift.print(error)
                }
        }

    }
    
}
