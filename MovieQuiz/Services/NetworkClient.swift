//
//  NetworkClient.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 17.06.2025.
//

import Foundation

final class NetworkClient {
    func fetch(url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "MissingData", code: 0)))
                return
            }
            completion(.success(data))
        }
        task.resume()   // ← Обязательно должен быть!
    }
}
