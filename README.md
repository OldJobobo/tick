# PR #338 — actual file chooser visual evidence

These are captures of Flea's real Save dialog, not illustrated or reconstructed
controls. The GIF animates actual rendered frames after QtTest mouse clicks and
Ctrl+wheel events; it is not a continuous desktop recording.

## Provenance

- Before: upstream `main` at `f21789e56cc4b0877caa3156fff7bce52a8dd9c2`.
- After: PR #338 at `90e77dfbcaf60dd087c460c11ac970393b206cbc`.
- Real `PickerWindow.qml`, `PickerChrome.qml`, `PickerGrid.qml`, delegates and
  listing backend. The Rust source is identical between these revisions.
- Offscreen Qt Quick software rendering, 840 × 560, text size 14, the same fixed
  neutral dark palette and synthetic files/settings on both sides.
- Device/network discovery is stubbed to empty for privacy. The standard
  headless Commons fixture suppresses compositor reload events. No chooser
  controls or file rows are replaced with mock artwork.
- PNG interface pixels are unmodified. `compose.py` only crops the path-detail
  still and adds captions outside captured interface pixels.
- No desktop settings, installed Flea, portal registration or daily Tick bundle
  was changed to make these captures. This is chooser-rendering/input evidence,
  not a native portal/compositor or fractional-scaling test.

## What the captures prove

1. The path click does nothing before; the same Qt mouse click opens a selected
   path input afterwards.
2. The new eye control reveals `.env.example` and `.draft-notes.txt` in the actual
   directory listing. Both are excluded in the before capture.
3. Three Ctrl+wheel-up notches leave the old grid at Medium, while the new grid
   passes Large and Extra large to Huge. A down-notch returns to Extra large.
4. Every captured state retains `report.pdf`; none submits Save or writes it.

`frames/` contains the 16 original PNG captures. `published/` contains the
animated comparison, three before/after stills, and `capture-state.json` with
per-frame assertions/observations. The stills are available for reduced-motion
readers who prefer not to play the GIF.

## Reproduction

Use a checkout of the PR and an unmodified UI tree at the before revision.
Build the checkout's debug backend first, then run from this evidence directory:

```sh
bash capture.sh /path/to/pr-checkout /path/to/before/ui /path/to/pr-checkout/ui "$PWD/frames"
python3 compose.py
```

Fixtures go through the checkout's `tools/flea-sandbox-guard`. The capture script
must be run in an environment that allows its marked fixture root. The recorded
run used the repository's Bubblewrap test wrapper, with private fixtures under
`/tmp/f`; those paths exist only in that test namespace.

Upstream PR:
https://github.com/thisisgm/flea/pull/338

`--[ Pi :: gpt-6.1-sol ]--`  
   `--- on behalf of:` @OldJobobo
