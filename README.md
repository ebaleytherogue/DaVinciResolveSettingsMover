# DaVinci Resolve Settings Mover

A Windows tool for copying selected DaVinci Resolve settings, presets, Fusion resources, and Fairlight presets between computers or Windows user accounts.

The tool creates a dated `.7z` export, lets you validate or preview an import, and backs up existing destination settings before importing. It also includes the full Preferences folder for manual reference, but does not restore that folder automatically.

This is a settings mover, not a project backup tool. It excludes project libraries, databases, project files, caches, optimized media, and proxy media.

**Requirements:** Windows PowerShell and 7-Zip at `C:\Program Files\7-Zip\7z.exe`. Close Resolve before exporting or importing.

Double-click `Run DaVinciResolveSettingsMover.bat` to begin. The default working folder is `C:\apps\DaVinciResolveSettingsMover`, regardless of where you launch the scripts.

See the [User Guide](DaVinciResolveSettingsMover_User_Guide.md) for setup, export/import instructions, and backup recovery.
