# M40: MAME controls on Windows and macOS

Copy [m40-ui.cfg](scripts/m40-ui.cfg) into MAME's `ctrlr` directory and launch with:

```text
mame m40 -uimodekey F12 -ctrlr m40-ui
```

Use `mame.exe` on Windows or `./m40` for the local macOS build, and add
your floppy options. The local interactive scripts already select this profile.
It reserves F12 for UI controls and disables the conflicting screenshot shortcut.

1. Press **F12** alone; check for **UI controls enabled**.
2. Press **Tab** to open the menu; use arrows and main Enter.
3. Close the menu with **Tab**.
4. Press **F12** again; check for **UI controls disabled** before typing into M40.

Neither F12 nor Scroll Lock sends an M40 key. **Alt+H** sends HALT/ERASE (48),
**Alt+C** clears BCOS E/KE, **F8** is BCOS RUN/retry, and **Ctrl+F8** toggles TEST/L2.
Clicking the FLOPPY/HD and K1/K2/K3 status-bar switches does not require UI controls.

If saved custom assignments override the profile, correct **Toggle UI Controls**
and clear **Save Snapshot** under **Input Settings → Input Assignments (general) →
User Interface**. Do not erase unrelated settings.

If remote desktop intercepts Ctrl+F8, assign **F16/F8 (5A)** to PC **F10**
under **Input Assignments (this system)**. Then use F10 for RUN and Ctrl+F10
for TEST. This is an optional local override, not the default mapping.
