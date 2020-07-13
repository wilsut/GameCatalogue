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
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageGame: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    var game: Game?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let result = game {
            imageGame.image = result.image
            nameLabel.text = result.name
            
            let urlComponents = URLComponents(string: "https://api.rawg.io/api/games/\(result.id)")!
            
            let request = URLRequest(url: urlComponents.url!)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
