# Color Balance for Onion

Warmth and red, green, blue white balance for the display of the Miyoo Mini Plus running [Onion](https://github.com/OnionUI/Onion), with live preview, built in test images and your own screenshots as reference.

## Why

Onion's display settings (Lumination, Hue, Saturation, Contrast) cannot correct a color tint in white and gray areas: Hue and Saturation only affect colors that are already colored. The Blue light filter can warm the image, but only in five fixed and fairly strong steps.

Color Balance adds the missing control:

- **Warmth** from 0 to 100 % in steps of 1 %.
- **Red, green and blue** individually, for example to remove a green or blue tint from white.
- **Live preview**: every step is visible immediately.
- **Test images**: white and grays, a gray ramp, natural colors and color bars.
- **My screenshots**: check the colors on the games you actually play.

## Requirements

- Onion with the Blue light filter (Apps › Tweaks › Appearance). Tested with Onion 4.4 beta on a Miyoo Mini Plus.
- Other Miyoo Mini models should work as well, but are untested.

## Installation

1. Download `ColorBalance-vX.Y.Z.zip` from [Releases](../../releases).
2. Extract it to the root of the SD card. The folder `App/ColorBalance` appears.
3. Open **Apps › Color Balance**.

To update, extract a newer zip the same way and replace the existing files. Your saved values are kept.

## Usage

Main menu:

| Entry | Effect |
|---|---|
| Warmer +5 / +1, Cooler −1 / −5 | change the warmth |
| Red, green, blue … | adjust each channel in steps of 1 |
| Test images | show the four test images with the current setting |
| My screenshots | show your screenshots from `/Screenshots` with the current setting |
| Reset to neutral | back to the original colors |
| Save and exit | keep the setting |
| Exit without saving (or B) | discard all changes |

In the image viewer, A or right shows the next image, B or left the previous one, MENU returns to the app.

By default the channels can only be lowered, so bright areas keep their detail. The option **Above neutral** in the channel menu allows raising them as well.

To take a screenshot in a game, hold MENU and press POWER.

### Suggested order

1. In **Settings › Display**, set Lumination to taste and Hue to 10.
2. In Color Balance, set the warmth and, if needed, single channels until **White and grays** looks neutral.
3. Back in Settings, fine tune Saturation with **Natural colors** or your screenshots, and Contrast with the **Gray ramp** (all 16 steps should stay distinguishable).

If pure red in the color bars already looks pinkish, that is a hue issue of the panel: adjust Hue by one step. If only mixed reds such as skin tones look pinkish, lower blue in Color Balance instead.

## How it works

- For the live preview the app writes the red, green and blue gains to the display driver.
- On saving, the values are stored in `.tmp_update/config/display/colorBalance`. The app adds four lines to Onion's `.tmp_update/script/blue_light.sh` (a backup is kept as `blue_light.sh.orig`), so the Blue light filter applies these values instead of its fixed levels, and switches the filter on.
- Onion therefore applies your colors at every boot, and the filter's hotkey switches them on and off, which is handy for comparing.
- While custom values are saved, the **Strength** setting of the Blue light filter has no effect. If the filter **schedule** is on, your colors only apply in its time window; the app shows a note when you save.
- If an Onion update replaces `blue_light.sh`, open Color Balance once and save again.

The Settings › Display values and Color Balance are separate stages in the display driver and do not overwrite each other.

## Uninstall

1. In Color Balance, choose **Reset to neutral**, then **Save and exit**.
2. Delete the folder `App/ColorBalance`.
3. Optionally restore the original filter script: in `.tmp_update/script/`, delete `blue_light.sh` and rename `blue_light.sh.orig` to `blue_light.sh`.

## Disclaimer

Provided as is, without warranty. The app only changes the display color gains, its own files in `.tmp_update/config/display/` and the four lines in `blue_light.sh` described above. Use at your own risk. This project is not affiliated with the Onion team.

## Credits

Thanks to the Onion team for Onion, its Blue light filter and the prompt and image viewer tools this app builds on. Icon and test images are original.

## License

[MIT](LICENSE)
