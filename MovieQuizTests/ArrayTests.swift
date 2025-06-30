//
//  ArrayTests.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 23.06.2025.
//

import XCTest
@testable import MovieQuiz

final class ArrayTests: XCTestCase {

    func testSafeSubscript_withValidIndexes_returnsCorrectElements() {
        let numbers = [10, 20, 30]
        XCTAssertEqual(numbers[safe: 0], 10)
        XCTAssertEqual(numbers[safe: 1], 20)
        XCTAssertEqual(numbers[safe: 2], 30)
    }

    func testSafeSubscript_withNegativeIndex_returnsNil() {
        let array = ["a", "b", "c"]
        XCTAssertNil(array[safe: -1])
    }

    func testSafeSubscript_withIndexEqualToCount_returnsNil() {
        let array = ["a", "b", "c"]
        XCTAssertNil(array[safe: 3])
    }

    func testSafeSubscript_withTooLargeIndex_returnsNil() {
        let array = [1, 2, 3]
        XCTAssertNil(array[safe: 100])
    }
}

