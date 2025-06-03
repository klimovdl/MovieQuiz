//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 02.06.2025.
//

import Foundation

struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
