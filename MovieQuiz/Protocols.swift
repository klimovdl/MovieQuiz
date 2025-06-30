//
//  Protocols.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 30.06.2025.
//

import Foundation

protocol QuestionFactoryProtocol: AnyObject {
    var totalQuestionsCount: Int { get }
    func loadData()
    func requestNextQuestion()
    func reset()
}

protocol QuestionFactoryDelegate: AnyObject {
    func didLoadDataFromServer()
    func didReceiveNextQuestion(question: QuizQuestion?)
    func didFailToLoadData(with error: Error)
}
