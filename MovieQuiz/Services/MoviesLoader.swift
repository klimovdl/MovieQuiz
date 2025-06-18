//
//  MoviesLoader.swift
//  MovieQuiz
//
//  Created by Danil Klimov on 17.06.2025.
//

import Foundation

protocol MoviesLoading {
    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void)
}

struct MoviesLoader: MoviesLoading {
    private let networkClient = NetworkClient()

    private var mostPopularMoviesUrl: URL {
        guard let url = URL(string: "https://tv-api.com/en/API/Top250Movies/k_zcuw1ytf") else {
            preconditionFailure("Unable to construct mostPopularMoviesUrl")
        }
        return url
    }

    func loadMovies(handler: @escaping (Result<MostPopularMovies, Error>) -> Void) {
        print("➡️ Fetching JSON from:", mostPopularMoviesUrl)
        networkClient.fetch(url: mostPopularMoviesUrl) { result in
            switch result {
            case .success(let data):
                print("✅ Got data:", data.count, "bytes")
                do {
                    let mostPopularMovies = try JSONDecoder().decode(MostPopularMovies.self, from: data)
                    print("✅ Decoded items count:", mostPopularMovies.items.count)
                    handler(.success(mostPopularMovies))
                } catch {
                    print("❌ JSON decode error:", error)
                    handler(.failure(error))
                }
            case .failure(let error):
                print("❌ Network error:", error)
                handler(.failure(error))
            }
        }
    }
}

