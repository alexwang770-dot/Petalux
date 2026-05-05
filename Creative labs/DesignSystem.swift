import SwiftUI

// MARK: - Petalux Design System

extension Color {
    // Core palette from Figma
    static let ptCream       = Color(red: 0.984, green: 0.969, blue: 0.957)   // #FBF7F4 phone bg
    static let ptPink        = Color(red: 0.929, green: 0.714, blue: 0.722)   // #ED B6B8 rose
    static let ptPinkLight   = Color(red: 0.973, green: 0.890, blue: 0.890)   // #F8E3E3 light rose
    static let ptPinkDeep    = Color(red: 0.741, green: 0.455, blue: 0.471)   // #BD7478 deep rose
    static let ptSage        = Color(red: 0.533, green: 0.576, blue: 0.475)   // #889279 sage green
    static let ptSageLight   = Color(red: 0.820, green: 0.843, blue: 0.796)   // #D1D7CB light sage
    static let ptBrown       = Color(red: 0.408, green: 0.278, blue: 0.224)   // #684739
    static let ptText        = Color(red: 0.267, green: 0.200, blue: 0.180)   // #44332E dark text
    static let ptTextMid     = Color(red: 0.533, green: 0.435, blue: 0.408)   // #886F68
    static let ptTextLight   = Color(red: 0.733, green: 0.667, blue: 0.643)   // #BBAAA4
    static let ptDivider     = Color(red: 0.910, green: 0.878, blue: 0.867)   // #E8E0DD

    // Tab bar
    static let ptTabBg       = Color(red: 0.969, green: 0.945, blue: 0.933)   // #F7F1EE
    static let ptTabActive   = Color(red: 0.741, green: 0.455, blue: 0.471)   // same as ptPinkDeep

    // Toggle on
    static let ptToggleOn    = Color(red: 0.533, green: 0.576, blue: 0.475)   // sage
}

extension Font {
    // Display / clock
    static let ptClock  = Font.custom("Georgia", size: 56).weight(.regular)
    static let ptClockSm = Font.custom("Georgia", size: 14)
    static let ptTitle  = Font.custom("Georgia", size: 22).italic()
    static let ptHead   = Font.system(size: 13, weight: .medium)
    static let ptBody   = Font.system(size: 13, weight: .regular)
    static let ptCaption = Font.system(size: 11, weight: .regular)
    static let ptTab    = Font.system(size: 10, weight: .medium)
}

// MARK: - Tab enum

enum PtTab: String, CaseIterable {
    case schedule = "Schedule"
    case music    = "Music"
    case display  = "Display"

    var icon: String {
        switch self {
        case .schedule: return "calendar"
        case .music:    return "music.note"
        case .display:  return "sun.max"
        }
    }
}
