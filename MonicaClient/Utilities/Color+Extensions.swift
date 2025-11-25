//
//  Color+Extensions.swift
//  MonicaClient
//
//  Created for 001-003-avatar-authentication feature
//  Copyright © 2025 Monica Client. All rights reserved.
//

import SwiftUI

extension Color {
    /// Initialize Color from hex string
    /// Supports formats: "#RRGGBB", "#AARRGGBB", "RRGGBB", "hsl(h, s%, l%)"
    /// Falls back to gray for invalid formats
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle HSL format: hsl(h, s%, l%)
        if hex.hasPrefix("hsl(") {
            let hslString = hex
                .replacingOccurrences(of: "hsl(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "%", with: "")

            let components = hslString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

            if components.count == 3,
               let h = Double(components[0]),
               let s = Double(components[1]),
               let l = Double(components[2]) {
                self = Color(hue: h / 360.0, saturation: s / 100.0, brightness: l / 100.0)
                return
            }
        }

        // Handle hex format
        let hexSanitized = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            // Invalid hex format, default to gray
            self = .gray
            return
        }

        let length = hexSanitized.count
        let r, g, b, a: Double

        if length == 6 {
            // RRGGBB format
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            // AARRGGBB format
            a = Double((rgb & 0xFF000000) >> 24) / 255.0
            r = Double((rgb & 0x00FF0000) >> 16) / 255.0
            g = Double((rgb & 0x0000FF00) >> 8) / 255.0
            b = Double(rgb & 0x000000FF) / 255.0
        } else {
            // Invalid length, default to gray
            self = .gray
            return
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
