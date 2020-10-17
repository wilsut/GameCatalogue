//
//  ViewController.swift
//  GameCatalogue
//
//  Created by William Sutanto on 10/07/20.
//  Copyright © 2020 William Sutanto. All rights reserved.
//

import UIKit

let pageSize = "10"
var components = URLComponents(string: "https://api.rawg.io/api/games")!

enum DownloadState {
    case new, downloaded, failed
}

struct Games: Codable {
    let count: Int
    let games: [Game]

    enum CodingKeys: String, CodingKey {
        case count
        case games = "results"
    }
}

class Game: Codable {
    let id: Int
    let name: String
    let released: String
    let backgroundImage: String
    let rating: Double

    var image: UIImage? = UIImage(systemName: "rays")
    var state: DownloadState = .new

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case released
        case backgroundImage = "background_image"
        case rating
    }
    
    init(id: Int, name: String, released: String, backgroundImage: String, rating: Double, image: UIImage?) {
        self.id = id
        self.name = name
        self.released = released
        self.backgroundImage = backgroundImage
        self.rating = rating
        self.image = image
    }
}

class ImageDownloader: Operation {
    private let _game: Game

    init(game: Game) {
        _game = game
    }

    override func main() {
        if isCancelled {
            return
        }

        guard let imageData = try? Data(contentsOf: URL(string: _game.backgroundImage)!) else { return }

        if isCancelled {
            return
        }

        if !imageData.isEmpty {
            _game.image = UIImage(data: imageData)
            _game.state = .downloaded
        } else {
            _game.image = UIImage(systemName: "x.circle")
            _game.state = .failed
        }
    }
}

class PendingOperations {
    lazy var downloadInProgress: [IndexPath : Operation] = [:]

    lazy var downloadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.name = "com.dicoding.imagedownload"
        queue.maxConcurrentOperationCount = 2
        return queue
    }()
}

class ViewController: UIViewController {
    @IBOutlet weak var gameTableView: UITableView!

    private let _pendingOperations = PendingOperations()

    var games = [Game]()

    override func viewDidLoad() {
        super.viewDidLoad()

        gameTableView.backgroundView = nil
        gameTableView.backgroundColor = UIColor.black
        gameTableView.dataSource = self
        gameTableView.delegate = self
        gameTableView.register(UINib(nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "GameCell")

        components.queryItems = [
            URLQueryItem(name: "page_size", value: pageSize)
        ]

        let request = URLRequest(url: components.url!)

        let task = URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let response = response as? HTTPURLResponse, let data = data else { return }

            if response.statusCode == 200 {
                DispatchQueue.main.async {
                    do {
                        self.games = try JSONDecoder().decode(Games.self, from: data).games
                        self.gameTableView.reloadData()
                    } catch {
                        let alert = UIAlertController(title: "Not found!", message: "Please try again", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) )
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                print("ERROR: \(data), HTTP Status: \(response.statusCode)")
            }
        }

        task.resume()
    }

    fileprivate func startOperations(game: Game, indexPath: IndexPath) {
        if game.state == .new {
            startDownload(game: game, indexPath: indexPath)
        }
    }

    fileprivate func startDownload(game: Game, indexPath: IndexPath) {
        guard _pendingOperations.downloadInProgress[indexPath] == nil else { return }

        let downloader = ImageDownloader(game: game)
        downloader.completionBlock = {
            if downloader.isCancelled { return }

            DispatchQueue.main.async {
                self._pendingOperations.downloadInProgress.removeValue(forKey: indexPath)
                self.gameTableView.reloadRows(at: [indexPath], with: .automatic)
            }
        }

        _pendingOperations.downloadInProgress[indexPath] = downloader
        _pendingOperations.downloadQueue.addOperation(downloader)
    }

    fileprivate func toggleSuspendOperations(isSuspended: Bool) {
        _pendingOperations.downloadQueue.isSuspended = isSuspended
    }
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        toggleSuspendOperations(isSuspended: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        toggleSuspendOperations(isSuspended: false)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameTableViewCell

        let game = self.games[indexPath.row]
        cell.name.text = game.name
        cell.released.text = game.released
        cell.rating.text = String(game.rating)
        cell.imageGame.image = game.image

        //        if cell.accessoryView == nil {
        //            cell.accessoryView = UIActivityIndicatorView(style: .medium)
        //        }
        //
        //        guard let indicator = cell.accessoryView as? UIActivityIndicatorView else { fatalError() }

        if game.state == .new {
            //            indicator.startAnimating()
            if !tableView.isDragging && !tableView.isDecelerating {
                startOperations(game: game, indexPath: indexPath)
            }
        } else {
            //            indicator.stopAnimating()
        }

        return cell
    }

}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = DetailViewController(nibName: "DetailViewController", bundle: nil)

        detail.game = games[indexPath.row]

        self.navigationController?.pushViewController(detail, animated: true)
    }
}
