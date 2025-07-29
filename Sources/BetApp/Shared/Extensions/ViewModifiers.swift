import SwiftUI

// MARK: - Bounce Effect Modifier
struct BounceEffect: ViewModifier {
    let value: Int
    
    func body(content: Content) -> some View {
        if #available(macOS 14.0, iOS 17.0, *) {
            content
                .symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

// MARK: - Navigation Bar Placement
extension ToolbarItemPlacement {
    static var leadingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarLeading
        #else
        return .navigation
        #endif
    }
    
    static var trailingBar: ToolbarItemPlacement {
        #if os(iOS)
        return .navigationBarTrailing
        #else
        return .automatic
        #endif
    }
}

// MARK: - Page Tab View Style
struct PlatformPageTabViewStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        #else
        content
            .tabViewStyle(DefaultTabViewStyle())
        #endif
    }
}

extension View {
    func platformPageTabViewStyle() -> some View {
        self.modifier(PlatformPageTabViewStyle())
    }
}