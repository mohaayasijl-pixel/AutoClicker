import Foundation

/// Script injecté dans chaque page du navigateur intégré.
/// Il simule un appui en envoyant les événements DOM standards
/// (pointer, mouse, click et, en option, touch) à l'élément situé au point demandé.
///
/// Limite : ces événements sont « non fiables » (isTrusted = false) aux yeux de la page.
/// La grande majorité des pages et jeux web les acceptent, mais un site peut choisir de les ignorer.
enum TapScript {
    static let source = """
    (function () {
      if (window.__autoClicker) { return; }

      function fire(el, Ctor, type, x, y, extra) {
        try {
          var init = {
            bubbles: true, cancelable: true, composed: true, view: window,
            clientX: x, clientY: y, screenX: x, screenY: y,
            button: 0, buttons: /down$/.test(type) ? 1 : 0
          };
          if (extra) { for (var k in extra) { init[k] = extra[k]; } }
          el.dispatchEvent(new Ctor(type, init));
        } catch (e) {}
      }

      function fireTouch(el, x, y) {
        try {
          if (!window.Touch || !window.TouchEvent) { return; }
          var t = new Touch({
            identifier: Date.now(), target: el,
            clientX: x, clientY: y, screenX: x, screenY: y,
            pageX: x + window.scrollX, pageY: y + window.scrollY,
            radiusX: 1, radiusY: 1, force: 0.5
          });
          var base = { bubbles: true, cancelable: true, composed: true };
          el.dispatchEvent(new TouchEvent('touchstart', Object.assign({}, base,
            { touches: [t], targetTouches: [t], changedTouches: [t] })));
          el.dispatchEvent(new TouchEvent('touchend', Object.assign({}, base,
            { touches: [], targetTouches: [], changedTouches: [t] })));
        } catch (e) {}
      }

      window.__autoClicker = {
        tap: function (nx, ny, withTouch) {
          var vv = window.visualViewport;
          var x = vv ? vv.offsetLeft + nx * vv.width : nx * window.innerWidth;
          var y = vv ? vv.offsetTop + ny * vv.height : ny * window.innerHeight;
          var el = document.elementFromPoint(x, y);
          if (!el) { return false; }
          var p = { pointerId: 1, pointerType: 'touch', isPrimary: true,
                    width: 1, height: 1, pressure: 0.5 };
          var hasPointer = typeof window.PointerEvent === 'function';
          if (hasPointer) { fire(el, PointerEvent, 'pointerdown', x, y, p); }
          if (withTouch) { fireTouch(el, x, y); }
          fire(el, MouseEvent, 'mousedown', x, y);
          if (hasPointer) { fire(el, PointerEvent, 'pointerup', x, y, Object.assign({}, p, { pressure: 0 })); }
          fire(el, MouseEvent, 'mouseup', x, y);
          fire(el, MouseEvent, 'click', x, y);
          return true;
        }
      };
    })();
    """

    /// Appel JavaScript pour un appui au point normalisé.
    static func tapCall(x: Double, y: Double, touch: Bool) -> String {
        let nx = min(max(x, 0), 1)
        let ny = min(max(y, 0), 1)
        return "window.__autoClicker ? window.__autoClicker.tap(\(nx), \(ny), \(touch)) : false"
    }
}
