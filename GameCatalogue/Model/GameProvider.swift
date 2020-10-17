//
//  GameProvider.swift
//  GameCatalogue
//
//  Created by William Sutanto on 17/10/20.
//  Copyright © 2020 William Sutanto. All rights reserved.
//

import CoreData
import UIKit

class GameProvider {

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Game")

        container.loadPersistentStores { _, error in
            guard error == nil else {
                fatalError("Unresolved error \(error!)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = false
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.undoManager = nil

        return container
    }()

    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = persistentContainer.newBackgroundContext()
        taskContext.undoManager = nil

        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return taskContext
    }

    func getAllGame(completion: @escaping(_ games: [GameModel]) -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GameData")
            do {
                let results = try taskContext.fetch(fetchRequest)
                var games: [GameModel] = []
                for result in results {
                    let game = GameModel(id: result.value(forKeyPath: "id") as? Int32,
                                         name: result.value(forKeyPath: "name") as? String,
                                         released: result.value(forKeyPath: "released") as? String,
                                         imageUrl: result.value(forKeyPath: "imageUrl") as? String,
                                         rating: result.value(forKeyPath: "rating") as? Double,
                                         image: result.value(forKeyPath: "image") as? Data)
                    games.append(game)
                }
                completion(games)
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }

    func getGame(_ id: Int, completion: @escaping(_ games: GameModel) -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "GameData")
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == \(id)")
            do {
                if let result = try taskContext.fetch(fetchRequest).first {
                    let game = GameModel(id: result.value(forKeyPath: "id") as? Int32,
                                         name: result.value(forKeyPath: "name") as? String,
                                         released: result.value(forKeyPath: "released") as? String,
                                         imageUrl: result.value(forKeyPath: "imageUrl") as? String,
                                         rating: result.value(forKeyPath: "rating") as? Double,
                                         image: result.value(forKeyPath: "image") as? Data)
                    completion(game)
                }
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.userInfo)")
            }
        }
    }

    func createGame(_ id: Int, _ name: String, _ released: String, _ imageUrl: String, _ rating: Double, _ image: Data, completion: @escaping() -> Void) {
        let taskContext = newTaskContext()
        taskContext.performAndWait {
            if let entity = NSEntityDescription.entity(forEntityName: "GameData", in: taskContext) {
                let game = NSManagedObject(entity: entity, insertInto: taskContext)

                game.setValue(id, forKeyPath: "id")
                game.setValue(name, forKeyPath: "name")
                game.setValue(released, forKeyPath: "released")
                game.setValue(imageUrl, forKeyPath: "imageUrl")
                game.setValue(rating, forKeyPath: "rating")
                game.setValue(image, forKeyPath: "image")

                do {
                    try taskContext.save()
                    completion()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }
    }

    func deleteAllGame(completion: @escaping() -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GameData")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                batchDeleteResult.result != nil {
                completion()
            }
        }
    }

    func deleteGame(_ id: Int, completion: @escaping() -> Void) {
        let taskContext = newTaskContext()
        taskContext.perform {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "GameData")
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == \(id)")
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            batchDeleteRequest.resultType = .resultTypeCount
            if let batchDeleteResult = try? taskContext.execute(batchDeleteRequest) as? NSBatchDeleteResult,
                batchDeleteResult.result != nil {
                completion()
            }
        }
    }
}
