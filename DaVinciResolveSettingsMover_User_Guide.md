# DaVinci Resolve Settings Mover
## User Guide — Version 1.2

**Platform:** Windows  
**Required software:** Windows PowerShell and 7-Zip  
**Script files:**

- `DaVinciResolveSettingsMover.ps1`
- `Run DaVinciResolveSettingsMover.bat`

## Table of Contents

1. [What the Tool Does](#1-what-the-tool-does)
2. [Before You Begin](#2-before-you-begin)
3. [Exporting Settings](#3-exporting-settings)
4. [Checking an Export](#4-checking-an-export)
5. [Importing Settings](#5-importing-settings)
6. [Backups and Recovery](#6-backups-and-recovery)
7. [Troubleshooting](#7-troubleshooting)
8. [Recommended Workflow](#8-recommended-workflow)

---

## 1. What the Tool Does

Use this tool when you want to copy selected DaVinci Resolve settings and custom resources to another Windows computer or user account, or save them before reinstalling Resolve.

The tool:

- Exports the supported items that exist for the current Windows user.
- Creates a dated `.7z` archive containing those items and a `manifest.json` inventory.
- Lets you check an archive and preview where its contents would be restored.
- Backs up existing destination settings before a real import, when matching destinations exist.
- Imports the supported items into the current Windows user's Resolve folders.
- Writes a log for each run.

### What is included?

All source paths below are relative to:

`%APPDATA%\Blackmagic Design\DaVinci Resolve\`

You can paste that path into File Explorer's address bar.

| Item | Source location | Imported automatically? |
|---|---|---|
| Keyboard preset | `Preferences\keyboard.preset.xml` | Yes |
| User presets configuration | `Preferences\config.user.presets.xml` | Yes |
| Media metadata preset | `Preferences\mediametadata.preset.xml` | Yes |
| Primary HDR preset | `Preferences\primaryhdr.preset.xml` | Yes |
| UI preset | `Preferences\UI.preset` | Yes |
| Fusion LUTs, Macros, Templates, Scripts, Settings, Defaults, and Profiles | Corresponding folders under `Support\Fusion\` | Yes |
| Fairlight presets | `Preferences\Fairlight\Presets` | Yes |
| Full Preferences folder | `Preferences\` | **No — manual reference only** |

Missing optional items are logged and skipped. The tool does not search other locations for additional presets or LUTs.

**Important:** The full Preferences folder is included in the export, but only the individual preference items listed above are restored automatically. Do not expect every Resolve preference to transfer.

### What is excluded?

Project libraries, Resolve databases, project files, cache files, optimized media, proxy media, render cache, and Fusion DiskCache are outside the tool's intended coverage. Back up your projects and media separately.

---

## 2. Before You Begin

### Check 7-Zip

The script expects:

`C:\Program Files\7-Zip\7z.exe`

If your installation is elsewhere, edit the `$SevenZip` setting near the top of `DaVinciResolveSettingsMover.ps1` to match it.

### Prepare the script files

Keep the PS1 and BAT files together. A convenient location is:

```text
C:\apps\DaVinciResolveSettingsMover\
    DaVinciResolveSettingsMover.ps1
    Run DaVinciResolveSettingsMover.bat
```

The script uses `C:\apps\DaVinciResolveSettingsMover` as its working folder even if you launch it from somewhere else, such as a repository checkout.

To use another working folder, edit `$Root` near the top of the PS1 file. The account running the tool must be able to write there.

The tool creates these subfolders as needed:

| Folder | Purpose |
|---|---|
| `exports` | Export archives; also where the import menu looks for archives |
| `backups` | Destination settings saved before an import |
| `logs` | Dated activity logs |
| `temp` | Temporary working files; this run's temporary folder is removed when it finishes |

### Close Resolve and choose the right account

Save your work and close DaVinci Resolve before exporting, importing, or running a dry-run import. The tool checks for a running `Resolve` process and stops if it finds one.

Run the tool as the Windows user whose settings you want to export or import. The destination is based on the current user's `%APPDATA%`, not the username stored in the export.

Prefer matching Resolve versions on both computers. The tool does not check Resolve version compatibility.

### Open the menu

Double-click:

`Run DaVinciResolveSettingsMover.bat`

The launcher opens Windows PowerShell and runs the PS1 file beside it.

| Option | Action |
|---|---|
| `1` | Export settings |
| `2` | Import settings |
| `3` | Dry-run import |
| `4` | Validate export archive |
| `5` | Exit |

Type the option number and press **Enter**. Each run performs one operation and ends. At the launcher's final pause, press any key to close the window. Open the BAT again for the next operation.

---

## 3. Exporting Settings

**Step 1 — Close Resolve on the source computer.**

Use the Windows account containing the settings you want to copy.

**Step 2 — Open the BAT file and choose `1`.**

The tool copies the supported items it finds and creates an export archive.

Messages such as `Optional item not present` mean that a listed file or folder was not found. This can be normal if you have never created that type of preset.

**Step 3 — Find the export.**

With the default configuration, look in:

`C:\apps\DaVinciResolveSettingsMover\exports\`

The filename resembles:

`DaVinciResolveSettingsExport-20261102-143000.7z`

The archive contains an `AppDataRoaming` folder tree and a `manifest.json` inventory, including the source computer, source user, export time, and script version.

**Step 4 — Check and copy the archive.**

Validate it using option `4`, as explained below. Copy the complete `.7z` file to the destination computer. You do not need to extract it for the tool to import it.

---

## 4. Checking an Export

### Validate export archive — option 4

Use this to check that an archive identifies itself as a settings mover export and that its listed items are present.

1. Place the `.7z` file in the tool's `exports` folder.
2. Open the BAT file and choose `4`.
3. Review the numbered archive list, which shows the most recently modified archives first.
4. Type the archive number and press **Enter**.
5. Read the source details and the `Found restorable item`, `Found backup-only item`, or `Missing` messages.

Validation does not restore settings. It does extract temporary files and write a log. Missing items are reported, so review the results rather than relying only on `Validation complete`.

### Dry-run import — option 3

Use this on the destination computer to preview an import.

1. Close Resolve.
2. Open the BAT file and choose `3`.
3. Select the archive by number.
4. Review each `Ready to restore` entry and its destination.
5. Check any warnings about missing payload items.

The dry run skips the full Preferences folder and leaves the destination Resolve settings unchanged. It creates temporary files and a log, but does not create a destination backup or perform the import.

**Important:** A dry run previews the plan; it does not prove that every preset will work in the destination installation.

---

## 5. Importing Settings

**Step 1 — Prepare the destination computer.**

Make sure Resolve, 7-Zip, and both tool files are available. Run the tool under the destination Windows account and close Resolve.

**Step 2 — Place the export in the destination `exports` folder.**

With the default configuration:

`C:\apps\DaVinciResolveSettingsMover\exports\`

**Step 3 — Run a dry-run import first.**

Choose `3`, select the archive, and review the items and destination paths. Resolve any unexpected results before proceeding.

**Step 4 — Open the BAT again and choose `2`.**

Select the archive by number and press **Enter**.

**There is no additional confirmation prompt.** After selecting the archive, the tool validates it, attempts to back up existing destinations, and imports the restorable items.

Matching files can be overwritten. Folder contents are copied into the destination; files that exist only at the destination are not deliberately removed. The result is not an exact replacement of the destination folder tree.

The full Preferences folder remains a backup-only item and is skipped during restore.

**Step 5 — Review the log and test Resolve.**

After the operation finishes, open Resolve and check the keyboard preset, UI presets, Fusion resources, and Fairlight presets you expected to transfer.

Keep the export and destination backup until you have confirmed the result.

---

## 6. Backups and Recovery

### Where are the pre-import backups?

Before a real import, the tool copies existing destination items listed in the export manifest, including the full Preferences folder when listed and present.

If it finds anything to back up, it creates an archive resembling:

`C:\apps\DaVinciResolveSettingsMover\backups\DaVinciResolveSettingsBackup-20261102-150000.7z`

If no matching destinations exist, it logs that there was nothing to back up.

### How do I restore a backup?

Recovery is manual. The pre-import backup does not contain the export manifest required by the import menu, so do not move it into `exports` and try to import it as a normal export.

1. Close Resolve.
2. Open the backup archive in 7-Zip and extract it into a separate folder.
3. Browse inside `AppDataRoaming\Blackmagic Design\DaVinci Resolve\`.
4. Copy the specific files or folder contents you need back into the matching locations under `%APPDATA%\Blackmagic Design\DaVinci Resolve\`.
5. Reopen Resolve and verify the result.

A backup restores previously existing files. It does not automatically remove new files added by the import; those may need to be identified and removed separately if you need a complete rollback.

The full Preferences copy in an export is also available for manual reference. Avoid copying the entire folder over another installation without reviewing what you need.

---

## 7. Troubleshooting

### 7-Zip was not found

Confirm that `C:\Program Files\7-Zip\7z.exe` exists, or correct `$SevenZip` in the script.

### Resolve appears to be running

Close Resolve and let it finish exiting. If necessary, check Task Manager for a remaining Resolve process, then reopen the BAT file.

### No .7z files were found

Place the export archive in the configured working folder's `exports` subfolder. The menu does not browse other folders, including the folder containing the BAT file unless that is also the configured working location.

### Archive selection is invalid

Enter a number shown in the archive list, such as `1`, rather than a filename. Restart the BAT if the run has ended.

### Archive is missing manifest.json

Use a complete export produced by this tool. A manually assembled archive or a pre-import backup is not a normal import archive.

### Some settings did not transfer

Check the coverage table and the log. Missing source items are skipped, and the full Preferences folder is never restored automatically. Resources stored outside the listed paths are not collected.

### The window says Done, but something went wrong

`Done` also appears after a caught error. Review earlier messages and the log in `logs` for `ERROR`, `WARNING`, or `Missing` entries.

The script does not explicitly check 7-Zip's exit codes, so a completion message alone does not guarantee a usable archive or successful import. Check the archive with 7-Zip and verify the actual settings in Resolve.

### Where is the log?

With the default configuration:

`C:\apps\DaVinciResolveSettingsMover\logs\`

Look for a file resembling:

`DaVinciResolveSettingsMover-20261102-150000.log`

Temporary extracted files are removed at the end of the run. The export archives, backups, and logs remain.

---

## 8. Recommended Workflow

1. Close Resolve on the source computer.
2. Choose **1 — Export settings**.
3. Reopen the tool and choose **4 — Validate export archive**. Review the results.
4. Copy the export to the destination computer's `exports` folder.
5. Close Resolve on the destination computer.
6. Choose **3 — Dry-run import** and review the destination paths.
7. Reopen the tool and choose **2 — Import settings**.
8. Review the log, open Resolve, and test the transferred settings.
9. Keep the export and pre-import backup until you are satisfied.

**Golden rule:** Verify the transferred settings before deleting your export or destination backup, and back up projects separately.

**End of User Guide**
