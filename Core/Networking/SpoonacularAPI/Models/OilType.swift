//
//  OilType.swift
//  PureBite
//
//  Created by Aleksandr Riakhin on 8/24/24.
//
import Foundation

enum OilType: String, CaseIterable {
    case cookingOil = "cooking oil"
    case tunaInOliveOil = "tuna in olive oil"
    case cannedAnchovies = "canned anchovies"
    case albacoreTunaPackedInOil = "albacore tuna packed in oil"
    case oilCuredBlackOlives = "oil cured black olives"
    case oilPackedSunDriedTomatoes = "oil packed sun dried tomatoes"
    case mctOil = "mct oil"
    case soybeanOil = "soybean oil"
    case cornOil = "corn oil"
    case palmOil = "palm oil"
    case flaxOil = "flax oil"
    case hempOil = "hemp oil"
    case oliveOil = "olive oil"
    case chiliOil = "chili oil"
    case saladOil = "salad oil"
    case lemonOil = "lemon oil"
    case basilOil = "basil oil"
    case vegetableOil = "vegetable oil"
    case oliveOilSpray = "olive oil spray"
    case canolaOil = "canola oil"
    case sesameOil = "sesame oil"
    case peanutOil = "peanut oil"
    case walnutOil = "walnut oil"
    case garlicOil = "garlic oil"
    case almondOil = "almond oil"
    case coconutOil = "coconut oil"
    case avocadoOil = "avocado oil"
    case truffleOil = "truffle oil"
    case mustardOil = "mustard oil"
    case hazelnutOil = "hazelnut oil"
    case grapeSeedOil = "grape seed oil"
    case sunflowerOil = "sunflower oil"
    case safflowerOil = "safflower oil"
    case riceBranOil = "rice bran oil"
    case pistachioOil = "pistachio oil"
    case vegetableOilCookingSpray = "vegetable oil cooking spray"
    case shortening = "shortening"
    case lightOliveOil = "light olive oil"
    case pumpkinSeedOil = "pumpkin seed oil"
    case darkSesameOil = "dark sesame oil"
    case virginOliveOil = "virgin olive oil"
    case extraVirginOliveOil = "extra virgin olive oil"
    case expellerPressedCanolaOil = "expeller pressed canola oil"

    static var excludedOils: [OilType] {
        [
            .flaxOil,
            .hempOil,
            .sesameOil,
            .peanutOil,
            .walnutOil,
            .almondOil,
            .grapeSeedOil,
            .sunflowerOil,
            .safflowerOil,
            .pumpkinSeedOil,
            .canolaOil,
            .vegetableOil,
            .vegetableOilCookingSpray,
            .lightOliveOil,
            .mctOil,
            .shortening,
            .riceBranOil,
            .pistachioOil,
            .expellerPressedCanolaOil,
            .oliveOilSpray,
            .saladOil,
            .soybeanOil
        ]
    }
}
