import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Drink.timestamp, ascending: false)],
        predicate: NSPredicate(format: "timestamp >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default)
    private var drinks: FetchedResults<Drink>

    @State private var showingAddDrink = false
    @State private var showingDetails = false

    let hydrationGoal = 2500

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("You are \(hydrationPercent())% towards your goal")
                    .font(.title2)
                    .bold()

                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(drinks.prefix(21)) { drink in
                            VStack(spacing: 4) {
                                Text(icon(for: drink.type ?? "water"))
                                    .font(.title)

                                Text("\(drink.amount) ml")
                                    .font(.caption2)

                                HStack(spacing: 2) {
                                    Group {
                                        if (drink.type ?? "").contains("coffee") {
                                            Image(systemName: "bolt.fill")
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .frame(width: 10, height: 10)

                                    Group {
                                        if (drink.type ?? "").contains("tea") {
                                            Image(systemName: "wind")
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .frame(width: 10, height: 10)

                                    Group {
                                        if (drink.type ?? "").contains("juice") {
                                            Image(systemName: "cube.fill")
                                        } else {
                                            Color.clear
                                        }
                                    }
                                    .frame(width: 10, height: 10)
                                }
                                .frame(height: 10)
                                
                            }
                            .padding(4)
                        }
                    }
                }

                Button(action: { showingDetails = true }) {
                    VStack(spacing: 2) {
                        Text("You've drunk \(totalMl()) ml")
                        Text("of which \(hydrationMl()) ml counts towards your hydration goal")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top)

                HStack {
                    Button("Last Drink") {}
                    Spacer()
                    Button(action: { showingAddDrink = true }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                    Button("Favourite") {}
                }
                .padding(.horizontal)
            }
            .padding()
            .navigationBarHidden(true)
        }
        
        // TODO: Remove before release
        // Uncomment to clear drinks from setup
        // .onAppear {
        //     deleteAllDrinks()
        // }
        
        .sheet(isPresented: $showingAddDrink) {
            AddDrinkView()
        }
        .sheet(isPresented: $showingDetails) {
            DrinkDetailView(drinks: Array(drinks))
        }
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

    private func hydrationValue(for drink: Drink) -> Double {
        let type = drink.type ?? ""
        if type.contains("coffee") || type.contains("tea") {
            return 0.8
        }
        return 1.0
    }

    private func hydrationMl() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return drinks
            .filter { ($0.timestamp ?? .distantPast) >= today }
            .reduce(0) { $0 + Int(Double($1.amount) * hydrationValue(for: $1)) }
    }

    private func totalMl() -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return drinks
            .filter { ($0.timestamp ?? .distantPast) >= today }
            .reduce(0) { $0 + Int($1.amount) }
    }

    private func hydrationPercent() -> Int {
        min(100, hydrationMl() * 100 / hydrationGoal)
    }
    
    
    //TODO: Remove before release
    private func deleteAllDrinks() {
        for drink in drinks {
            viewContext.delete(drink)
        }
        try? viewContext.save()
    }
}
