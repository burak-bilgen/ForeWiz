import Foundation

struct SystemDateProvider: DateProvider {
    var now: Date {
        Date()
    }
}
