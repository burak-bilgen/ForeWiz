//
//  Weathra_WidgetControl.swift
//  Weathra Widget
//

import AppIntents
import SwiftUI
import WidgetKit

struct Weathra_WidgetControl: ControlWidget {
    static let kind: String = "bilgenworks.weatherassistant.Weathra Widget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Hava Durumunu Yenile",
                isOn: value.isEnabled,
                action: RefreshWeatherIntent()
            ) { isEnabled in
                Label(isEnabled ? "Aktif" : "Pasif", systemImage: "arrow.clockwise")
            }
        }
        .displayName("Weathra Kontrol")
        .description("Hava durumunu manuel olarak yenile")
    }
}

extension Weathra_WidgetControl {
    struct Value {
        var isEnabled: Bool
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: RefreshConfiguration) -> Value {
            Value(isEnabled: true)
        }

        func currentValue(configuration: RefreshConfiguration) async throws -> Value {
            Value(isEnabled: true)
        }
    }
}

struct RefreshConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Yenileme"

    @Parameter(title: "Aktif", default: true)
    var isEnabled: Bool
}

struct RefreshWeatherIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Hava Durumunu Yenile"

    @Parameter(title: "Yenile")
    var value: Bool

    init() {}

    init(_ value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}