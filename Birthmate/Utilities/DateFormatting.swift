import Foundation

enum DateFormatting {
    static func birthdate(month: Int, day: Int) -> String {
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(.dateTime.month(.wide).day())
    }

    static func birthdateShort(month: Int, day: Int) -> String {
        "\(Calendar.current.monthSymbols[month - 1]) \(day)"
    }
}

enum AgentDebugLog {
    private static let endpoint = URL(string: "http://127.0.0.1:7727/ingest/f04f601e-4ddf-4c7b-a263-2e4ae7e5c11c")!

    static func log(location: String, message: String, data: [String: String] = [:], hypothesisId: String) {
        #if DEBUG
        // #region agent log
        let payload: [String: Any] = [
            "sessionId": "80e2dc",
            "location": location,
            "message": message,
            "data": data,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "hypothesisId": hypothesisId
        ]
        guard JSONSerialization.isValidJSONObject(payload),
              let body = try? JSONSerialization.data(withJSONObject: payload),
              let line = String(data: body, encoding: .utf8) else { return }

        if let doc = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let file = doc.appendingPathComponent("debug-80e2dc.log")
            if let handle = try? FileHandle(forWritingTo: file) {
                handle.seekToEndOfFile()
                handle.write((line + "\n").data(using: .utf8)!)
                try? handle.close()
            } else {
                try? (line + "\n").write(to: file, atomically: true, encoding: .utf8)
            }
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("80e2dc", forHTTPHeaderField: "X-Debug-Session-Id")
        request.httpBody = body
        URLSession.shared.dataTask(with: request).resume()
        // #endregion
        #endif
    }
}
