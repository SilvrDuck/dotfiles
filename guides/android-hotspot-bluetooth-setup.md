# Android Wi-Fi hotspot from macOS (Bluetooth-triggered)

## Phone

1. Install **Shizuku**, **Delta** (`dev.shadoe.delta`), and **Tasker** from F-Droid via the IzzyOnDroid repo (`https://apt.izzysoft.de/fdroid/repo`).
2. Start **Shizuku** (must show *Running*; re-*Start* after each reboot on a non-rooted phone).
3. Open **Delta**, grant it Shizuku access, confirm it toggles the hotspot manually.
4. **Delta → Advanced settings → turn on Tasker integration.**
5. **Tasker → Tasks → +**, name it *Start Hotspot*, add **System → Send Intent**:

   ```text
   Action:   dev.shadoe.delta.action.START_SOFT_AP
   Package:  dev.shadoe.delta
   Class:    dev.shadoe.delta.SoftApBroadcastReceiver
   Target:   Broadcast Receiver
   ```

   Leave Cat, Mime Type, Data, Extra empty. Save.
6. **Tasker → Tasks → +**, name it *Stop Hotspot*, add the same **System → Send Intent** as above but with `Action: dev.shadoe.delta.action.STOP_SOFT_AP` (package, class, and target identical). Save.
7. **Tasker → Profiles → + → State → Net → BT Connected**, pick the Mac (by device/address). The field accepts multiple addresses, so additional Macs just append theirs here. Attach *Start Hotspot* as the entry task, then long-press it → **Add Exit Task** → *Stop Hotspot*. The Mac turns Bluetooth off when it sleeps (`bt-sleep`), so closing the lid drops the BT link, the profile goes false, and the exit task stops the hotspot — no waiting on the phone's idle-timer.
8. **Settings → Apps**, set **Tasker**, **Delta**, **Shizuku** → Battery → **Unrestricted**. (Delta must stay alive in the background for `STOP_SOFT_AP` to fire — unlike `START`.)

## Mac

1. Pair the phone: **System Settings → Bluetooth**, accept the prompt on the phone.
2. Read its Bluetooth address: `blueutil --paired`.
3. Store the per-machine values: `android-hotspot setup` (Bluetooth address, SSID, password).
4. Run it: `android-hotspot start`. (`android-hotspot wifi` re-joins without re-triggering.)
