import SwiftUI

/// An extension to `Color` to allow initialization from hex strings and numeric hex literals.
public extension Color {
    
    /// Creates a `Color` from a hex string representation.
    ///
    /// Supported formats:
    /// - `#RRGGBB`, `RRGGBB`
    /// - `#RGB`, `RGB` (3-digit shorthand, expanded to 6-digit)
    /// - `#RRGGBBAA`, `RRGGBBAA` (8-digit with alpha channel)
    ///
    /// Alpha parameter is optional and overrides any alpha in an 8-digit hex string.
    ///
    /// If parsing fails, the returned color is `.magenta`.
    ///
    /// - Parameters:
    ///   - hex: The hex string representing the color.
    ///   - alpha: Optional alpha multiplier (0...1), default is 1.0.
    init(hex: String, alpha: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let strippedHex: String
        
        if hex.hasPrefix("#") {
            strippedHex = String(hex.dropFirst())
        } else if hex.hasPrefix("0x") {
            strippedHex = String(hex.dropFirst(2))
        } else {
            strippedHex = hex
        }
        
        func hexDigitToInt(_ c: Character) -> Int? {
            switch c {
            case "0"..."9":
                return Int(String(c))
            case "a"..."f":
                return 10 + Int(c.asciiValue! - Character("a").asciiValue!)
            default:
                return nil
            }
        }
        
        func parseHexComponent(_ str: String) -> Double? {
            guard let intVal = Int(str, radix: 16) else { return nil }
            return Double(intVal) / 255.0
        }
        
        var r: Double = 0
        var g: Double = 0
        var b: Double = 0
        var a: Double = 1
        
        switch strippedHex.count {
        case 3:
            // Expand RGB shorthand (e.g. F0A -> FF00AA)
            let rStr = String(repeating: strippedHex[strippedHex.startIndex], count: 2)
            let gStr = String(repeating: strippedHex[strippedHex.index(strippedHex.startIndex, offsetBy: 1)], count: 2)
            let bStr = String(repeating: strippedHex[strippedHex.index(strippedHex.startIndex, offsetBy: 2)], count: 2)
            guard let rr = parseHexComponent(rStr),
                  let gg = parseHexComponent(gStr),
                  let bb = parseHexComponent(bStr) else {
                self = Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)
                return
            }
            r = rr
            g = gg
            b = bb
            a = 1
        case 6:
            // RRGGBB
            let rStr = String(strippedHex.prefix(2))
            let gStr = String(strippedHex.dropFirst(2).prefix(2))
            let bStr = String(strippedHex.dropFirst(4).prefix(2))
            guard let rr = parseHexComponent(rStr),
                  let gg = parseHexComponent(gStr),
                  let bb = parseHexComponent(bStr) else {
                self = Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)
                return
            }
            r = rr
            g = gg
            b = bb
            a = 1
        case 8:
            // RRGGBBAA
            let rStr = String(strippedHex.prefix(2))
            let gStr = String(strippedHex.dropFirst(2).prefix(2))
            let bStr = String(strippedHex.dropFirst(4).prefix(2))
            let aStr = String(strippedHex.dropFirst(6).prefix(2))
            guard let rr = parseHexComponent(rStr),
                  let gg = parseHexComponent(gStr),
                  let bb = parseHexComponent(bStr),
                  let aa = parseHexComponent(aStr) else {
                self = Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)
                return
            }
            r = rr
            g = gg
            b = bb
            a = aa
        default:
            // Unsupported format
            self = Color(.sRGB, red: 1, green: 0, blue: 1, opacity: 1)
            return
        }
        
        // Clamp alpha between 0 and 1 and multiply by any provided alpha
        let finalAlpha = min(max(a * alpha, 0), 1)
        
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: finalAlpha)
    }
    
    /// Creates a `Color` from a hex integer representation.
    ///
    /// - Parameters:
    ///   - hex: A 24-bit integer (0xRRGGBB)
    ///   - alpha: Optional alpha multiplier (0...1), default is 1.0.
    ///
    /// Usage:
    /// ```
    /// Color(hex: 0xFF0000) // Red
    /// Color(hex: 0x00FF00, alpha: 0.5) // 50% transparent green
    /// ```
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double(hex & 0x0000FF) / 255.0
        let clampedAlpha = min(max(alpha, 0), 1)
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: clampedAlpha)
    }
    
    /// Convenience static method for creating a `Color` from a hex string.
    ///
    /// Usage:
    /// ```
    /// let color = Color.hex("#3498db")
    /// let colorWithAlpha = Color.hex("3498db", alpha: 0.7)
    /// ```
    static func hex(_ hexString: String, alpha: Double = 1.0) -> Color {
        return Color(hex: hexString, alpha: alpha)
    }
    
    /// Convenience static method for creating a `Color` from a hex integer.
    ///
    /// Usage:
    /// ```
    /// let color = Color.hex(0x3498db)
    /// let colorWithAlpha = Color.hex(0x3498db, alpha: 0.7)
    /// ```
    static func hex(_ hexInt: UInt32, alpha: Double = 1.0) -> Color {
        return Color(hex: hexInt, alpha: alpha)
    }
}


/// Usage examples:
/*
let color1 = Color(hex: "#3498db")          // Blue color
let color2 = Color(hex: "3498db")           // Blue color without #
let color3 = Color(hex: "#3ab")             // Shorthand RGB (#33aabb)
let color4 = Color(hex: "3ab")              // Shorthand RGB without #
let color5 = Color(hex: "#3498dbcc")        // Blue color with alpha from hex (0xcc)
let color6 = Color(hex: "3498dbcc")         // Same with no #
let color7 = Color(hex: 0x3498db)            // Blue color from integer
let color8 = Color(hex: 0x3498db, alpha: 0.5) // Blue color with 50% opacity
let color9 = Color.hex("#ff0000")            // Static method usage
let color10 = Color.hex(0x00ff00, alpha: 0.3) // Static method with alpha
*/
