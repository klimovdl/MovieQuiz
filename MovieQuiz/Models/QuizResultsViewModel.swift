//
//  QuizResultsViewModel.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 01.06.2025.
//

import Foundation

struct QuizResultsViewModel {
    let title: String
    let text: String
    let buttonText: String
    let completion: () -> Void

    init(
        title: String,
        text: String,
        buttonText: String,
        completion: @escaping () -> Void
    ) {
        self.title      = title
        self.text       = text
        self.buttonText = buttonText
        self.completion = completion
    }
}

