//
//  RetargetlyTests.swift
//  RetargetlyTests
//
//  Created by José Valderrama on 6/6/18.
//  Copyright © 2018 NextDots. All rights reserved.
//

import XCTest

class RetargetlyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let source_hash = "19N10-F&!Xazt"
        RManager.initiate(with: source_hash)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
