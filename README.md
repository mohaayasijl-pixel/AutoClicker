# Auto Clicker pour iPhone

Application iOS en Swift / SwiftUI (iOS 17 minimum, prévue pour l'iPhone 16 et iOS 18/26).

---

## 1. Ce qui marche, ce qu'Apple interdit

iOS isole chaque application : **aucune API publique ne permet à une app de toucher l'écran d'une autre app.**
Les seuls moyens de le faire (jailbreak, API privées, failles) sont exclus de ce projet. L'app est donc construite
autour de ce qui est réellement possible.

| Fonction demandée | Statut | Comment |
|---|---|---|
| Clics répétés, intervalle réglable (ms) | ✅ Fonctionne | Dans le navigateur intégré à l'app |
| Nombre de clics ou mode illimité | ✅ Fonctionne | Réglage par profil |
| Démarrer / pause / reprendre / arrêter | ✅ Fonctionne | Bouton flottant |
| Plusieurs points, séquence, délai par point | ✅ Fonctionne | Mode « Séquence » |
| Bouton flottant déplaçable | ✅ Dans l'app | Se cale sur les bords, position mémorisée |
| Profils (créer, modifier, dupliquer, supprimer, charger) | ✅ Fonctionne | Sauvegarde automatique en JSON |
| Raccourcis / Siri : « Démarrer un profil », « Arrêter » | ✅ Fonctionne | App Intents |
| Cliquer dans **une autre app** (jeu, Roblox, Instagram…) | ❌ Interdit par iOS | Alternative : Contrôle de sélection / AssistiveTouch (guide intégré) |
| Bouton flottant **par-dessus les autres apps** | ❌ Interdit par iOS | Pas d'équivalent aux surcouches Android |
| Fonctionner app fermée / en arrière-plan | ❌ Interdit par iOS | L'auto-clic se met en pause, l'écran reste allumé pendant l'usage |
| Créer une recette d'accessibilité automatiquement | ❌ Interdit par iOS | Configuration manuelle guidée dans l'app |
| Raccourcis qui « touchent » l'écran | ❌ N'existe pas | Raccourcis peut seulement lancer un profil dans l'app |
| Recopie de l'iPhone sur Mac + auto-clic Mac | ❌ En Belgique | Apple ne propose pas cette fonction dans l'Union européenne |

### Où l'auto-clic agit vraiment
Dans le **navigateur intégré** de l'app : sites web, jeux web « clicker », formulaires, pages HTML5.
L'app envoie à la page les événements standards (pointer, mouse, click, et touch en option) à l'endroit exact du point.

Limites honnêtes :
- Les événements créés par script sont marqués « non fiables » (`isTrusted = false`). La plupart des pages les acceptent ; un site peut décider de les ignorer.
- Les contenus dans une iframe d'un autre domaine (certaines pubs ou jeux intégrés) ne peuvent pas être cliqués.
- Le rythme réel peut être légèrement plus lent que le réglage si la page est lourde (minimum 20 ms entre deux actions).

### Pour les autres apps : outils officiels d'Apple
Le guide dans l'app (menu ••• → « Ce qui est possible sur iOS ») explique pas à pas, en s'adaptant au profil actif :
- **Contrôle de sélection → Recettes → Geste personnalisé** : rejoue une suite de taps enregistrée, à chaque déclenchement.
- **AssistiveTouch → Créer un geste** : même principe, relancé depuis le bouton rond.

Ces deux outils ne bouclent pas à l'infini tout seuls ; c'est la limite fixée par Apple.

---

## 2. Installer sur l'iPhone 16

Il faut compiler l'app avec Xcode, qui ne tourne que sur macOS. Deux façons :

### Option A — Avec un Mac (le plus simple)
1. Installer **Xcode 16** ou plus récent (App Store, gratuit).
2. Ouvrir `AutoClicker.xcodeproj`.
3. Xcode → Réglages → Comptes : ajouter votre identifiant Apple (gratuit).
4. Cliquer sur le projet → cible **AutoClicker** → **Signing & Capabilities** → *Team* : choisir votre « Personal Team ».
   Si Xcode signale que l'identifiant est pris, remplacer `com.veyl.autoclicker` par un autre (ex. `com.votrenom.autoclicker`).
5. Brancher l'iPhone, le choisir en haut de Xcode, puis ▶︎ (Cmd+R).
6. Sur l'iPhone :
   - Réglages → Confidentialité et sécurité → **Mode développeur** → activer (redémarrage demandé).
   - Réglages → Général → **VPN et gestion de l'appareil** → faire confiance à votre profil développeur.

### Option B — Sans Mac (PC Windows)
Le dossier `.github/workflows/build.yml` fait compiler l'app sur un Mac de GitHub, gratuitement.
1. Créer un compte et un dépôt sur github.com, puis y envoyer tout ce dossier (bouton « Add file → Upload files »).
2. Onglet **Actions** : le build se lance tout seul (sinon « Build » → « Run workflow »). Il exécute aussi les tests.
3. À la fin, télécharger l'artefact **AutoClicker-ipa** (un zip contenant `AutoClicker.ipa`).
4. Installer **Sideloadly** sur le PC (avec iTunes et iCloud version site Apple), brancher l'iPhone,
   glisser `AutoClicker.ipa`, saisir votre identifiant Apple, cliquer *Start*.
5. Sur l'iPhone : activer le Mode développeur et faire confiance au profil (voir option A, étape 6).

Avec un identifiant Apple gratuit, l'app doit être réinstallée **tous les 7 jours** (règle d'Apple).

