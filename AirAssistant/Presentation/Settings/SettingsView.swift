import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            UnitSystemPicker(unitSystem: $viewModel.profile.unitSystem)
            QuietHoursPicker(quietHours: $viewModel.profile.quietHours)
        }
        .navigationTitle("Ayarlar")
    }
}
