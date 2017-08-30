//
//  Int+seconds.swift
//  PiP
//
//  Created by denis zaytcev on 2/10/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation


extension Int {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}

extension Int32 {
    var msToSeconds: Double {
        return Double(self) / 1000
    }
}
