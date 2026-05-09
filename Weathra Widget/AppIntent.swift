//
//  AppIntent.swift
//  Weathra Widget
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Hava Durumu" }
    static var description: IntentDescription { "Weathra hava durumu widget'ı" }

    @Parameter(title: "Konum", default: nil)
    var selectedLocationID: String?
}