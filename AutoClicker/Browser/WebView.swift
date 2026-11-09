import SwiftUI
import WebKit

/// Affiche le WKWebView du BrowserController (réutilisé, jamais recréé).
struct WebView: UIViewRepresentable {
    let browser: BrowserController

    func makeUIView(context: Context) -> WKWebView {
        browser.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
