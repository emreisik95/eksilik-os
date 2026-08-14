# Messages, Page Wheel, Ekşi Şeyler, Themes, and iPad Icons Design

## Goal

Finish the remaining 2.0.2 work as one coherent release: restore authenticated messages, make direct page selection swipeable, apply font-size changes immediately inside Settings, add a real native feed backed by `eksiseyler.com`, add ten distinctive themes, and satisfy Apple's alternate iPad icon requirements.

## Live contracts and root causes

The authenticated mobile message page currently renders `ul#threads > li > article` rows and `/mesaj/<numeric-id>` conversations under `#message-thread article`. The existing parsers already match both structures. The failing boundary is the request: Ekşi Sözlük returns the message document normally but rejects the same GET carrying `X-Requested-With: XMLHttpRequest`. Message list and conversation GETs therefore need document semantics, while message POST behavior remains unchanged.

`UserPreferences` mixes `@Published` state with `@AppStorage` properties inside an `ObservableObject`. Font size, filter style, server URL, and related settings persist, but they do not reliably publish changes to views holding the object through `@EnvironmentObject`. Persistent user-facing properties will use one observable storage path: `@Published` values initialized from the injected `UserDefaults`, with write-through persistence in `didSet`.

The existing “ekşi şeyler” entry filter is an Ekşi Sözlük topic scope (`a=eksiseyler`); it is not an implementation of `eksiseyler.com`. The real site exposes public editorial cards with stable hero, content-box, and mashup markup. A separate service and parser will model those cards without weakening or removing the existing entry filter.

## Page selection interaction

The compact first/previous/current/next/last chrome remains. Tapping the current-page capsule opens a bottom sheet centered on a native wheel picker. The wheel starts at the current page and can be swiped directly to any page from 1 through the total. First/current/last shortcuts provide fast anchors, and an explicit “git” action prevents accidental navigation while the wheel is still moving. The selection policy clamps every value and supplies deterministic anchors for tests and accessibility.

## Ekşi Şeyler experience

“şeyler” becomes a reorderable Home destination alongside gündem, bugün, and debe. Its screen is visually editorial rather than another topic list:

- a horizontal category rail for yeni, kültür, bilim, eğlence, yaşam, spor, and haber;
- a large lead card followed by compact image-led story cards;
- category and read-count metadata where the source exposes them;
- pull-to-refresh, retry, empty state, image placeholders, and deduplication;
- a WebKit-free native reader that renders the selected article's metadata, text, headings,
  quotes, lists, and preloaded full-screen images with the app's own theme.

The parser accepts only HTTP(S) links on `eksiseyler.com`, normalizes relative image URLs, extracts lazy-loaded and CSS-background images, and rejects navigation/category/footer links. Categories use the site's documented visible URLs rather than generated search guesses.

## Theme system

The five existing stored raw values remain untouched. Ten new values are appended so existing users never migrate to a different theme accidentally. A palette token centralizes surface, raised surface, recessed surface, accent, primary text, secondary text, separator, and scheme colors. The new themes are deliberately different in mood and contrast:

1. notebook — warm paper, ink, olive;
2. bosphorus — deep navy, turquoise;
3. burgundy — wine, rose;
4. terminal — phosphor green on near-black;
5. lilac — muted violet night;
6. solar dark — solarized dark;
7. solar light — solarized light;
8. ice — nordic blue-gray;
9. coffee — espresso, cream, copper;
10. high contrast — black, white, yellow.

All theme and icon-style display names remain English (`dark`, `light`, `oldschool`, and so on)
while their explanatory copy follows the app's Turkish interface language.

The picker uses a three-swatch palette preview rather than a single accent dot, making themes recognizable before selection. Theme names, stable raw values, palette completeness, and readable foreground/background contrast are covered by tests.

## Alternate iPad icons

Each alternate icon family gains explicit 76×76 (`~ipad`) and 152×152 (`@2x~ipad`) opaque PNGs generated from its existing artwork. `CFBundleIcons~ipad` mirrors the phone alternate-icon declarations. Release validation checks exact dimensions, opacity, plist declarations, and bundled resources, directly covering warning 90892.

## Release and safety

The release stays on marketing version 2.0.2 and receives the next unused build number. Tests are written before implementation, the platform-independent harness and full XCTest/coverage gates must pass, SwiftLint must remain clean, App Store preflight is rerun, and the final binary goes only to the internal TestFlight group. App Review submission and merge remain separate explicit actions.
