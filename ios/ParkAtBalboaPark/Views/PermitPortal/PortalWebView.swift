import SwiftUI
import WebKit

struct PortalWebView: UIViewRepresentable {
    let url: URL
    @Binding var currentURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(currentURL: $currentURL)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var currentURL: URL?

        init(currentURL: Binding<URL?>) {
            _currentURL = currentURL
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            currentURL = webView.url
        }
    }
}
