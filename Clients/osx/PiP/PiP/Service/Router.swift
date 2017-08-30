//
//  Router.swift
//  PiP
//
//  Created by denis zaytcev on 2/10/17.
//  Copyright © 2017 denis zaytcev. All rights reserved.
//

import Foundation
import Alamofire


enum Router: URLRequestConvertible {
    static let baseURLString = "http://localhost:8080"
    
    case listMovies(String, Int)
    case start(String, String)
    case stream(String)
    case stop
    case file
    case status
    case subtitles
    
    var method: Alamofire.HTTPMethod {
        return .post
    }
    
    var path: String {
        switch self {
        case .listMovies:
            return "/search"
        case .start:
            return "/start"
        case .stream:
            return "/stream"
        case .stop:
            return "/stop"
        case .file:
            return "/file"
        case .status:
            return "/status"
        case .subtitles:
            return "/subtitles"
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = URL(string: Router.baseURLString)!
        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue
        
        switch self {
        case .listMovies(let keywords, let page):
            return try Alamofire.URLEncoding.httpBody.encode(urlRequest, with:
                ["keywords": keywords, "page": page])
        case .start(let quality, let movieId):
            return try Alamofire.URLEncoding.httpBody.encode(urlRequest, with:
                ["id": movieId, "quality": quality])
        case .stream(let link):
            return try Alamofire.URLEncoding.httpBody.encode(urlRequest, with:["link": link])
        default:
            return urlRequest
        }
    }
}
