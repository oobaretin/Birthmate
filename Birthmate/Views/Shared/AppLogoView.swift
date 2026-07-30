import SwiftUI

struct AppLogoView: View {
    var size: CGFloat = 120
    var cornerRadius: CGFloat? = nil
    var showsShadow: Bool = true

    private var resolvedCornerRadius: CGFloat {
        cornerRadius ?? size * 0.22
    }

    var body: some View {
        Image("AppLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: resolvedCornerRadius, style: .continuous))
            .shadow(
                color: showsShadow ? Color.black.opacity(0.12) : .clear,
                radius: 10,
                y: 4
            )
    }
}

#Preview {
    AppLogoView()
        .padding()
}
