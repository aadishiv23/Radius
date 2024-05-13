//
//  Supabase.swift
//  Radius
//
//  Created by Aadi Shiv Malhotra on 5/7/24.
//

import Foundation
import Supabase
import CryptoKit


let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://hfpzogdypqzwcpwhfivx.supabase.co")!,
  supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhmcHpvZ2R5cHF6d2Nwd2hmaXZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE2NDc1NDQsImV4cCI6MjAyNzIyMzU0NH0.A3hRL_Ov_W_G0xS76ghUioujhO1_JV5-3bhUxW8eNUo"
)


func hashPassword(_ password: String) -> String {
    let hashed = SHA256.hash(data: Data(password.utf8))
    
    // The hash result is a series of bytes. Each byte is an integer between 0 and 255.
    // This line converts each byte into a two-character hexadecimal string.
    // %x indicates hexadecimal formatting.
    // 02 ensures that the hexadecimal number is padded with zeros to always have two digits.
    // This is important because a byte represented in hexadecimal can have one or two digits (e.g., 0x3 or 0x03),
    // and consistent formatting requires two digits.
    // After converting all bytes to two-character strings, joined() concatenates all these strings into a single string, resulting in the final hashed password in hexadecimal form.
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
