//
//  Weathra_WidgetBundle.swift
//  Weathra Widget
//
//  Created by Burak on 9.05.2026.
//

import WidgetKit
import SwiftUI

@main
struct Weathra_WidgetBundle: WidgetBundle {
    var body: some Widget {
        Weathra_Widget()
        Weathra_WidgetControl()
        Weathra_WidgetLiveActivity()
    }
}
