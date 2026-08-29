# VHOLUME No Head Bob — UE4SS mod

This mod disables the **vertical bob** and **roll sway** configured by VHOLUME's `CameraShake_Run` default object. It does not disable landing, mantle, ledge-grab, zipline, or fall camera shakes.

NOTE: This will invalidate any runs completed with this mod, thus they will not appear on the leaderboard.

## Requirements

- A Windows copy of VHOLUME.
- (If doing manual install) The latest [experimental UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) (the normal, non-zDEV package) installed into VHOLUME's real executable directory:

  ```text
  <Steam library>\steamapps\common\VHOLUME\VHOLUME\Binaries\Win64\
  ```

  That directory must contain `VHOLUME-Win64-Shipping.exe`, `UE4SS.dll`, and a `Mods` directory.

## Automated install (recommended)

1. Double-click `Install-VHOLUMENoHeadBob.cmd`.
2. When prompted, paste the **VHOLUME install root**—the folder containing `VHOLUME.exe` and the inner `VHOLUME` folder:

   ```text
   <Steam library>\steamapps\common\VHOLUME
   ```

The command wrapper starts PowerShell with `-ExecutionPolicy Bypass` **only for that one installer process**; it does not change the computer's saved execution-policy setting. It is included because scripts delivered from the internet or chat applications are often blocked by Windows policy.

If the friend prefers not to use that one-process bypass, they can right-click each `.ps1` file → **Properties** → **Unblock**, then run `Install-VHOLUMENoHeadBob.ps1` from an already permitted PowerShell session instead.

The installer downloads the newest **normal UE4SS experimental** build from the official GitHub release, verifies its published SHA-256 digest when present, preserves an existing `Mods\mods.txt`, enables `NoHeadBob`, and stores a small uninstall manifest.

To remove only this mod, double-click `Uninstall-VHOLUMENoHeadBob.cmd`.

To remove the mod **and** the UE4SS core files installed by this package, open a Command Prompt in the extracted package directory and run:

```text
Uninstall-VHOLUMENoHeadBob.cmd -RemoveUE4SS
```

## Manual install

1. Extract this ZIP **into the `Win64` directory** above, preserving folders. It should create:

   ```text
   Win64\Mods\NoHeadBob\scripts\main.lua
   ```

2. Open:

   ```text
   Win64\Mods\mods.txt
   ```

3. Add this line exactly once (do not overwrite the existing file):

   ```text
   NoHeadBob : 1
   ```

4. Start VHOLUME and enter a level.

5. In the UE4SS console, confirm this message appears:

   ```text
   [NoHeadBob] NoHeadBob successfully applied
   ```

## Verify

Run normally. The rhythmic vertical run bob and roll sway should be gone. Other movement camera effects should remain.

## Uninstall

1. Remove or change this entry in `Mods\mods.txt`:

   ```text
   NoHeadBob : 1
   ```

   To disable without deleting, change `1` to `0`.

2. Delete `Win64\Mods\NoHeadBob` if desired.

## Notes

- This modifies memory at runtime only; it does not alter VHOLUME's `.pak` files.
- The normal UE4SS package is sufficient for using this mod. `zDEV-UE4SS` is only needed for development tools such as Live View, object dumps, and the GUI debugger.
- If the mod never reports success after entering a level, inspect `UE4SS.log`, then test the current experimental UE4SS build before trying a different configuration.
