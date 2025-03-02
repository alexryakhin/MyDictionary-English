//
//  FavoritesService.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 8/25/24.
//

import CoreData
import Combine

protocol FavoritesServiceInterface {
    var favoritesPublisher: AnyPublisher<[Recipe], CoreError> { get }

    func save(recipe: Recipe) throws(CoreError)
    func remove(recipeWithId: Int) throws(CoreError)
    func isFavorite(recipeWithId: Int) throws(CoreError) -> Bool
    func fetchAllFavorites() throws(CoreError) -> [Recipe]
    func fetchRecipeById(_ id: Int) throws(CoreError) -> Recipe
}

class FavoritesService: FavoritesServiceInterface {
    private let coreDataService: CoreDataServiceInterface
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let favoritesSubject = CurrentValueSubject<[Recipe], CoreError>([])

    var favoritesPublisher: AnyPublisher<[Recipe], CoreError> {
        return favoritesSubject.eraseToAnyPublisher()
    }

    init(coreDataService: CoreDataServiceInterface) {
        self.coreDataService = coreDataService
        // Initial load of favorite recipes
        loadFavorites()
    }

    private func loadFavorites() {
        do {
            try fetchAllFavorites()
        } catch {
            favoritesSubject.send(completion: .failure(error))
        }
    }

    func save(recipe: Recipe) throws(CoreError) {
        let context = coreDataService.context
        let recipeCD = RecipeCDModel(context: context)
        if let aggregateLikes = recipe.aggregateLikes {
            recipeCD.aggregateLikes = Int32(aggregateLikes)
        }
        if let healthScore = recipe.healthScore {
            recipeCD.healthScore = Int32(healthScore)
        }
        recipeCD.id = Int64(recipe.id)
        recipeCD.image = recipe.image?.absoluteString
        if let ingredients = recipe.extendedIngredients {
            recipeCD.ingredients = try? encoder.encode(ingredients)
        }
        recipeCD.instructions = recipe.instructions
        if let mealTypes = recipe.dishTypes, !mealTypes.isEmpty {
            recipeCD.mealTypes = try? encoder.encode(mealTypes)
        }
        if let nutrition = recipe.nutrition {
            recipeCD.nutrition = try? encoder.encode(nutrition)
        }
        if let occasions = recipe.occasions, !occasions.isEmpty {
            recipeCD.occasions = try? encoder.encode(occasions)
        }
        if let readyInMinutes = recipe.readyInMinutes {
            recipeCD.readyInMinutes = Int32(readyInMinutes)
        }
        if let servings = recipe.servings {
            recipeCD.servings = Int32(servings)
        }
        recipeCD.sourceUrl = recipe.sourceURL
        recipeCD.sourceName = recipe.sourceName
        if let spoonacularScore = recipe.spoonacularScore {
            recipeCD.spoonacularScore = spoonacularScore
        }
        recipeCD.summary = recipe.summary
        recipeCD.sustainable = recipe.sustainable ?? false
        if let taste = recipe.taste {
            recipeCD.taste = try? encoder.encode(taste)
        }
        recipeCD.timestamp = Date()
        recipeCD.title = recipe.title
        recipeCD.vegan = recipe.vegan ?? false
        recipeCD.vegetarian = recipe.vegetarian ?? false
        recipeCD.veryHealthy = recipe.veryHealthy ?? false
        recipeCD.veryPopular = recipe.veryPopular ?? false
        recipeCD.isFavorite = false

        do {
            try coreDataService.saveContext()
            // Reload favorites and publish the updated list
            loadFavorites()
        } catch {
            throw error
        }
    }

    func remove(recipeWithId id: Int) throws(CoreError) {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<RecipeCDModel> = RecipeCDModel.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)

        do {
            let results = try context.fetch(fetchRequest)
            if let favorite = results.first {
                context.delete(favorite)
                try coreDataService.saveContext()
                // Reload favorites and publish the updated list
                loadFavorites()
            }
        } catch {
            throw CoreError.storageError(.saveFailed)
        }
    }

    func isFavorite(recipeWithId id: Int) throws(CoreError) -> Bool {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<RecipeCDModel> = RecipeCDModel.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)

        do {
            let results = try context.fetch(fetchRequest)
            return !results.isEmpty
        } catch {
            throw CoreError.storageError(.readFailed)
        }
    }

    @discardableResult
    func fetchAllFavorites() throws(CoreError) -> [Recipe] {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<RecipeCDModel> = RecipeCDModel.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

        do {
            let results = try context.fetch(fetchRequest)
            let returnValue = results.filter(\.isFavorite).compactMap(mapRecipe(from:))
            favoritesSubject.send(returnValue)
            return returnValue
        } catch {
            throw CoreError.storageError(.readFailed)
        }
    }

    func fetchRecipeById(_ id: Int) throws(CoreError) -> Recipe {
        let context = coreDataService.context
        let fetchRequest: NSFetchRequest<RecipeCDModel> = RecipeCDModel.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)

        if let recipeCD = try? context.fetch(fetchRequest).first {
            return mapRecipe(from: recipeCD)
        } else {
            throw CoreError.storageError(.readFailed)
        }
    }

    private func mapRecipe(from model: RecipeCDModel) -> Recipe {
        Recipe(
            id: Int(model.id),
            title: model.title ?? .empty,
            aggregateLikes: Int(model.aggregateLikes),
            dishTypes: try? decoder.decode([String].self, from: model.mealTypes ?? Data()),
            extendedIngredients: try? decoder.decode([ExtendedIngredient].self, from: model.ingredients ?? Data()),
            healthScore: Int(model.healthScore),
            image: URL(string: model.image),
            instructions: model.instructions,
            nutrition: try? decoder.decode(Nutrition.self, from: model.nutrition ?? Data()),
            occasions: try? decoder.decode([String].self, from: model.occasions ?? Data()),
            readyInMinutes: Int(model.readyInMinutes),
            servings: Int(model.servings),
            sourceName: model.sourceName,
            sourceURL: model.sourceUrl,
            spoonacularScore: model.spoonacularScore,
            summary: model.summary,
            taste: try? decoder.decode(Taste.self, from: model.taste ?? Data()),
            sustainable: model.sustainable,
            vegan: model.vegan,
            vegetarian: model.vegetarian,
            veryHealthy: model.veryHealthy,
            veryPopular: model.veryPopular,
            isFavorite: model.isFavorite
        )
    }
}

#if DEBUG
class FavoritesServiceMock: FavoritesServiceInterface {
    private let favoritesSubject = CurrentValueSubject<[Recipe], CoreError>([])

    var favoritesPublisher: AnyPublisher<[Recipe], CoreError> {
        return favoritesSubject.eraseToAnyPublisher()
    }

    private var recipes: [Recipe] = []

    init(recipes: [Recipe] = []) {
        self.recipes = recipes
    }

    func save(recipe: Recipe) {
        recipes.append(recipe)
    }

    func remove(recipeWithId id: Int) {
        recipes.removeAll {
            id == $0.id
        }
    }

    func isFavorite(recipeWithId id: Int) -> Bool {
        recipes.contains {
            id == $0.id
        }
    }

    func fetchAllFavorites() throws(CoreError) -> [Recipe] {
        recipes
    }

    func fetchRecipeById(_ id: Int) throws(CoreError) -> Recipe {
        Recipe(id: 0, title: "Title")
    }
}
#endif
