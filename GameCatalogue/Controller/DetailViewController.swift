//
//  DetailViewController.swift
//  GameCatalogue
//
//  Created by William Sutanto on 12/07/20.
//  Copyright © 2020 William Sutanto. All rights reserved.
//

import UIKit

struct GameDetail: Codable {
    let description: String
    
    enum CodingKeys: String, CodingKey {
        case description = "description_raw"
    }
}

class DetailViewController: UIViewController {
    
    private lazy var gameProvider: GameProvider = { return GameProvider() }()
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageGame: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBAction func favorite(_ sender: UIButton) {
        favorite()
    }
    
    var game: Game?
    var isFavorite: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = game {
            gameProvider.getGame(result.id) { _ in
                DispatchQueue.main.async {
                    self.toggleFavorite()
                }
            }
            
            imageGame.image = result.image
            nameLabel.text = result.name
            
            let urlComponents = URLComponents(string: "https://api.rawg.io/api/games/\(result.id)")!
            let request = URLRequest(url: urlComponents.url!)
            let task = URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let response = response as? HTTPURLResponse, let data = data else { return }
                if response.statusCode == 200 {
                    DispatchQueue.main.async {
                        let gameDetail = try! JSONDecoder().decode(GameDetail.self, from: data)
                        self.descLabel.text = gameDetail.description
                    }
                } else {
                    print("ERROR: \(data), HTTP Status: \(response.statusCode)")
                }
            }
            task.resume()
        }
    }
    
    private func toggleFavorite() {
        if (isFavorite) {
            isFavorite = false
            favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
        } else {
            isFavorite = true
            favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
        }
    }
    
    private func favorite() {
        if let result = game {
            if (isFavorite) {
                gameProvider.deleteGame(result.id) {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Successful", message: "Remove favorite", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default) )
                        self.present(alert, animated: true, completion: nil)
                        self.toggleFavorite()
                    }
                }
            } else {
                gameProvider.createGame(result.id, result.name, result.released, result.backgroundImage, result.rating, result.image?.pngData() ?? Data()) {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: "Successful", message: "Add favorite", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                        self.toggleFavorite()
                    }
                }
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
