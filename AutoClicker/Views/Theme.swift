import SwiftUI

enum Theme {
    static let accent = Color(red: 0.37, green: 0.92, blue: 0.83)      // turquoise
    static let running = Color(red: 0.37, green: 0.92, blue: 0.83)
    static let paused = Color(red: 0.98, green: 0.75, blue: 0.29)      // ambre
    static let danger = Color(red: 0.97, green: 0.40, blue: 0.40)
    static let marker = Color(red: 0.55, green: 0.60, blue: 1.0)       // lavande

    /// Couleur d'un point selon sa position dans la séquence.
    static func pointColor(_ index: Int) -> Color {
        let palette: [Color] = [
            Color(red: 0.37, green: 0.92, blue: 0.83),
            Color(red: 0.55, green: 0.60, blue: 1.0),
            Color(red: 0.98, green: 0.75, blue: 0.29),
            Color(red: 0.96, green: 0.47, blue: 0.71),
            Color(red: 0.53, green: 0.86, blue: 0.42),
            Color(red: 0.40, green: 0.75, blue: 0.98)
        ]
        return palette[index % palette.count]
    }
}

/// Champ numérique en millisecondes (ou autre unité) avec bornes.
struct NumberField: View {
    let title: String
    @Binding var value: Int
    var unit: String = "ms"
    var range: ClosedRange<Int> = 0...3_600_000
    var step: Int = 10

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            TextField(title, value: clamped, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 90)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 22, alignment: .leading)
            Stepper(title, value: clamped, in: range, step: step)
                .labelsHidden()
        }
    }

    private var clamped: Binding<Int> {
        Binding(
            get: { value },
            set: { value = min(max($0, range.lowerBound), range.upperBound) }
        )
    }
}

extension Int {
    /// « 1,5 s » ou « 250 ms ».
    var formattedDuration: String {
        if self >= 1000 {
            let seconds = Double(self) / 1000
            return seconds.formatted(.number.precision(.fractionLength(0...2))) + " s"
        }
        return "\(self) ms"
    }
}
