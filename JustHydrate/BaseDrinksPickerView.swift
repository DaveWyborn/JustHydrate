import SwiftUI

enum BaseDrinkType: String, CaseIterable, Identifiable {
    var id: String { rawValue }

    case water, juice, tea, coffee, milk, alcohol, softdrink, sweet, sports

    var label: String {
        switch self {
        case .water: return "Water"
        case .juice: return "Juice"
        case .tea: return "Tea"
        case .coffee: return "Coffee"
        case .milk: return "Milk"
        case .alcohol: return "Wine/Beer"
        case .softdrink: return "Soft Drink"
        case .sweet: return "Sweet/Other"
        case .sports: return "Sports Drink"
        }
    }

    var icon: String {
        switch self {
        case .water: return "💧"
        case .juice: return "🍊"
        case .tea: return "🍵"
        case .coffee: return "☕️"
        case .milk: return "🥛"
        case .alcohol: return "🍷"
        case .softdrink: return "🧃"
        case .sweet: return "🧋"
        case .sports: return "⚡️"
        }
    }

    static var primaryTypes: [BaseDrinkType] {
        [.water, .juice, .tea, .coffee, .milk, .alcohol]
    }

    static var moreTypes: [BaseDrinkType] {
        [.softdrink, .sweet, .sports]
    }
}

struct BaseDrinkPickerView: View {
    @Binding var selectedDrink: BaseDrinkType?
    @State private var showMore: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                ForEach(BaseDrinkType.primaryTypes) { type in
                    drinkButton(for: type)
                }
            }

            if showMore {
                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                    ForEach(BaseDrinkType.moreTypes) { type in
                        drinkButton(for: type)
                    }
                }
            } else {
                Button("More Drinks") {
                    withAnimation {
                        showMore = true
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }

    private func drinkButton(for type: BaseDrinkType) -> some View {
        Button(action: {
            selectedDrink = type
        }) {
            VStack(spacing: 4) {
                Text(type.icon)
                    .font(.system(size: 28)) // Fixed icon size
                    .frame(height: 30)

                Text(type.label)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 8) // Reduced padding
            .frame(maxWidth: .infinity)
            .background(selectedDrink == type ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// TODO: Post-MVP - Make top 6 dynamic based on user behaviour
// TODO: Post-MVP - Add ability to customise icons or add favourites
// TODO: Post-MVP - Move to carousel mode on compact screens if needed