---

## 3. Utilisation

1. Au premier lancement, la **page de test** s'ouvre avec deux profils prêts : appuyez sur le bouton turquoise.
   Le compteur de la page doit monter : c'est la preuve que l'auto-clic fonctionne sur votre iPhone.
2. Tapez une adresse dans la barre du haut pour ouvrir un autre site.
3. **Maintenez** le bouton flottant → main → touchez l'écran pour placer les points (glisser pour déplacer,
   maintenir un point pour le supprimer en mode séquence).
4. **Toucher** le bouton flottant : démarrer → pause → reprendre. Maintenir → Arrêter.
5. Le nom du profil en haut à gauche ouvre la liste des profils (charger, modifier, dupliquer, supprimer).
6. Dans l'app **Raccourcis**, les actions « Démarrer un profil » et « Arrêter l'auto-clic » sont disponibles,
   ainsi que Siri : « Démarrer *nom du profil* avec Auto Clicker ».

Bouton flottant :
- turquoise ▶︎ = prêt, sombre ⏸ = en cours, ambre ▶︎ = en pause, chiffre = compte à rebours ;
- pastille = nombre de clics réussis ; onde rouge = rien sous le point.

---

## 4. Tests

`AutoClickerTests` (20 tests XCTest) vérifie :
- la construction des séquences (appuis multiples, délais par point, minimum de 20 ms) ;
- le moteur : arrêt après N clics, ordre des points, pause / reprise / arrêt, compte à rebours, régularité du rythme ;
- les profils : sauvegarde automatique, rechargement, duplication, noms uniques, suppression sûre ;
- l'analyse des adresses et le script de clic.

Lancer : Xcode → Product → Test (Cmd+U), ou automatiquement via GitHub Actions (option B).

**Test sur appareil réel :** ce projet a été écrit sans Mac ni iPhone à disposition, il n'a donc pas encore été compilé ni testé
sur un iPhone. La page de test intégrée sert à cette vérification : si le compteur monte, tout fonctionne.
Si Xcode affiche une erreur à la compilation, copiez-la telle quelle pour la corriger.

---

## 5. Architecture

```
AutoClicker/
├── App/
│   ├── AutoClickerApp.swift      Point d'entrée, pause auto en arrière-plan
│   └── AppState.swift            État partagé : profils + moteur + navigateur
├── Models/
│   ├── ClickPoint.swift          Point normalisé (0…1), appuis, délais
│   ├── ClickProfile.swift        Profil complet + profils de départ
│   └── ProfileStore.swift        Persistance JSON, sauvegarde automatique
├── Engine/
│   ├── ClickPlan.swift           Profil → liste d'actions (logique pure)
│   ├── ClickEngine.swift         Exécution : start / pause / resume / stop, rythme régulier
│   └── ClickTarget.swift         Protocole de la cible des clics
├── Browser/
│   ├── BrowserController.swift   WKWebView, navigation, exécution des clics
│   ├── TapScript.swift           JavaScript qui simule l'appui dans la page
│   ├── TestPage.swift            Page de test hors ligne
│   └── WebView.swift             Pont SwiftUI ↔ WKWebView
├── Views/
│   ├── ClickerScreen.swift       Écran principal
│   ├── FloatingControl.swift     Bouton flottant
│   ├── PointsOverlay.swift       Placement des points, retour visuel
│   ├── ProfilesView.swift        Liste des profils
│   ├── ProfileEditorView.swift   Réglages d'un profil
│   ├── GuideView.swift           Possible / interdit, guides d'accessibilité
│   └── Theme.swift               Couleurs, champ numérique
└── Intents/
    └── AutoClickerIntents.swift  Raccourcis et Siri
```

Le moteur ne dépend que du protocole `ClickTarget` : il est testé avec une cible factice, et le navigateur
n'est qu'une implémentation de ce protocole. Les positions sont normalisées, donc un profil reste valable
en portrait comme en paysage, sur toutes les tailles d'iPhone.
