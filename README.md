# VHOLUME No Head Bob — UE4SS mod

This mod disables the **vertical bob** and **roll sway** configured by VHOLUME's `CameraShake_Run` default object. It does not disable landing, mantle, ledge-grab, zipline, or fall camera shakes.

## Requirements

- A Windows copy of VHOLUME.
- The latest **experimental UE4SS** (the normal, non-zDEV package) installed into VHOLUME's real executable directory:

  ```text
  <Steam library>\steamapps\common\VHOLUME\VHOLUME\Binaries\Win64\
  ```

  That directory must contain `VHOLUME-Win64-Shipping.exe`, `UE4SS.dll`, and a `Mods` directory.

## Automated install (recommended)

Open **PowerShell** in the extracted package folder and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-VHOLUMENoHeadBob.ps1
```

When prompted, paste the folder containing `VHOLUME-Win64-Shipping.exe`:

```text
<Steam library>\steamapps\common\VHOLUME\VHOLUME\Binaries\Win64
```

The installer downloads the newest **normal UE4SS experimental** build from the official GitHub release, verifies its published SHA-256 digest when present, preserves an existing `Mods\mods.txt`, enables `NoHeadBob`, and stores a small uninstall manifest.

To remove only this mod:

```powershell
powershell -ExecutionPolicy Bypass -File .\Uninstall-VHOLUMENoHeadBob.ps1
```

To remove the mod **and** the UE4SS core files installed by this package (restoring any core files backed up at installation):

```powershell
powershell -ExecutionPolicy Bypass -File .\Uninstall-VHOLUMENoHeadBob.ps1 -RemoveUE4SS
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
- Test in single-player/offline first. Steam Offline Mode is recommended while using a new UE4SS setup.
- The normal UE4SS package is sufficient for using this mod. `zDEV-UE4SS` is only needed for development tools such as Live View, object dumps, and the GUI debugger.
- If the mod never reports success after entering a level, inspect `UE4SS.log`, then test the current experimental UE4SS build before trying a different configuration.
