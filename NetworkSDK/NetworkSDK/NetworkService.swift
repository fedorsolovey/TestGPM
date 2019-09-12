//
//  NetworkService.swift
//  testgpm
//
//  Created by Fedor Soloviev on 12/09/2019.
//  Copyright © 2019 Fedor Solovev. All rights reserved.
//

import Foundation

public final class NetworkService<S: Decodable, F: NSError>: NSObject, URLSessionTaskDelegate, URLSessionDataDelegate {

    private var defaultSession: URLSession {
        URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }
    private var query: [Int: QueryItem] = [:]

    public func load(by url: URL, completion: @escaping (Result<S, F>) -> Void) -> Int {
        let dataTask = defaultSession.dataTask(with: url)
        let hash = Int.random(in: 0...9999)

        query[hash] = QueryItem(dataTask: dataTask, completion: { (data, response, error) in
            if let error = error {
                completion(.failure(error as! F))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode), let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [:]) as! F))
                return
            }
            do {
                let decodedData = try JSONDecoder().decode(S.self, from: data)
                completion(.success(decodedData))
            } catch _ {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [:]) as! F))
            }
        })
        dataTask.resume()
        return hash
    }

    public func cancel(by hash: Int) {
        guard let dataTask = query[hash]?.dataTask else { return }
        dataTask.cancel()
    }

    // MARK: - URLSessionDelegates

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let item = query.first(where: { $1.dataTask == task }) else { return }

        DispatchQueue.main.async {
            self.query.removeValue(forKey: item.key)
            let queryItem = item.value
            queryItem.completion(queryItem.data, task.response, error)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let item = query.first(where: { $1.dataTask == dataTask }) else { return }

        DispatchQueue.main.async {
            item.value.data = data
        }
    }

    final class QueryItem {
        let dataTask: URLSessionDataTask
        let completion: (Data?, URLResponse?, Error?) -> Void
        var data: Data?

        init(dataTask: URLSessionDataTask, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
            self.dataTask = dataTask
            self.completion = completion
        }
    }
}

