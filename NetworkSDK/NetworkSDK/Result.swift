//
//  Result.swift
//  NetworkSDK
//
//  Created by Fedor Soloviev on 12/09/2019.
//  Copyright © 2019 Fedor Solovev. All rights reserved.
//

import Foundation

public enum Result<Success, Failure> where Failure : Error {

    case success(Success)
    case failure(Failure)

}

extension Result {

    func flatMap<NewSuccess>(_ transform: (Success) -> Result<NewSuccess, Failure>) -> Result<NewSuccess, Failure> {
        switch self {
        case .success(let value):
            return transform(value)

        case .failure(let error):
            let error = error as NSError
            return .failure(NSError(domain: error.domain, code: error.code, userInfo: error.userInfo) as! Failure)
        }
    }
}
