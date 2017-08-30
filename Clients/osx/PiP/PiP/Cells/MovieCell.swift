//
//  MovieCell.swift
//  PiP
//
//  Created by denis zaytcev on 2/9/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa

class MovieCell: NSCollectionViewItem {
    @IBOutlet weak var picture: DKAsyncImageView!
    @IBOutlet weak var rating: NSTextField!
    @IBOutlet weak var year: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.wantsLayer = true
        rating.layer?.zPosition = 1
    }
}
