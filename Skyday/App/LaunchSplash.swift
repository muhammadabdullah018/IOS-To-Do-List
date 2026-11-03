import SwiftUI

/// Short brand moment after the system launch screen: the moon morphs into the sun over a
/// pixel cloud, then the overlay fades away (about 0.9 s). Never blocks touches; skipped
/// for Reduce Motion and UI tests.
struct LaunchSplash: View {
    @Binding var isVisible: Bool
    @State private var isDay = false
    @State private var rise = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [SkyColor.sky, SkyColor.lightSky], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: Space.md) {
                ZStack(alignment: .topTrailing) {
                    PixelSprite(sprite: Sprite.cloudLarge, pixel: 5)
                    Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(isDay ? SkyColor.pink : Color.white)
                        .contentTransition(.symbolEffect(.replace.downUp))
                        .offset(x: 14, y: -30)
                }
                Text("Skyday")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.white)
                    .shadow(color: SkyColor.skyTextShadow, radius: 3, x: 0, y: 2)
            }
            .offset(y: rise ? -8 : 8)
            .opacity(rise ? 1 : 0.6)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            withAnimation(.easeOut(duration: 0.35)) { rise = true }
            try? await Task.sleep(nanoseconds: 250_000_000)
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { isDay = true }
            try? await Task.sleep(nanoseconds: 650_000_000)
            withAnimation(.easeInOut(duration: 0.3)) { isVisible = false }
        }
    }
}
