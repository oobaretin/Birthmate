import AuthenticationServices
import CryptoKit
import Foundation

enum AppleSignInNonce {
    static func random(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        result.reserveCapacity(length)
        for _ in 0..<length {
            result.append(charset.randomElement()!)
        }
        return result
    }

    static func sha256(_ value: String) -> String {
        let input = Data(value.utf8)
        let hashed = SHA256.hash(data: input)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum AppleSignInErrorHelper {
    static func message(for error: Error) -> String {
        let nsError = error as NSError
        guard nsError.domain == ASAuthorizationError.errorDomain else {
            return error.localizedDescription
        }

        switch nsError.code {
        case ASAuthorizationError.canceled.rawValue:
            return """
            Apple Sign In was canceled (error 1001). This often happens on the simulator even when you enter your password.

            Try these steps in order:
            1. In Xcode → Birthmate target → Signing & Capabilities, select your Apple ID Team (not “None”).
            2. Confirm “Sign in with Apple” appears under Capabilities.
            3. On the simulator: Settings → Apple Account — sign in (or sign out and back in).
            4. Delete Birthmate from the simulator, then Product → Clean Build Folder and run again.
            5. If it still fails, try on a real iPhone — Sign in with Apple is much more reliable there.
            """

        case ASAuthorizationError.unknown.rawValue:
            return """
            Apple Sign In failed (error 1000). In Xcode, open Birthmate → Signing & Capabilities, confirm your Team is selected and “Sign in with Apple” is added. Then clean build, delete the app from the simulator, and run again.
            """

        case ASAuthorizationError.failed.rawValue:
            return """
            Apple Sign In failed (error 1004). Check that your Team is set in Xcode Signing & Capabilities, then try again on a real device if the simulator keeps failing.
            """

        default:
            return "Apple Sign In failed (error \(nsError.code)). \(error.localizedDescription)"
        }
    }
}
