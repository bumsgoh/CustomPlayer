//
//  ContainerPool.swift
//  MPEG-4Parser
//
//  Created by USER on 25/04/2019.
//  Copyright © 2019 bumslap. All rights reserved.
//

import Foundation

class ContainerPool {
    private var containerPool = [String: ContainerType]()
    init() {
        ContainerType.allCases.forEach {
            containerPool.updateValue($0, forKey: $0.rawValue)
        }
    }
    func pullOutContainer(with name: String) throws -> ContainerType {
        guard let container = containerPool[name] else {
            throw NSError(domain: "No container with input name", code: 0)
        }
        return container
    }
}
