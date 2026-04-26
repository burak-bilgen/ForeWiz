import SwiftUI

struct UnitSystemPicker: View {
    @Binding var unitSystem: UnitSystem

    var body: some View {
        Picker("Birimler", selection: $unitSystem) {
            ForEach(UnitSystem.allCases, id: \.self) { system in
                Text(system.localizedTitle).tag(system)
            }
        }
    }
}
