import SwiftUI

// MARK: - Flower shape (one petal as a Path)

struct PetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        path.move(to: CGPoint(x: w / 2, y: h))
        path.addCurve(
            to: CGPoint(x: w / 2, y: 0),
            control1: CGPoint(x: w * 1.1, y: h * 0.65),
            control2: CGPoint(x: w * 1.1, y: h * 0.35)
        )
        path.addCurve(
            to: CGPoint(x: w / 2, y: h),
            control1: CGPoint(x: w * -0.1, y: h * 0.35),
            control2: CGPoint(x: w * -0.1, y: h * 0.65)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Full Flower View

struct FlowerView: View {
    let isOpen: Bool
    let onTap: () -> Void

    private let petalCount = 6
    private let petalColors: [Color] = [
        Color(red: 0.973, green: 0.871, blue: 0.871), // blush #F8DEDE
        Color(red: 0.957, green: 0.820, blue: 0.820), // rose  #F4D1D1
        Color(red: 0.973, green: 0.871, blue: 0.871),
        Color(red: 0.957, green: 0.820, blue: 0.820),
        Color(red: 0.973, green: 0.871, blue: 0.871),
        Color(red: 0.957, green: 0.820, blue: 0.820),
    ]

    var body: some View {
        ZStack {
            // Ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.94, green: 0.78, blue: 0.55).opacity(0.3), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 140, height: 140)

            // Petals
            ForEach(0..<petalCount, id: \.self) { i in
                let angle = Double(i) * (360.0 / Double(petalCount)) - 90
                let openAngle = Angle(degrees: angle)
                let closedAngle = Angle(degrees: -90)

                PetalShape()
                    .fill(petalColors[i])
                    .opacity(0.88)
                    .frame(width: 22, height: 50)
                    .offset(y: isOpen ? -46 : -8)
                    .rotationEffect(isOpen ? openAngle : closedAngle, anchor: .center)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.72)
                        .delay(Double(i) * 0.04),
                        value: isOpen
                    )
            }

            // Center disc - warm cream
            Circle()
                .fill(Color(red: 0.965, green: 0.886, blue: 0.745))
                .frame(width: 28, height: 28)

            // Stem hint
            Circle()
                .fill(Color(red: 0.533, green: 0.576, blue: 0.475))
                .frame(width: 10, height: 10)
        }
        .frame(width: 140, height: 140)
        .contentShape(Circle())
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.08, green: 0.06, blue: 0.03).ignoresSafeArea()
        VStack(spacing: 32) {
            FlowerView(isOpen: true,  onTap: {})
            FlowerView(isOpen: false, onTap: {})
        }
    }
}
