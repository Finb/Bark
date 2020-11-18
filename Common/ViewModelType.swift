//
//  ViewModelType.swift
//  Bark
//
//  Created by huangfeng on 2020/11/17.
//  Copyright © 2020 Fin. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewModelType {
    associatedtype Input
    associatedtype Output

    func transform(input: Input) -> Output
}

class ViewModel:NSObject{ }
