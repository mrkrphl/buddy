import Foundation

/// Catalog of cook gear Buddy can plan around.
enum KitchenApplianceID: String, CaseIterable, Codable, Identifiable, Hashable {
    case stove
    case microwave
    case airFryer
    case blender
    case toaster
    case instantPot
    case oven
    case riceCooker
    case grill
    case foodProcessor
    case slowCooker
    case coffeeMaker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stove: return "Stove"
        case .microwave: return "Microwave"
        case .airFryer: return "Air fryer"
        case .blender: return "Blender"
        case .toaster: return "Toaster"
        case .instantPot: return "Instant Pot"
        case .oven: return "Oven"
        case .riceCooker: return "Rice cooker"
        case .grill: return "Grill"
        case .foodProcessor: return "Food processor"
        case .slowCooker: return "Slow cooker"
        case .coffeeMaker: return "Coffee maker"
        }
    }

    var blurb: String {
        switch self {
        case .stove: return "Buddy will lean on stovetop stir-fries and pans."
        case .microwave: return "Quick reheats and mug meals stay on the table."
        case .airFryer: return "Buddy will suggest air-fry friendly plates."
        case .blender: return "Smoothies and blended sauces stay in play."
        case .toaster: return "Toast, bagels, and crispy finishes."
        case .instantPot: return "Pressure-cook stews and grains when you’re short on time."
        case .oven: return "Roasts, bakes, and sheet-pan nights."
        case .riceCooker: return "Set-and-forget rice and grains."
        case .grill: return "Outdoor or indoor grill energy."
        case .foodProcessor: return "Chop, shred, and sauce with less effort."
        case .slowCooker: return "Low-and-slow pots waiting when you get home."
        case .coffeeMaker: return "Morning fuel — Buddy won’t forget the brew."
        }
    }

    /// SF Symbol fallback (shelf extras / accessibility).
    var systemImage: String {
        switch self {
        case .stove: return "flame.fill"
        case .microwave: return "microwave"
        case .airFryer: return "fan"
        case .blender: return "drop.fill"
        case .toaster: return "rectangle.split.3x1.fill"
        case .instantPot: return "circle.bottomhalf.filled"
        case .oven: return "oven"
        case .riceCooker: return "leaf.fill"
        case .grill: return "flame"
        case .foodProcessor: return "gearshape.2.fill"
        case .slowCooker: return "hourglass"
        case .coffeeMaker: return "cup.and.saucer"
        }
    }

    /// Catalog asset names for the counter diorama (nil → SF Symbol).
    var offAsset: String? {
        switch self {
        case .microwave: return "ApplianceMicrowaveOff"
        case .airFryer: return "ApplianceAirFryerOff"
        case .blender: return "ApplianceBlenderOff"
        case .toaster: return "ApplianceToasterOff"
        case .instantPot: return "ApplianceInstantPotOff"
        default: return nil
        }
    }

    var onAsset: String? {
        switch self {
        case .microwave: return "ApplianceMicrowaveOn"
        case .airFryer: return "ApplianceAirFryerOn"
        case .blender: return "ApplianceBlenderOn"
        case .toaster: return "ApplianceToasterOn"
        case .instantPot: return "ApplianceInstantPotOn"
        default: return nil
        }
    }

    var hasCounterSprite: Bool { offAsset != nil && onAsset != nil }

    /// Default row on the main counter diorama (matches mockup L→R).
    static var counterDefaults: [KitchenApplianceID] {
        [.microwave, .airFryer, .blender, .toaster, .instantPot]
    }

    static var shelfExtras: [KitchenApplianceID] {
        allCases.filter { !counterDefaults.contains($0) }
    }
}

enum KitchenApplianceStore {
    static func decodeIDs(_ raw: [String]) -> Set<KitchenApplianceID> {
        Set(raw.compactMap(KitchenApplianceID.init(rawValue:)))
    }

    static func encodeIDs(_ ids: Set<KitchenApplianceID>) -> [String] {
        KitchenApplianceID.allCases.filter { ids.contains($0) }.map(\.rawValue)
    }
}
