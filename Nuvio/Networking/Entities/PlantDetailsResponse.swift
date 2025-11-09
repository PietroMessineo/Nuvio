import Foundation

struct PlantDetailsResponse: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let family: String
    let poisonous: PoisonousInfo
    let petToxicity: PetToxicity
    let careDifficulty: CareDifficulty?
    let pruning: Pruning
    let health: HealthStatus
    let taxonomy: Taxonomy
    let description: PlantDescription
    let watering: WateringInfo
    let temperature: Temperature
    let sunlight: DetailedInfo
    let soil: SoilInfo
    let humidity: HumidityInfo
    let repotting: DetailedInfo
    let fertilizer: DetailedInfo
    let bloom: BloomInfo
    let pestsDiseases: PestsDiseases
    let airBenefit: DetailedInfo
    let funFact: DetailedInfo
}

struct PoisonousInfo: Codable, Hashable {
    let isPoisonous: Bool?
    let details: String?
}

struct PetToxicity: Codable, Hashable {
    let cats: ToxicityLevel
    let dogs: ToxicityLevel
    let other: String?
    
    enum ToxicityLevel: String, Codable, Hashable {
        case toxic = "Toxic"
        case nonToxic = "Non-toxic"
        case unknown = "Unknown"
        
        var localizedString: String {
            switch self {
            case .toxic:
                return NSLocalizedString("Toxic", comment: "Pet toxicity level")
            case .nonToxic:
                return NSLocalizedString("Non-toxic", comment: "Pet toxicity level")
            case .unknown:
                return NSLocalizedString("Unknown", comment: "Pet toxicity level")
            }
        }
    }
}

enum CareDifficulty: String, Codable, Hashable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case expert = "Expert"
    
    var localizedString: String {
        switch self {
        case .easy:
            return NSLocalizedString("Easy", comment: "Care difficulty level")
        case .moderate:
            return NSLocalizedString("Moderate", comment: "Care difficulty level")
        case .challenging:
            return NSLocalizedString("Challenging", comment: "Care difficulty level")
        case .expert:
            return NSLocalizedString("Expert", comment: "Care difficulty level")
        }
    }
}

struct Pruning: Codable, Hashable {
    let bestTime: String
    let notes: String?
}

struct HealthStatus: Codable, Hashable {
    let status: PlantHealth
    let summary: String
    
    enum PlantHealth: String, Codable, Hashable {
        case healthy = "Healthy"
        case overWatered = "Over-watered"
        case underWatered = "Under-watered"
        case pestDamaged = "Pest-damaged"
        case nutrientDeficient = "Nutrient-deficient"
        case rootBound = "Root-bound"
        case mixed = "Mixed"
        case unknown = "Unknown"
        
        var localizedString: String {
            switch self {
            case .healthy:
                return NSLocalizedString("Healthy", comment: "Plant health status")
            case .overWatered:
                return NSLocalizedString("Over-watered", comment: "Plant health status")
            case .underWatered:
                return NSLocalizedString("Under-watered", comment: "Plant health status")
            case .pestDamaged:
                return NSLocalizedString("Pest-damaged", comment: "Plant health status")
            case .nutrientDeficient:
                return NSLocalizedString("Nutrient-deficient", comment: "Plant health status")
            case .rootBound:
                return NSLocalizedString("Root-bound", comment: "Plant health status")
            case .mixed:
                return NSLocalizedString("Mixed", comment: "Plant health status")
            case .unknown:
                return NSLocalizedString("Unknown", comment: "Plant health status")
            }
        }
    }
}

struct Taxonomy: Codable, Hashable {
    let genus: String
    let scientificName: String
    let commonNames: [String]
}

struct PlantDescription: Codable, Hashable {
    let short: String
    let long: String
}

struct WateringInfo: Codable, Hashable {
    let short: String
    let long: String
    let reminderToggleLabel: String?
    let reminderDays: Int
}

struct Temperature: Codable, Hashable {
    let celsiusRange: String
    let fahrenheitRange: String
}

struct DetailedInfo: Codable, Hashable {
    let short: String
    let long: String
}

struct SoilInfo: Codable, Hashable {
    let type: String
    let drainage: DrainageLevel
    
    enum DrainageLevel: String, Codable, Hashable {
        case fast = "Fast"
        case moderate = "Moderate"
        case slow = "Slow"
        
        var localizedString: String {
            switch self {
            case .fast:
                return NSLocalizedString("Fast", comment: "Soil drainage level")
            case .moderate:
                return NSLocalizedString("Moderate", comment: "Soil drainage level")
            case .slow:
                return NSLocalizedString("Slow", comment: "Soil drainage level")
            }
        }
    }
}

struct HumidityInfo: Codable, Hashable {
    let rangePercent: String
    let long: String
}

struct BloomInfo: Codable, Hashable {
    let season: BloomSeason
    let hue: String?
    let fragrance: FragranceLevel
    
    enum BloomSeason: String, Codable, Hashable {
        case spring = "spring"
        case summer = "summer"
        case autumn = "autumn"
        case winter = "winter"
        case yearRound = "year-round"
        case none = "none"
        case unknown = "unknown"
        
        var localizedString: String {
            switch self {
            case .spring:
                return NSLocalizedString("spring", comment: "Bloom season")
            case .summer:
                return NSLocalizedString("summer", comment: "Bloom season")
            case .autumn:
                return NSLocalizedString("autumn", comment: "Bloom season")
            case .winter:
                return NSLocalizedString("winter", comment: "Bloom season")
            case .yearRound:
                return NSLocalizedString("year-round", comment: "Bloom season")
            case .none:
                return NSLocalizedString("none", comment: "Bloom season")
            case .unknown:
                return NSLocalizedString("unknown", comment: "Bloom season")
            }
        }
    }
    
    enum FragranceLevel: String, Codable, Hashable {
        case fragrant = "fragrant"
        case nonFragrant = "non-fragrant"
        case subtle = "subtle"
        case unknown = "unknown"
        
        var localizedString: String {
            switch self {
            case .fragrant:
                return NSLocalizedString("fragrant", comment: "Fragrance level")
            case .nonFragrant:
                return NSLocalizedString("non-fragrant", comment: "Fragrance level")
            case .subtle:
                return NSLocalizedString("subtle", comment: "Fragrance level")
            case .unknown:
                return NSLocalizedString("unknown", comment: "Fragrance level")
            }
        }
    }
}

struct PestsDiseases: Codable, Hashable {
    let common: [String]
    let quickFixes: [String]
}

// Extension to show temperature according to user's locale
extension Temperature {
    var localizedTemperature: String {
        if Locale.current.measurementSystem == .metric {
            return celsiusRange
        } else {
            return fahrenheitRange
        }
    }
}
