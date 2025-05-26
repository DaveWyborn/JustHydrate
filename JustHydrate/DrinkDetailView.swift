import SwiftUI
import CoreData

struct DrinkDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    var drinks: [Drink]
    @State private var editingDrink: Drink?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(drinksToday(), id: \.self) { drink in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(icon(for: drink.type ?? "water"))
                                        .font(.title3)
                                    Text(drink.type?.capitalized ?? "Unknown")
                                        .bold()
                                    Spacer()
                                    Text("\(drink.amount) ml")
                                        .font(.subheadline)
                                }

                                HStack {
                                    Spacer()
                                    Text("Hydration: \(hydrationMl(for: drink)) ml (\(hydrationPercent(for: drink))%)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }

                                let n = nutrition(for: drink)
                                HStack {
                                    Spacer()
                                    Text("Calories: \(n.cal) • Carbs: \(n.carbs)g • Protein: \(n.protein)g • Fat: \(n.fat)g")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Spacer()
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    delete(drink)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingDrink = drink
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 100)
                }

                Divider()

                VStack(spacing: 4) {
                    Text("Total for Today")
                        .font(.headline)

                    let total = totalNutrition()
                    Text("Hydration: \(total.hydration) ml (\(total.percent)%)")
                        .font(.caption)

                    Text("Calories: \(total.cal) • Carbs: \(total.carbs)g • Protein: \(total.protein)g • Fat: \(total.fat)g")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            .navigationTitle("Today's Drinks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $editingDrink) { drink in
                AddDrinkView(existingDrink: drink)
            }
        }
    }

    private func drinksToday() -> [Drink] {
        let today = Calendar.current.startOfDay(for: Date())
        return drinks.filter { ($0.timestamp ?? .distantPast) >= today }
    }

    private func delete(_ drink: Drink) {
        viewContext.delete(drink)
        try? viewContext.save()
    }

    private func hydrationMl(for drink: Drink) -> Int {
        Int(Double(drink.amount) * hydrationValue(for: drink))
    }

    private func hydrationPercent(for drink: Drink) -> Int {
        Int(hydrationValue(for: drink) * 100)
    }

    private func hydrationValue(for drink: Drink) -> Double {
        let type = drink.type ?? ""
        if type.contains("coffee") || type.contains("tea") {
            return 0.8
        }
        return 1.0
    }

    private func nutrition(for drink: Drink) -> (cal: Int, carbs: Int, protein: Int, fat: Int) {
        let baseAmount = Double(drink.amount)
        var calories = 0
        var carbs = 0
        var protein = 0
        var fat = 0

        let type = drink.type ?? ""

        if type == "milk" {
            calories = Int(baseAmount * 0.5)
            carbs = Int(baseAmount * 0.05)
            protein = Int(baseAmount * 0.035)
            fat = Int(baseAmount * 0.02)
        }

        if type == "tea" || type == "coffee" {
            let milkAmount = 15.0
            calories += Int(milkAmount * 0.5)
            carbs += Int(milkAmount * 0.05)
            protein += Int(milkAmount * 0.035)
            fat += Int(milkAmount * 0.02)
        }

        return (calories, carbs, protein, fat)
    }

    private func totalNutrition() -> (hydration: Int, percent: Int, cal: Int, carbs: Int, protein: Int, fat: Int) {
        let goal = 2500
        var hydration = 0
        var cal = 0, carbs = 0, protein = 0, fat = 0

        for drink in drinksToday() {
            hydration += hydrationMl(for: drink)
            let n = nutrition(for: drink)
            cal += n.cal
            carbs += n.carbs
            protein += n.protein
            fat += n.fat
        }

        let percent = min(100, hydration * 100 / goal)
        return (hydration, percent, cal, carbs, protein, fat)
    }

    private func icon(for type: String) -> String {
        switch type {
        case "juice": return "🍣"
        case "tea": return "🍵"
        case "coffee": return "☕️"
        case "milk": return "🥛"
        default: return "🥤"
        }
    }
}
