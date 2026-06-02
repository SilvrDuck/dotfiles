# Crisp HiDPI scaling on external displays (macOS Tahoe + BetterDisplay)

On some monitors macOS Tahoe refuses a sharp, usable scaled resolution. This
unlocks a crisp 21:9 HiDPI mode (around **3072 × 1296**) using BetterDisplay.

Tested with **BetterDisplay v4.3.4** (the build that supports macOS Tahoe 26).

## 1. Install BetterDisplay

Download from the official site (betterdisplay.pro) or the GitHub releases
page, or via Homebrew:

```sh
brew install --cask betterdisplay
```

Drag it to Applications and launch it — a new icon appears in your menu bar.

## 2. Grant permissions

On first launch it may ask for Accessibility access. Open System Settings →
Privacy & Security → Accessibility and make sure BetterDisplay is toggled on.
Add BetterDisplay to the list if it isn't there.

## 3. Open the display settings

Click the BetterDisplay menu-bar icon, open Settings via the gear icon at the
bottom of the menu, go to the **Displays** section, and select your display.

## 4. Unlock scaling

Enable "Edit the default system configuration of this display model," then
enable the "Flexible scaling" option that appears just below it. (In some
builds this second toggle reads "native smooth resolution scaling" — same
feature, renamed for clarity.) To pin one fixed resolution instead of a free
slider, also tick **"Custom scaled resolutions."**

## 5. Apply and reboot

Click **Apply Changes**, enter your administrator credentials, and reboot. The
reboot is required — the change rewrites the display's system config.

## 6. Set your resolution after reboot

Use the resolution slider in the app menu to scale the desktop. Slide to
**3072 × 1296** (the slider shows the "looks like" size). On a high-DPI panel
(example: a 5120 × 2160 display) every slider position renders in HiDPI and
stays sharp. If you added a custom resolution in step 4, it now also appears in
System Settings → Displays.

## Notes

- **Why 3072 × 1296 and not 3840 × 1620:** both are true 64:27, but 3072
  renders to a ~6144 × 2592 framebuffer while 3840 needs ~7680 × 3240. On
  Apple Silicon, video memory is allocated dynamically and large framebuffers
  can hit limits, so the smaller one is the safer, reliably-crisp choice. Try
  3840 only if 3072 feels too cramped.
- **Free vs Pro:** the core HiDPI / flexible-scaling unlock is free. Pro mainly
  adds convenience like the menu-bar slider. If the slider is gated, set the
  resolution from the app's display submenu or from System Settings → Displays.
- **If flexible scaling looks wrong** (offsets, blur), macOS probably
  misreported the panel's native pixel resolution. Manually set the native
  panel pixel resolution (example: 5120 × 2160) in the same display settings
  and re-apply.
- **To revert:** turn off "Edit the default system configuration of this
  display model," Apply, and reboot — or delete the override folder at
  `/Library/Displays/Contents/Resources/Overrides` and reboot.
