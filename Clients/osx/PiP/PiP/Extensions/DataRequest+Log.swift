//
//  DataRequest+Log.swift
//  PiP
//
//  Created by denis zaytcev on 2/9/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation
import Alamofire



extension DataRequest {
    public func LogRequest() -> Self {
        print(self)
        return self
    }
}
