# VHOLUME No Head Bob — UE4SS mod

This mod disables the **vertical bob** and **roll sway** configured by VHOLUME's `CameraShake_Run` default object. It does not disable landing, mantle, ledge-grab, zipline, or fall camera shakes.

> **Note:** Runs completed with this mod are invalidated and will not appear on the leaderboard.

## Requirements

- A Windows copy of VHOLUME.
- For a manual install: the latest [experimental UE4SS](https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest) **normal/non-zDEV** package.

The current normal UE4SS archive layout is:

```text
<Steam library>\steamapps\common\VHOLUME\VHOLUME\Binaries\Win64\
├── VHOLUME-Win64-Shipping.exe
├── dwmapi.dll
└── ue4ss\
    ├── UE4SS.dll
    ├── UE4SS-settings.ini
    └── Mods\
        └── mods.txt
```

`zDEV-UE4SS` is only needed for development tools such as Live View, object dumps, and the GUI debugger. The normal UE4SS package is sufficient for using this mod.

## Automated install (recommended)

1. Download the latest [release zip](https://github.com/the-color-cyan/NoHeadBob/releases) and extract it.
1. Double-click `Install-VHOLUMENoHeadBob.cmd`.
2. When prompted, paste the **VHOLUME install root**—the folder containing `VHOLUME.exe` and the inner `VHOLUME` folder:

   ```text
   <Steam library>\steamapps\common\VHOLUME
   ```

The installer downloads the newest normal UE4SS experimental build from the official GitHub release, verifies its published SHA-256 digest when available, preserves an existing `ue4ss\Mods\mods.txt`, and enables `NoHeadBob`.

The command wrapper uses `-ExecutionPolicy Bypass` only for that one PowerShell process; it does not change the computer's saved execution-policy setting. If preferred, unblock the `.ps1` files via **Properties → Unblock** and run the PowerShell scripts from an already permitted session instead.

## Uninstall

### Remove the mod and UE4SS (default)

Double-click:

```text
Uninstall-VHOLUMENoHeadBob.cmd
```

The script asks for confirmation before removing:

```text
Win64\ue4ss
Win64\dwmapi.dll
```

It restores a pre-install UE4SS backup if one existed.

### Remove only the mod and preserve UE4SS

Open Command Prompt in the extracted package folder and run:

```text
Uninstall-VHOLUMENoHeadBob.cmd -KeepUE4SS
```

The `-KeepUE4SS` flag removes the `NoHeadBob` folder and its `mods.txt` entry, but leaves the existing UE4SS installation in place.

## Manual install

1. Extract the normal UE4SS archive into:

   ```text
   <Steam library>\steamapps\common\VHOLUME\VHOLUME\Binaries\Win64
   ```

2. Copy the packaged `Mods\NoHeadBob` folder to:

   ```text
   Win64\ue4ss\Mods\NoHeadBob
   ```

3. Open:

   ```text
   Win64\ue4ss\Mods\mods.txt
   ```

4. Add this line exactly once (do not overwrite the file):

   ```text
   NoHeadBob : 1
   ```

5. Start VHOLUME and enter a level.

6. Verify the mod through the UE4SS log:

   ```text
   Win64\ue4ss\UE4SS.log
   ```

   Open that file in Notepad after entering a level, then search for:

   ```text
   [NoHeadBob] NoHeadBob successfully applied
   ```

   If using `zDEV-UE4SS` instead of the normal package, open its GUI with `Ctrl+O` (when the GUI console is enabled) and use the **Console** tab to see the same output live.

## Verify

Run normally. The rhythmic vertical run bob and roll sway should be gone, while the other movement-camera effects should remain.

## Manual mod-only removal

1. Remove or change this line in `ue4ss\Mods\mods.txt`:

   ```text
   NoHeadBob : 1
   ```

   Change `1` to `0` to disable it without deletion.

2. Delete:

   ```text
   Win64\ue4ss\Mods\NoHeadBob
   ```

## Notes

- This modifies memory at runtime only; it does not alter VHOLUME's `.pak` files.
- Test in single-player/offline first.
- If the mod never reports success after entering a level, inspect `Win64\ue4ss\UE4SS.log` and ensure the current experimental normal UE4SS build is installed.
