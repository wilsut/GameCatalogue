//
//  SearchViewController.swift
//  GameCatalogue
//
//  Created by William Sutanto on 12/07/20.
//  Copyright © 2020 William Sutanto. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var gameTableView: UITableView!
    
    private let _pendingOperations = PendingOperations()
    
    var games = [Game]()
    var search: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameTableView.backgroundView = nil
        gameTableView.backgroundColor = UIColor.black
        gameTableView.dataSource = self
        gameTableView.delegate = self
        gameTableView.register(UINib(nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "GameCell")
        
        searchBar.delegate = self
        
        components.queryItems = [
            URLQueryItem(name: "page_size", value: pageSize)
        ]
        
        let request = URLRequest(url: components.url!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, let data = data else { return }
            
            if response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.games = try! JSONDecoder().decode(Games.self, from: data).games
                    self.gameTableView.reloadData()
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

extension SearchViewController: UITableViewDataSource{
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

extension SearchViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = DetailViewController(nibName: "DetailViewController", bundle: nil)
        
        detail.game = games[indexPath.row]
        
        self.navigationController?.pushViewController(detail, animated: true)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        search = searchText
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        components.queryItems = [
            URLQueryItem(name: "page_size", value: pageSize),
            URLQueryItem(name: "search", value: search)
        ]
        
        let request = URLRequest(url: components.url!)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse, let data = data else { return }
            
            if response.statusCode == 200 {
                DispatchQueue.main.async {
                    self.games = try! JSONDecoder().decode(Games.self, from: data).games
                    self.gameTableView.reloadData()
                }
            } else {
                print("ERROR: \(data), HTTP Status: \(response.statusCode)")
            }
        }
        
        task.resume()
    }
}
