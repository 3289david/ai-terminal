import Foundation

// MARK: - ANSI Parsed Segment

struct ANSISegment: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let style: ANSIStyle

    static func == (lhs: ANSISegment, rhs: ANSISegment) -> Bool {
        lhs.text == rhs.text && lhs.style == rhs.style
    }
}

struct ANSIStyle: Equatable {
    var foreground: ANSIColor = .default
    var background: ANSIColor = .defaultBG
    var bold: Bool = false
    var dim: Bool = false
    var italic: Bool = false
    var underline: Bool = false
    var strikethrough: Bool = false

    static let plain = ANSIStyle()
}

enum ANSIColor: Equatable {
    case `default`
    case defaultBG
    case black, red, green, yellow, blue, magenta, cyan, white
    case brightBlack, brightRed, brightGreen, brightYellow
    case brightBlue, brightMagenta, brightCyan, brightWhite
    case rgb(UInt8, UInt8, UInt8)
    case palette(UInt8)
}

// MARK: - ANSI Parser

final class ANSIParser {

    /// Parse raw terminal text into styled segments.
    static func parse(_ input: String) -> [ANSISegment] {
        var segments: [ANSISegment] = []
        var currentStyle = ANSIStyle.plain
        var buffer = ""
        var i = input.startIndex

        while i < input.endIndex {
            let ch = input[i]

            // ESC sequence
            if ch == "\u{1B}" {
                let next = input.index(after: i)
                if next < input.endIndex && input[next] == "[" {
                    // Flush buffer
                    if !buffer.isEmpty {
                        segments.append(ANSISegment(text: buffer, style: currentStyle))
                        buffer = ""
                    }
                    // Parse CSI
                    var j = input.index(after: next) // skip [
                    var params = ""
                    while j < input.endIndex {
                        let c = input[j]
                        if c.isLetter || c == "@" || c == "`" {
                            if c == "m" {
                                currentStyle = applyCSI(params, to: currentStyle)
                            }
                            // Skip other CSI commands (cursor moves, etc.)
                            i = input.index(after: j)
                            break
                        }
                        params.append(c)
                        j = input.index(after: j)
                    }
                    if j >= input.endIndex { i = j }
                    continue
                } else if next < input.endIndex && input[next] == "]" {
                    // OSC sequence -- skip until BEL or ST
                    var j = input.index(after: next)
                    while j < input.endIndex {
                        let c = input[j]
                        if c == "\u{07}" || c == "\u{1B}" {
                            if c == "\u{1B}" {
                                let afterST = input.index(after: j)
                                if afterST < input.endIndex && input[afterST] == "\\" {
                                    j = input.index(after: afterST)
                                }
                            } else {
                                j = input.index(after: j)
                            }
                            break
                        }
                        j = input.index(after: j)
                    }
                    i = j
                    continue
                }
            }

            // Carriage return handling
            if ch == "\r" {
                i = input.index(after: i)
                continue
            }

            buffer.append(ch)
            i = input.index(after: i)
        }

        if !buffer.isEmpty {
            segments.append(ANSISegment(text: buffer, style: currentStyle))
        }

        return segments
    }

    // MARK: - SGR parameter application

    private static func applyCSI(_ params: String, to style: ANSIStyle) -> ANSIStyle {
        var s = style
        let codes = params.split(separator: ";").compactMap { Int($0) }

        if codes.isEmpty {
            return .plain
        }

        var idx = 0
        while idx < codes.count {
            let code = codes[idx]
            switch code {
            case 0:  s = .plain
            case 1:  s.bold = true
            case 2:  s.dim = true
            case 3:  s.italic = true
            case 4:  s.underline = true
            case 9:  s.strikethrough = true
            case 22: s.bold = false; s.dim = false
            case 23: s.italic = false
            case 24: s.underline = false
            case 29: s.strikethrough = false

            // Standard foreground
            case 30: s.foreground = .black
            case 31: s.foreground = .red
            case 32: s.foreground = .green
            case 33: s.foreground = .yellow
            case 34: s.foreground = .blue
            case 35: s.foreground = .magenta
            case 36: s.foreground = .cyan
            case 37: s.foreground = .white
            case 39: s.foreground = .default

            // Standard background
            case 40: s.background = .black
            case 41: s.background = .red
            case 42: s.background = .green
            case 43: s.background = .yellow
            case 44: s.background = .blue
            case 45: s.background = .magenta
            case 46: s.background = .cyan
            case 47: s.background = .white
            case 49: s.background = .defaultBG

            // Bright foreground
            case 90: s.foreground = .brightBlack
            case 91: s.foreground = .brightRed
            case 92: s.foreground = .brightGreen
            case 93: s.foreground = .brightYellow
            case 94: s.foreground = .brightBlue
            case 95: s.foreground = .brightMagenta
            case 96: s.foreground = .brightCyan
            case 97: s.foreground = .brightWhite

            // Bright background
            case 100...107: break // handled similarly if needed

            // Extended foreground: 38;5;N or 38;2;R;G;B
            case 38:
                if idx + 1 < codes.count && codes[idx + 1] == 5 && idx + 2 < codes.count {
                    s.foreground = .palette(UInt8(clamping: codes[idx + 2]))
                    idx += 2
                } else if idx + 1 < codes.count && codes[idx + 1] == 2 && idx + 4 < codes.count {
                    s.foreground = .rgb(
                        UInt8(clamping: codes[idx + 2]),
                        UInt8(clamping: codes[idx + 3]),
                        UInt8(clamping: codes[idx + 4])
                    )
                    idx += 4
                }

            // Extended background: 48;5;N or 48;2;R;G;B
            case 48:
                if idx + 1 < codes.count && codes[idx + 1] == 5 && idx + 2 < codes.count {
                    s.background = .palette(UInt8(clamping: codes[idx + 2]))
                    idx += 2
                } else if idx + 1 < codes.count && codes[idx + 1] == 2 && idx + 4 < codes.count {
                    s.background = .rgb(
                        UInt8(clamping: codes[idx + 2]),
                        UInt8(clamping: codes[idx + 3]),
                        UInt8(clamping: codes[idx + 4])
                    )
                    idx += 4
                }

            default: break
            }
            idx += 1
        }
        return s
    }
}
