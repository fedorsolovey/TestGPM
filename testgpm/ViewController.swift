//
//  ViewController.swift
//  testgpm
//
//  Created by Fedor Soloviev on 10/09/2019.
//  Copyright © 2019 Fedor Solovev. All rights reserved.
//

import UIKit
import NetworkSDK

final class ViewController: UIViewController {

    @IBOutlet private weak var startButton: UIBarButtonItem!
    @IBOutlet private weak var cancelButton: UIBarButtonItem!
    @IBOutlet private weak var tableView: UITableView!

    private let networkService = NetworkService<Post, NSError>()
    private var isRunning = false

    private var hashes: [Int] = []
    private var values: [Post] = []

    private var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        cancelButton.isEnabled = false

        title = "Hashes"
        
    }

    @IBAction func didTapOnStartButton(_ sender: UIBarButtonItem) {
        isRunning = true
        timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(makeRequest), userInfo: nil, repeats: true)

        startButton.isEnabled = false
        cancelButton.isEnabled = true
    }

    @IBAction func didTapOnCancelButton(_ sender: UIBarButtonItem) {
        isRunning = false
        timer?.invalidate()

        startButton.isEnabled = true
        cancelButton.isEnabled = false

        hashes.removeAll()
    }

    @objc private func makeRequest() {
        let i = Int.random(in: 0...100)
        let urlString = "https://jsonplaceholder.typicode.com/posts/" + String(i)
        guard let url = URL(string: urlString) else { return }

        let hash = self.networkService.load(by: url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let value):
                print(value)

            case .failure(let error):
                print(error)
                self.showAlert(message: error.localizedDescription)
            }
        }
        if hashes.count > 5 {
            hashes.removeFirst()
        }
        hashes.append(hash)
        tableView.reloadData()
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hashes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "UITableViewCell"
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: identifier)
        }
        cell.tag = hashes[indexPath.row]
        cell.textLabel?.text = String(hashes[indexPath.row])
        return cell
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        networkService.cancel(by: cell.tag)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Requests"
    }
}
