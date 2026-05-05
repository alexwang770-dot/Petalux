import SwiftUI
import Combine

struct HomeView: View {
    @ObservedObject var ble: BLEManager
    @State private var currentTab: PtTab = .schedule
    @State private var now = Date()

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack(alignment: .bottom) {
            // Full-bleed flower background
            flowerBackground

            // Content overlaid on top
            VStack(spacing: 0) {
                topBar
                clockBlock
                Spacer()
                bottomTabBar
            }
        }
        .ignoresSafeArea()
        .onReceive(timer) { t in now = t }
    }

    // MARK: Flower background

    var flowerBackground: some View {
        ZStack {
            // Warm cream base
            Color.ptCream.ignoresSafeArea()

            // Soft pink radial bloom behind flower
            RadialGradient(
                colors: [
                    Color.ptPink.opacity(0.55),
                    Color.ptPinkLight.opacity(0.3),
                    Color.ptCream.opacity(0.0)
                ],
                center: .init(x: 0.65, y: 0.55),
                startRadius: 20,
                endRadius: 260
            )
            .ignoresSafeArea()

            // Flower illustration (right-aligned, large)
            GeometryReader { geo in
                FlowerView(
                    isOpen: ble.lampState.isOpen,
                    ledColor: ble.lampState.color.swiftUIColor
                ) {
                    ble.send(ble.lampState.isOpen
                        ? .bloomClose(speed: 3)
                        : .bloomOpen(speed: 3))
                }
                .scaleEffect(2.2)
                .position(x: geo.size.width * 0.75, y: geo.size.height * 0.52)
                .opacity(0.85)
            }
        }
    }

    // MARK: Top bar

    var topBar: some View {
        HStack {
            Text("PETALUX")
                .font(.system(size: 13, weight: .semibold, design: .default))
                .tracking(3)
                .foregroundColor(.ptText)
            Spacer()
            connectionIndicator
        }
        .padding(.horizontal, 24)
        .padding(.top, 60)
        .padding(.bottom, 8)
    }

    var connectionIndicator: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(ble.connectionState == .connected ? Color.ptSage : Color.ptTextLight)
                .frame(width: 6, height: 6)
            Text(ble.connectionState == .connected ? "Connected" : "Disconnected")
                .font(.ptCaption)
                .foregroundColor(.ptTextMid)
        }
        .onTapGesture {
            if ble.connectionState == .disconnected { ble.startScanning() }
        }
    }

    // MARK: Clock block

    var clockBlock: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Big clock
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(hourMinute)
                    .font(Font.custom("Georgia", size: 64))
                    .foregroundColor(.ptText)
                    .monospacedDigit()
                Text(amPm)
                    .font(Font.custom("Georgia", size: 18))
                    .foregroundColor(.ptTextMid)
                    .padding(.bottom, 6)
            }
            // Date
            Text(dateString)
                .font(.ptCaption)
                .foregroundColor(.ptTextMid)
                .tracking(0.5)

            // Lamp state pill
            HStack(spacing: 6) {
                Circle()
                    .fill(ble.lampState.isOpen ? Color.ptSage : Color.ptPinkDeep)
                    .frame(width: 6, height: 6)
                Text(ble.lampState.isOpen ? "Flower Open" : "Flower Closed")
                    .font(.ptCaption)
                    .foregroundColor(ble.lampState.isOpen ? .ptSage : .ptPinkDeep)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((ble.lampState.isOpen ? Color.ptSage : Color.ptPinkDeep).opacity(0.1))
            .cornerRadius(20)
            .padding(.top, 6)
        }
        .padding(.horizontal, 28)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Bottom tab bar

    var bottomTabBar: some View {
        VStack(spacing: 0) {
            // Tab content panel
            Group {
                switch currentTab {
                case .schedule: ScheduleTabView(ble: ble)
                case .music:    MusicTabView(ble: ble)
                case .display:  DisplayTabView(ble: ble)
                }
            }
            .frame(height: 220)
            .background(Color.ptCream)

            // Tab strip
            HStack(spacing: 0) {
                ForEach(PtTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { currentTab = tab }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.rawValue)
                                .font(.ptTab)
                        }
                        .foregroundColor(currentTab == tab ? .ptPinkDeep : .ptTextLight)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.ptTabBg)
            .overlay(Rectangle().frame(height: 0.5).foregroundColor(.ptDivider), alignment: .top)
            .padding(.bottom, 20) // safe area
        }
    }

    // MARK: Time helpers

    var hourMinute: String {
        let f = DateFormatter(); f.dateFormat = "hh:mm"
        return f.string(from: now)
    }
    var amPm: String {
        let f = DateFormatter(); f.dateFormat = "a"
        return f.string(from: now).uppercased()
    }
    var dateString: String {
        let f = DateFormatter(); f.dateFormat = "MMM dd, yyyy • EEE"
        return f.string(from: now).uppercased()
    }
}

// MARK: - Preview
#Preview {
    HomeView(ble: BLEManager())
}
