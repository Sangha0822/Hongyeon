//
//  AnniversaryClient.swift
//  Hongyeon
//

import Foundation

// Where AnniversaryView keeps the chosen day ("yyyy-MM-dd") until it's saved to the account.
let draftAnniversaryKey = "draftAnniversary"

// Turns the picked day into "yyyy-MM-dd" in the phone's own time zone, so the server stores
// the day the user tapped rather than the UTC day. Gregorian, so a phone set to another
// calendar (e.g. Buddhist) still sends the year the server expects.
let anniversaryFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

// Saves the signed-in user's anniversary. Returns whether the server accepted it.
func saveAnniversary(_ day: String) async -> Bool {
    guard let sessionToken = SessionStore.load() else { return false }

    let url = URL(string: "https://hongyeon-api.onrender.com/me/anniversary")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: ["anniversary": day])

    do {
        let (_, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        print("Save anniversary status: \(statusCode)")
        return statusCode == 200
    } catch {
        print("Save anniversary failed: \(error.localizedDescription)")
        return false
    }
}
