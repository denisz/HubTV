//
//  CollectionEpisodeView.swift
//  PiP
//
//  Created by denis zaytcev on 2/3/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Cocoa

class CollectionEpisodeView: NSCollectionView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        self.dataSource = self
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.dataSource = self
        self.delegate = self

    }
}


extension CollectionEpisodeView : NSCollectionViewDelegate {
    
}

extension CollectionEpisodeView: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 60
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: "EpisodeCellID", for: indexPath)
        guard let collectionViewItem = item as? EpisodeCell else {return item}
        
        return collectionViewItem
    }
}
