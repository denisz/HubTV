//
//  QueryController.swift
//  PiP
//
//  Created by denis zaytcev on 2/2/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation
import BoltsSwift

public protocol QueryControllerDelegate {
//    func queryForData(_ query: QueryController) -> Task<URL>
//    func queryObjectsWillLoad(_ query: QueryController, page: Int, clear: Bool) -> Task<Bool>
//    func queryObjectsDidLoad(_ query: QueryController, error: Error?)
//    func queryObjectsDidAppend(_ query: QueryController, objects: [PFObject])
//    func queryObjectsWillAppend(_ query: QueryController, objects: [PFObject]) -> QueryTaskResult?
//    func queryObjectsDidAppendDelta(_ query: QueryController, oldObjects: [PFObject], newObjects: [PFObject])
//    func loadObjects(_ page: Int, clear: Bool)-> QueryTaskResult?
}

public class QueryController<T> {
    public var delegate: QueryControllerDelegate?
    
    var objects: [T] = []
    
    public func numberOfRows() -> Int {
        return self.objects.count
    }
    
//    public func objectAtIndexPath(_ indexPath: IndexPath) -> MovieModel? {
//    }
//    
//    func loadObjects(_ page: Int, clear: Bool) -> QueryTaskResult {
//    }
//    
//    func loadObjects() -> Task<[T]> {
//    }
//    
//    func loadNextPage() -> Task<[T]> {
//    }
}
