//
//  FavoriteViewController.swift
//  GameCatalogue
//
//  Created by William Sutanto on 17/10/20.
//  Copyright © 2020 William Sutanto. All rights reserved.
//

import UIKit

class FavoriteViewController: UIViewController {
    @IBOutlet weak var gameTableView: UITableView!
    
    private var games: [GameModel] = []
    private lazy var gameProvider: GameProvider  = { return GameProvider() }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gameTableView.backgroundView = nil
        gameTableView.backgroundColor = UIColor.black
        gameTableView.dataSource = self
        gameTableView.delegate = self
        gameTableView.register(UINib(nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "GameCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.gameProvider.getAllGame { (result) in
            DispatchQueue.main.async {
                self.games = result
                self.gameTableView.reloadData()
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

extension FavoriteViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.games.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameTableViewCell
        
        let game = self.games[indexPath.row]
        cell.name.text = game.name
        cell.released.text = game.released
        cell.rating.text = String(game.rating ?? 0)
        cell.imageGame.image = UIImage(data: game.image ?? Data())
        
        //        if cell.accessoryView == nil {
        //            cell.accessoryView = UIActivityIndicatorView(style: .medium)
        //        }
        //
        //        guard let indicator = cell.accessoryView as? UIActivityIndicatorView else { fatalError() }
        
        return cell
    }
    
}

extension FavoriteViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detail = DetailViewController(nibName: "DetailViewController", bundle: nil)
        let item = games[indexPath.row]
        detail.game = Game(id: Int(item.id!), name: item.name!, released: item.released!, backgroundImage: item.imageUrl!, rating: item.rating!, image: UIImage(data: item.image ?? Data()))
        self.navigationController?.pushViewController(detail, animated: true)
    }
}
