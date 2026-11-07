# Changelog

## v1.0.1 (2026-11-07)

- New menu entry **Remove from Onion**: removes the app's four lines from Onion's `blue_light.sh`, deletes the saved values, resets the colors and switches the Blue light filter off. Nothing older is restored, so it is safe after Onion updates.
- The backup `blue_light.sh.orig` is now refreshed whenever the app has to add its lines, for example after an Onion update. A manual restore can no longer bring back an older script.
- README: updated uninstall instructions.

## v1.0.0 (2026-11-07)

First public release.

- Warmth in steps of 1 % and red, green, blue individually, with live preview.
- Four test images and a viewer for your own screenshots.
- Values are applied through Onion's Blue light filter, so Onion keeps applying them at boot.
