import SwiftUI

// MARK: - ANSI Color to SwiftUI Color

extension ANSIColor {
    var swiftUIColor: Color {
        switch self {
        case .default:        return Theme.textPrimary
        case .defaultBG:      return .clear
        case .black:          return Color(hex: "282C34")
        case .red:            return Color(hex: "E06C75")
        case .green:          return Color(hex: "98C379")
        case .yellow:         return Color(hex: "E5C07B")
        case .blue:           return Color(hex: "61AFEF")
        case .magenta:        return Color(hex: "C678DD")
        case .cyan:           return Color(hex: "56B6C2")
        case .white:          return Color(hex: "ABB2BF")
        case .brightBlack:    return Color(hex: "5C6370")
        case .brightRed:      return Color(hex: "F44747")
        case .brightGreen:    return Color(hex: "98C379")
        case .brightYellow:   return Color(hex: "D19A66")
        case .brightBlue:     return Color(hex: "528BFF")
        case .brightMagenta:  return Color(hex: "7C4DFF")
        case .brightCyan:     return Color(hex: "00BCD4")
        case .brightWhite:    return Color(hex: "FFFFFF")
        case .rgb(let r, let g, let b):
            return Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
        case .palette(let n):
            return paletteColor(n)
        }
    }

    private func paletteColor(_ n: UInt8) -> Color {
        switch n {
        case 0:   return Color(hex: "000000")
        case 1:   return Color(hex: "AA0000")
        case 2:   return Color(hex: "00AA00")
        case 3:   return Color(hex: "AA5500")
        case 4:   return Color(hex: "0000AA")
        case 5:   return Color(hex: "AA00AA")
        case 6:   return Color(hex: "00AAAA")
        case 7:   return Color(hex: "AAAAAA")
        case 8:   return Color(hex: "555555")
        case 9:   return Color(hex: "FF5555")
        case 10:  return Color(hex: "55FF55")
        case 11:  return Color(hex: "FFFF55")
        case 12:  return Color(hex: "5555FF")
        case 13:  return Color(hex: "FF55FF")
        case 14:  return Color(hex: "55FFFF")
        case 15:  return Color(hex: "FFFFFF")
        case 16...231:
            let v = Int(n) - 16
            let r = v / 36
            let g = (v % 36) / 6
            let b = v % 6
            return Color(
                red: r == 0 ? 0 : Double(r * 40 + 55) / 255,
                green: g == 0 ? 0 : Double(g * 40 + 55) / 255,
                blue: b == 0 ? 0 : Double(b * 40 + 55) / 255
            )
        case 232...255:
            let gray = Double(Int(n) - 232) * 10.0 + 8.0
            return Color(white: gray / 255)
        default:
            return Theme.textPrimary
        }
    }
}

// MARK: - Styled Text View

struct ANSITextView: View {
    let segments: [ANSISegment]

    var body: some View {
        segments.reduce(Text("")) { result, segment in
            result + styledText(segment)
        }
    }

    private func styledText(_ segment: ANSISegment) -> Text {
        var text = Text(segment.text)
            .foregroundColor(segment.style.foreground.swiftUIColor)
            .font(Theme.terminalFont)

        if segment.style.bold {
            text = text.bold()
        }
        if segment.style.italic {
            text = text.italic()
        }
        if segment.style.underline {
            text = text.underline()
        }
        if segment.style.strikethrough {
            text = text.strikethrough()
        }

        return text
    }
}
