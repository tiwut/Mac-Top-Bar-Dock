# Mac-Top-Bar-Dock

A lightning-fast, 100% native macOS menu bar app launcher inspired by "DockPops." It lives in your top menu bar and provides a beautiful, cascading "Liquid Glass" interface to quickly access your favorite apps, files, and folders.

Built entirely with standard **C++17** and **Objective-C++ (AppKit)**, requiring **zero** third-party frameworks.

<img width="1710" height="1112" alt="Screenshot 2026-05-26 at 21 09 57" src="https://github.com/user-attachments/assets/3fd7476c-577b-470b-999c-9cc43e61dee8" />

## How to run the APP?

```bash
chmod +x app-veri.sh
./app-veri.sh
```
or run 
```bash
xattr -cr "Top Bar Dock.app"
```

### Features

* **Native "Liquid Glass" Interface:** Uses native `NSVisualEffectView` to perfectly blur your desktop and dynamically adapt to macOS Light/Dark mode.
* **Cascading Folders:** Clicking a folder gracefully spawns a new window right next to the current one. Browse infinitely deep without cluttering your screen!
* **Zero Dock Clutter:** Runs entirely as a Status Bar Accessory. No annoying Terminal windows or Dock icons while running.
* **Smart Auto-Close:** Click anywhere else on your screen, and all LiquidDock windows instantly and cleanly vanish.
* **Live Refreshing:** Simply drop an App, Alias (Shortcut), or File into your `~/DockDesktop` folder. Next time you click the top bar, it's immediately there.
* **Native System Icons:** Automatically extracts the official macOS high-res icons for any file, app, or folder.

---

## Prerequisites

All you need is a Mac! Because this project uses pure Apple system libraries, the only requirement is the standard Apple Clang compiler (which is aliased as `g++` on macOS).

If you don't have it installed, open your Terminal and run:
```bash
xcode-select --install
```

---

## How to Compile & Install

1. **Clone or Download** this repository.
2. Open your Terminal and navigate to the folder containing the source code.
3. **Compile the App** using the following command:

```bash
g++ -std=c++17 -Wall -fobjc-arc -framework Cocoa TopBarDock.mm -o TopBarDock
```
> **Note:** The `-fobjc-arc` flag is critical! It enables Automatic Reference Counting to ensure memory is managed properly when opening nested folders.

---

## Usage

1. **Run the App:**
   ```bash
   ./TopBarDock
   ```
2. **Look at your Menu Bar:** You will see a new Grid icon (`▣`) in the top right of your screen (near your WiFi/Clock).
3. **The Magic Folder:** The first time you open the app, it creates a folder in your home directory at `~/DockDesktop`. 
4. **Add your Apps:** Open Finder, navigate to `Home -> DockDesktop`, and drag-and-drop your favorite Apps, Files, or Folders into it (Creating "Aliases/Shortcuts" works perfectly!).
5. **Launch:** Click the grid icon in your top bar. Your beautifully blurred app drawer will drop down. Click any app to launch it, or click a folder to cascade into it!

---

## Customization

Want to tweak the app? Open `TopBarDock.mm` in any text editor:
* **Change the Folder Path:** Search for `DockDesktop` and change it to whatever folder you'd like the app to read from.
* **Change Window Size:** Search for `CGFloat windowSize = 500.0;` and adjust the math to make your popup larger or smaller.
* **Change Icon Sizes:** Search for `CGFloat btnSize = 64.0;` and tweak the grid math variables to fit more or fewer icons per row.

---

## License
Distributed under the MIT License. See `LICENSE` for more information. Feel free to fork, modify, and build upon this!
