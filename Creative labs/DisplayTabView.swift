import SwiftUI

struct DisplayTabView: View {
    @ObservedObject var ble: BLEManager
    @State private var borderStyle: BorderStyle = .classic
    @State private var fontStyle: FontStyle = .default_

    enum BorderStyle: String, CaseIterable {
        case classic     = "Classic"
        case wave        = "Wave"
        case doubleLine  = "Double Line"
        case dashedLine  = "Dashed Line"
    }

    enum FontStyle: String, CaseIterable {
        case default_  = "Default"
        case bold      = "Bold"
        case digital   = "Digital"
        case elegant   = "Elegant"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader("Screen Border")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(BorderStyle.allCases, id: \.self) { style in
                        borderCard(style: style)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                Divider().background(Color.ptDivider)

                sectionHeader("Font Style")

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(FontStyle.allCases, id: \.self) { style in
                        fontCard(style: style)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.ptTextMid)
            .tracking(0.5)
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    func borderCard(style: BorderStyle) -> some View {
        let sel = borderStyle == style
        return Button { borderStyle = style } label: {
            HStack(spacing: 8) {
                // Radio
                Circle()
                    .stroke(sel ? Color.ptPinkDeep : Color.ptTextLight, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .overlay(sel ? Circle().fill(Color.ptPinkDeep).frame(width: 8, height: 8) : nil)
                Text(style.rawValue)
                    .font(.ptCaption)
                    .foregroundColor(.ptText)
                Spacer()
                // Mini clock preview
                Text("10:00")
                    .font(previewFont(style))
                    .foregroundColor(.ptPinkDeep)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: previewRadius(style))
                            .stroke(Color.ptPink, lineWidth: previewBorder(style))
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(sel ? Color.ptPinkLight.opacity(0.5) : Color.ptTabBg)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    func fontCard(style: FontStyle) -> some View {
        let sel = fontStyle == style
        return Button { fontStyle = style } label: {
            HStack(spacing: 8) {
                Circle()
                    .stroke(sel ? Color.ptPinkDeep : Color.ptTextLight, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                    .overlay(sel ? Circle().fill(Color.ptPinkDeep).frame(width: 8, height: 8) : nil)
                Text(style.rawValue)
                    .font(.ptCaption)
                    .foregroundColor(.ptText)
                Spacer()
                Text("10:00")
                    .font(previewFontStyle(style))
                    .foregroundColor(.ptPinkDeep)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.ptPinkLight.opacity(0.3))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(sel ? Color.ptPinkLight.opacity(0.5) : Color.ptTabBg)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    func previewFont(_ s: BorderStyle) -> Font {
        switch s {
        case .classic:    return .system(size: 10)
        case .wave:       return .system(size: 10, design: .rounded)
        case .doubleLine: return .system(size: 10)
        case .dashedLine: return .system(size: 10)
        }
    }
    func previewRadius(_ s: BorderStyle) -> CGFloat {
        switch s {
        case .classic: return 3
        case .wave: return 8
        case .doubleLine: return 0
        case .dashedLine: return 3
        }
    }
    func previewBorder(_ s: BorderStyle) -> CGFloat {
        switch s {
        case .doubleLine: return 2
        default: return 1
        }
    }
    func previewFontStyle(_ s: FontStyle) -> Font {
        switch s {
        case .default_: return .system(size: 10)
        case .bold:     return .system(size: 10, weight: .bold)
        case .digital:  return .system(size: 10, design: .monospaced)
        case .elegant:  return Font.custom("Georgia", size: 10)
        }
    }
}
