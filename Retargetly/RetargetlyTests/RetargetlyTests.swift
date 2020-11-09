//
//  RetargetlyTests.swift
//  RetargetlyTests
//
//  Created by José Valderrama on 09/11/2020.
//  Copyright © 2020 Retargetly. All rights reserved.
//

import XCTest
@testable import Retargetly

class RetargetlyTests: XCTestCase {

    func testInitiate() throws {
        let source_hash = "19N10-F&!Xazt"
        RManager.initiate(with: source_hash) { error in
            XCTAssertNil(error)
        }
    }

}
