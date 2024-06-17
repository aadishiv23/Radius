//
//  Supabase.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/7/24.
//

import Foundation
import Supabase
import CryptoKit
import SwiftUI

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://hfpzogdypqzwcpwhfivx.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmcHpvZ2R5cHF6d2Nwd2hmaXZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE2NDc1NDQsImV4cCI6MjAyNzIyMzU0NH0.A3hRL_Ov_W_G0xS76ghUioujhO1_JV5-3bhUxW8eNUo"
)


let encoder: JSONEncoder = {
  let encoder = PostgrestClient.Configuration.jsonEncoder
  encoder.keyEncodingStrategy = .convertToSnakeCase
  return encoder
}()

let decoder: JSONDecoder = {
  let decoder = PostgrestClient.Configuration.jsonDecoder
  decoder.keyDecodingStrategy = .convertFromSnakeCase
  return decoder
}()

extension Color {
    init?(hex: String) {
        let r, g, b: Double
        var hexColor = hex
        
        // Remove the # prefix if it exists
        if hexColor.hasPrefix("#") {
            hexColor = String(hexColor.dropFirst())
        }
        
        // Ensure the hex color has the right length
        guard hexColor.count == 6 else {
            return nil
        }

        let scanner = Scanner(string: hexColor)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            r = Double((hexNumber & 0xff0000) >> 16) / 255
            g = Double((hexNumber & 0x00ff00) >> 8) / 255
            b = Double(hexNumber & 0x0000ff) / 255
            self.init(red: r, green: g, blue: b)
            return
        }

        return nil
    }
}
