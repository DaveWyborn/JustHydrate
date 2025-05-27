import SwiftUI

enum HydrationGroup {
    case high    // 100% hydration
    case medium  // 80% hydration
    case low     // future use

    var backgroundColor: Color {
        switch self {
        case .high: return Color.blue.opacity(0.2)
        case .medium: return Color.orange.opacity(0.2)
        case .low: return Color.red.opacity(0.2)
        }
    }
}

struct QuickDrink: Hashable {
    let type: String
    let amount: Int
    let group: HydrationGroup
    let hasSugar: Bool
    let hasSalt: Bool
    let strength: String?
}

let quickPicks: [QuickDrink] = [
    QuickDrink(type: "water", amount: 200, group: .high, hasSugar: false, hasSalt: false, strength: nil),
    QuickDrink(type: "tea", amount: 150, group: .medium, hasSugar: false, hasSalt: false, strength: "mild"),
    QuickDrink(type: "coffee", amount: 100, group: .medium, hasSugar: true, hasSalt: false, strength: "strong"),
    QuickDrink(type: "milk", amount: 150, group: .high, hasSugar: false, hasSalt: false, strength: nil)
]

let drinkSubOptions: [BaseDrinkType: [String]] = [
    .water: ["Plain", "Sparkling", "Squash (Sugar Free)"],
    .tea: ["Herbal", "Matcha", "Green"],
    .coffee: ["Instant", "Filter", "Cafetière", "Latte", "Cappuccino"],
    .milk: ["Skimmed", "Semi-skimmed", "Full Fat", "Oat Milk", "Almond Milk"],
    .alcohol: ["Wine", "Beer", "Cider", "Tonic"],
    .softdrink: ["Coke", "Lemonade", "Fanta"],
    .sweet: ["Hot Chocolate", "Milkshake", "Oat Milk"],
    .sports: ["Lucozade", "Isotonic", "Protein Water"]
]



struct AddDrinkView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedBaseDrink: BaseDrinkType?
    @State private var selectedSubOption: String?
    @State private var volume: Double = 200

    var existingDrink: Drink? = nil

    @State private var selectedType: String = "water"


    let drinkTypes = ["water", "tea", "juice", "coffee", "milk"]

    var body: some View {
        NavigationView {
            Form {
                // MARK: Quick Picks Section
                Section(header: Text("Quick Picks")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickPicks, id: \.self) { drink in
                                Button(action: {
                                    selectedType = drink.type
                                    volume = drink.amount
                                    saveDrink()
                                }) {
                                    ZStack {
                                        VStack {
                                            Spacer()
                                            Text(icon(for: drink.type))
                                                .font(.largeTitle)
                                            Text("\(drink.amount) ml")
                                                .font(.caption)
                                            Text(drink.type.capitalized)
                                                .font(.caption2)
                                            Spacer()
                                        }
                                        .padding()
                                        .frame(width: 100, height: 120)
                                        .background(drink.group.backgroundColor)
                                        .cornerRadius(12)

                                        // Overlay icons
                                        VStack {
                                            HStack {
                                                if drink.hasSugar {
                                                    Image(systemName: "cube.fill")
                                                }
                                                if drink.hasSalt {
                                                    Image(systemName: "drop.fill")
                                                }
                                                Spacer()
                                            }
                                            Spacer()
                                            HStack {
                                                Spacer()
                                                if let strength = drink.strength {
                                                    Image(systemName: strengthIcon(for: strength))
                                                }
                                            }
                                        }
                                        .padding(6)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                .padding(.vertical, 2)
                
                Section(header: Text("Build your own")) {
                    BaseDrinkPickerView(selectedDrink: $selectedBaseDrink)
                }
                
                if let base = selectedBaseDrink,
                   let options = drinkSubOptions[base] {
                    Section(header: Text("Type")) {
                        Picker("Sub-type", selection: $selectedSubOption) {
                            ForEach(options, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(.wheel) // You can change this to .segmented or .wheel or .menu
                    }
                }
                
                // TODO: Post-MVP - Store last used sub-option per base drink type
                // TODO: Post-MVP - Allow custom sub-options to be added (e.g. Starbucks favourites)
                
                Section(header: Text("Amount")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume: \(Int(volume)) ml")
                            .font(.subheadline)
                        
                      //  let hydrationPercent = hydrationValue(for: selectedBaseDrink) * 100
                                
                      //  Text("Hydration impact: \(Int(hydrationPercent))%")
                      //      .font(.caption)
                      //      .foregroundColor(hydrationPercent == 100 ? .green : .orange)

                        Slider(value: $volume, in: 0...2000, step: 50)
                    }
                }
                
                
                
            }
            .navigationTitle(existingDrink == nil ? "Add Drink" : "Edit Drink")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveDrink()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if let drink = existingDrink {
                selectedType = drink.type ?? "water"
                volume = Int(drink.amount)
            }
            if selectedBaseDrink != nil {
                    loadLastVolume(for: selectedBaseDrink)
                }
        }
    }
    
    private func loadLastVolume(for type: BaseDrinkType?) {
        guard let key = type?.rawValue else { return }
        let saved = UserDefaults.standard.double(forKey: "volume_\(key)")
        if saved > 0 {
            volume = saved
        } else {
            volume = 200
        }
    }
    
    private func saveLastVolume(for type: BaseDrinkType?) {
        guard let key = type?.rawValue else { return }
        UserDefaults.standard.set(volume, forKey: "volume_\(key)")
    }

    private func saveDrink() {
        let drink = existingDrink ?? Drink(context: viewContext)

        drink.timestamp = existingDrink?.timestamp ?? Date()
        drink.amount = Int64(volume)
        drink.type = selectedType

        saveLastVolume(for: selectedBaseDrink)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("⚠️ Failed to save drink: \(error)")
        }
    }
    
    private func hydrationValue(for type: BaseDrinkType?) -> Double {
        switch type {
        case .coffee, .tea, .alcohol, .softdrink:
            return 0.8
        case .sports:
            return 1.1 // TODO: refine later
        default:
            return 1.0
        }
    }

    private func icon(for type: String) -> String {
        switch type {
        case "juice": return "🧃"
        case "tea": return "🍵"
        case "coffee": return "☕️"
        case "milk": return "🥛"
        default: return "🥤"
        }
    }

    private func strengthIcon(for level: String) -> String {
        switch level {
        case "strong": return "bolt.fill"
        case "mild": return "wind"
        default: return "circle"
        }
    }
}
