import SwiftUI

enum PanelDetent: CGFloat, Hashable {
    case peek = 0.15
    case half = 0.4
    case full = 0.85

    static let ordered: [PanelDetent] = [.peek, .half, .full]
}

struct BottomPanel<Content: View>: View {
    @Binding var detent: PanelDetent
    @ViewBuilder let content: () -> Content

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let panelHeight = height * detent.rawValue
            let adjusted = min(max(panelHeight - dragOffset, height * 0.1), height * 0.9)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 0) {
                    // Drag handle
                    Capsule()
                        .fill(.secondary.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 8)

                    content()
                        .frame(maxHeight: .infinity)
                        .clipped()
                }
                .frame(height: adjusted)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 20, topTrailingRadius: 20))
                .shadow(color: .black.opacity(0.1), radius: 8, y: -4)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let dragFraction = value.translation.height / height
                            let projected = detent.rawValue - dragFraction

                            let target = PanelDetent.ordered.min {
                                abs($0.rawValue - projected) < abs($1.rawValue - projected)
                            } ?? .peek

                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                detent = target
                                dragOffset = 0
                            }
                        }
                )
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: detent)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}
