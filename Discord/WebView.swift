import SwiftUI
@preconcurrency import WebKit

struct WebView: NSViewRepresentable {
    var channelClickWidth: CGFloat
    var initialURL: String
    var customCSS: String?
    @Binding var webViewReference: WKWebView?
    @AppStorage("FakeNitro") var fakeNitro: Bool = false
    @AppStorage("SilentTyping") var silentTyping: Bool = false  // Ajouté pour synchroniser avec l'état de SilentTyping
    
    // CSS par défaut
    private let defaultCSS = """
    :root {
        --background-accent: rgb(0, 0, 0, 0.5) !important;
        --background-floating: transparent !important;
        --background-message-highlight: transparent !important;
        --background-message-highlight-hover: transparent !important;
        --background-message-hover: transparent !important;
        --background-mobile-primary: transparent !important;
        --background-mobile-secondary: transparent !important;
        --background-modifier-accent: transparent !important;
        --background-modifier-active: transparent !important;
        --background-modifier-hover: transparent !important;
        --background-modifier-selected: transparent !important;
        --background-nested-floating: transparent !important;
        --background-primary: transparent !important;
        --background-secondary: transparent !important;
        --background-secondary-alt: transparent !important;
        --background-tertiary: transparent !important;
        --bg-overlay-3: transparent !important;
        --channeltextarea-background: transparent !important;
    }
    """
    
    init(channelClickWidth: CGFloat, initialURL: String, customCSS: String? = nil) {
        self.channelClickWidth = channelClickWidth
        self.initialURL = initialURL
        self.customCSS = customCSS
        self._webViewReference = .constant(nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.applicationNameForUserAgent = "Version/17.2.1 Safari/605.1.15"
        
        // Activation de la capture des médias
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = true
        
        // WebView
        let webView = WKWebView(frame: .zero, configuration: config)
        DispatchQueue.main.async {
            webViewReference = webView
        }
        
        context.coordinator.webView = webView
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        
        // Ajouter le CSS
        let cssToUse = customCSS ?? defaultCSS
        let initialScript = WKUserScript(source: """
            const style = document.createElement('style');
            style.textContent = `\(cssToUse)`;
            document.head.appendChild(style);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(initialScript)
        
        // Injection de l'état initial de SilentTyping
        let initialSilentTypingScript = """
        window.silentTypingEnabled = \(silentTyping ? "true" : "false");
        """
        let silentTypingUserScript = WKUserScript(source: initialSilentTypingScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(silentTypingUserScript)
        
        // Charger l'URL ou afficher une erreur
        if let url = URL(string: initialURL) {
            webView.load(URLRequest(url: url))
        } else {
            let errorHTML = """
            <html>
              <body>
                <h2>Invalid URL</h2>
                <p>The provided URL could not be parsed.</p>
              </body>
            </html>
            """
            webView.loadHTMLString(errorHTML, baseURL: nil)
        }
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Aucun changement nécessaire dans updateNSView pour le moment
    }
}

extension WebView {
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        weak var webView: WKWebView?

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let messageBody = message.body as? [String: Any], let type = messageBody["type"] as? String else {
                return
            }
            
            if type == "channel" {
                print("Channel clicked!")
            } else if type == "user" {
                if let url = messageBody["url"] as? String {
                    print("User clicked link:", url)
                }
            } else if type == "server" {
                print("Server icon clicked!")
            }
        }
    }
}
