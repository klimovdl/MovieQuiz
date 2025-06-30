//
//  Array+SafeSubscript.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 29.06.2025.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else { return nil }
        return self[index]
    }
}
