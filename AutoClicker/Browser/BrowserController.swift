import Foundation
import WebKit
import Observation

/// Navigateur intégré : c'est la zone où l'auto-clic agit réellement.
@MainActor
@Observable
final class BrowserController: ClickTarget {
    private(set) var addressText: String = ""
    private(set) var pageTitle: String = ""
    private(set) var isLoading = false
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    private(set) var lastError: String?
    private(set) var isTestPage = false

    let webView: WKWebView
    private let navigationDelegate = NavigationDelegate()
    @ObservationIgnored private var pendingCompletion: ((Bool) -> Void)?

    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let script = WKUserScript(source: TapScript.source,
                                  injectionTime: .atDocumentStart,
                                  forMainFrameOnly: true)
        configuration.userContentController.addUserScript(script)

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .black

        navigationDelegate.owner = self
        webView.navigationDelegate = navigationDelegate
    }

    // MARK: - Navigation

    /// Ouvre une adresse, un domaine (« exemple.com »), une recherche, ou la page de test.
    func load(_ text: String, completion: ((Bool) -> Void)? = nil) {
        pendingCompletion?(false)
        pendingCompletion = completion
        lastError = nil

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if TestPage.matches(trimmed) {
            isTestPage = true
            addressText = TestPage.urlString
            webView.loadHTMLString(TestPage.html, baseURL: nil)
            return
        }
        isTestPage = false
        guard let url = Self.url(from: trimmed) else {
            finish(success: false, error: "Adresse invalide")
            return
        }
        addressText = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    func reload() {
        if isTestPage { load(TestPage.urlString) } else { webView.reload() }
    }

    func goBack() { webView.goBack() }
    func goForward() { webView.goForward() }

    /// Transforme le texte saisi en URL : adresse complète, domaine ou recherche.
    nonisolated static func url(from text: String) -> URL? {
        if let url = URL(string: text), let scheme = url.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            return url
        }
        if !text.contains(" "), text.contains("."), let url = URL(string: "https://" + text) {
            return url
        }
        var components = URLComponents(string: "https://www.google.com/search")
        components?.queryItems = [URLQueryItem(name: "q", value: text)]
        return components?.url
    }

    // MARK: - ClickTarget

    func performTap(at point: CGPoint, sendTouchEvents: Bool) async -> Bool {
        guard webView.window != nil else { return false }
        let js = TapScript.tapCall(x: Double(point.x), y: Double(point.y), touch: sendTouchEvents)
        return await withCheckedContinuation { continuation in
            webView.evaluateJavaScript(js) { result, _ in
                continuation.resume(returning: (result as? Bool) ?? false)
            }
        }
    }

    // MARK: - Retours du WKWebView

    fileprivate func didStart() {
        isLoading = true
    }

    fileprivate func didFinish() {
        refreshState()
        finish(success: true, error: nil)
    }

    fileprivate func didFail(_ error: Error) {
        let nsError = error as NSError
        // Navigation annulée par une autre (clic sur un lien pendant le chargement) : pas une erreur.
        if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled { return }
        refreshState()
        finish(success: false, error: error.localizedDescription)
    }

    private func refreshState() {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        pageTitle = webView.title ?? ""
        if let url = webView.url, url.absoluteString != "about:blank" {
            isTestPage = false
            addressText = url.absoluteString
        } else if isTestPage {
            addressText = TestPage.urlString
            pageTitle = "Page de test"
        }
    }

    private func finish(success: Bool, error: String?) {
        isLoading = false
        lastError = error
        let completion = pendingCompletion
        pendingCompletion = nil
        completion?(success)
    }
}

/// Délégué séparé pour garder BrowserController indépendant de NSObject.
private final class NavigationDelegate: NSObject, WKNavigationDelegate {
    weak var owner: BrowserController?

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        MainActor.assumeIsolated { owner?.didStart() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        MainActor.assumeIsolated { owner?.didFinish() }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        MainActor.assumeIsolated { owner?.didFail(error) }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        MainActor.assumeIsolated { owner?.didFail(error) }
    }
}
