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

struct AddDrinkView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var existingDrink: Drink? = nil

    @State private var selectedType: String = "water"
    @State private var amount: Int = 200

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
                                    amount = drink.amount
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

                Section(header: Text("Drink Type")) {
                    Picker("Drink Type", selection: $selectedType) {
                        ForEach(drinkTypes, id: \.self) { type in
                            Text(type.capitalized)
                        }
                    }
                }

                Section(header: Text("Amount")) {
                    Stepper(value: $amount, in: 50...1000, step: 50) {
                        Text("\(amount) ml")
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
                amount = Int(drink.amount)
            }
        }
    }

    private func saveDrink() {
        let drink = existingDrink ?? Drink(context: viewContext)

        drink.timestamp = existingDrink?.timestamp ?? Date()
        drink.amount = Int64(amount)
        drink.type = selectedType

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("⚠️ Failed to save drink: \(error)")
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
