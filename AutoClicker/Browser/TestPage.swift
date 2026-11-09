import Foundation

/// Page de test intégrée, utilisable hors ligne, pour vérifier que l'auto-clic marche.
/// Les éléments sont placés en pourcentage de l'écran : les profils de départ visent juste
/// quelle que soit la taille de l'iPhone.
enum TestPage {
    static let urlString = "autoclicker://test"

    /// Vrai si le texte désigne la page de test (vide, adresse interne, « test »…).
    static func matches(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return t.isEmpty || t == urlString || t == "test" || t == "page de test"
    }

    struct Position {
        let x: Double
        let y: Double
    }

    static let mainButton = Position(x: 0.5, y: 0.38)
    static let targets = [Position(x: 0.2, y: 0.72), Position(x: 0.5, y: 0.72), Position(x: 0.8, y: 0.72)]

    static var html: String {
        let targetsHTML = targets.enumerated().map { index, t in
            """
            <button class="target" data-i="\(index)" style="left:\(t.x * 100)%;top:\(t.y * 100)%">
              <span class="n">\(index + 1)</span><span class="c" id="t\(index)">0</span>
            </button>
            """
        }.joined(separator: "\n")

        return """
        <!doctype html>
        <html lang="fr"><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
        <title>Page de test</title>
        <style>
          :root { color-scheme: dark; }
          html, body { margin: 0; height: 100%; overflow: hidden; background: #0d0f14; color: #e8ebf2;
            font-family: -apple-system, system-ui, sans-serif; -webkit-user-select: none; user-select: none;
            -webkit-tap-highlight-color: transparent; }
          .hud { position: fixed; top: 6%; left: 0; right: 0; text-align: center; }
          .hud .total { font-size: 54px; font-weight: 800; letter-spacing: -1px; }
          .hud .label { font-size: 13px; opacity: .6; text-transform: uppercase; letter-spacing: 2px; }
          .hud .cps { margin-top: 6px; font-size: 15px; color: #5eead4; font-variant-numeric: tabular-nums; }
          .main { position: fixed; transform: translate(-50%, -50%); width: 46vw; height: 46vw; max-width: 220px; max-height: 220px;
            border-radius: 50%; border: none; color: #0d0f14; font-size: 22px; font-weight: 800;
            background: radial-gradient(circle at 35% 30%, #99f6e4, #14b8a6 70%); box-shadow: 0 0 0 10px rgba(20,184,166,.12); }
          .main.hit { transform: translate(-50%, -50%) scale(.94); }
          .target { position: fixed; transform: translate(-50%, -50%); width: 22vw; height: 22vw; max-width: 96px; max-height: 96px;
            border-radius: 22px; border: 2px solid #334155; background: #161a22; color: #e8ebf2; display: flex;
            flex-direction: column; align-items: center; justify-content: center; gap: 2px; }
          .target .n { font-size: 12px; opacity: .55; }
          .target .c { font-size: 22px; font-weight: 700; font-variant-numeric: tabular-nums; }
          .target.hit { border-color: #5eead4; }
          .reset { position: fixed; bottom: 6%; left: 50%; transform: translateX(-50%); padding: 10px 22px; border-radius: 999px;
            border: 1px solid #334155; background: transparent; color: #94a3b8; font-size: 14px; }
        </style></head>
        <body>
          <div class="hud">
            <div class="label">clics reçus</div>
            <div class="total" id="total">0</div>
            <div class="cps" id="cps">0 clic/s</div>
          </div>
          <button class="main" id="main" style="left:\(mainButton.x * 100)%;top:\(mainButton.y * 100)%">TAP</button>
          \(targetsHTML)
          <button class="reset" id="reset">Remettre à zéro</button>
        <script>
          var total = 0, counts = [0, 0, 0], stamps = [];
          var totalEl = document.getElementById('total'), cpsEl = document.getElementById('cps');
          function flash(el) { el.classList.add('hit'); setTimeout(function () { el.classList.remove('hit'); }, 80); }
          function count(el) {
            total++; stamps.push(Date.now()); totalEl.textContent = total; flash(el);
          }
          document.getElementById('main').addEventListener('click', function (e) { count(e.currentTarget); });
          Array.prototype.forEach.call(document.querySelectorAll('.target'), function (el) {
            el.addEventListener('click', function () {
              var i = +el.dataset.i; counts[i]++; document.getElementById('t' + i).textContent = counts[i]; count(el);
            });
          });
          document.getElementById('reset').addEventListener('click', function () {
            total = 0; counts = [0, 0, 0]; stamps = []; totalEl.textContent = '0';
            for (var i = 0; i < 3; i++) { document.getElementById('t' + i).textContent = '0'; }
          });
          setInterval(function () {
            var now = Date.now(); stamps = stamps.filter(function (s) { return now - s < 1000; });
            cpsEl.textContent = stamps.length + (stamps.length > 1 ? ' clics/s' : ' clic/s');
          }, 200);
        </script>
        </body></html>
        """
    }
}
