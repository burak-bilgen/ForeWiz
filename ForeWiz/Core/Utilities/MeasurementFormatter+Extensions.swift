import Foundation

extension MeasurementFormatter {
    static func temperatureFormatter(locale: Locale = L10n.locale) -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = locale
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}
