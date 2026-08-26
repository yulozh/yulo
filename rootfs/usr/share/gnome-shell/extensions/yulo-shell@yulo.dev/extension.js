// Yulo Shell Extension - Win11-style bottom taskbar, dark mode toggle, scale-on-close
// Compatible with GNOME 46, 47, 48

const { St, Clutter, Gio, GLib, Shell, Meta } = imports.gi;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const AppSystem = imports.ui.appFavorites;
const AppFavorites = imports.ui.appFavorites;
const DND = imports.ui.dnd;
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

let bottomPanel = null;
let leftBox = null;
let centerBox = null;
let rightBox = null;
let startButton = null;
let appDock = null;
let darkToggle = null;
let inputIndicator = null;
let clockWidget = null;
let powerButton = null;
let originalPanelHeight = null;
let windowRemovedHandler = null;
let windowAddedHandler = null;
let settings = null;
let isDarkMode = false;

const WALLPAPER_LIGHT = 'file:///usr/share/backgrounds/yulo/wallpaper_4k_poster.png';
const WALLPAPER_DARK = 'file:///usr/share/backgrounds/yulo/wallpaper_4k_poster_dark.png';
const GTK_THEME_LIGHT = 'Yulo';
const GTK_THEME_DARK = 'Yulo-Dark';
const ICON_THEME = 'Yulo';
const SHELL_THEME = 'Yulo';

function init() {
    // Load settings
    try {
        settings = ExtensionUtils.getSettings();
    } catch (e) {
        log('[Yulo Shell] settings not available: ' + e);
    }
}

function enable() {
    log('[Yulo Shell] enabling');

    // Hide default top panel (we replace with bottom)
    originalPanelHeight = Main.panel.height;
    Main.panel.hide();

    // Create bottom panel
    createBottomPanel();

    // Create start button
    createStartButton();

    // Create app dock
    createAppDock();

    // Create system tray (right side)
    createSystemTray();

    // Set up window close scale animation
    setupWindowAnimations();

    // Apply initial theme
    applyTheme(isDarkMode);

    log('[Yulo Shell] enabled successfully');
}

function disable() {
    log('[Yulo Shell] disabling');

    // Remove window handlers
    if (windowRemovedHandler) {
        global.display.disconnect(windowRemovedHandler);
        windowRemovedHandler = null;
    }
    if (windowAddedHandler) {
        global.display.disconnect(windowAddedHandler);
        windowAddedHandler = null;
    }

    // Destroy bottom panel
    if (bottomPanel) {
        bottomPanel.destroy();
        bottomPanel = null;
    }

    // Show default panel
    Main.panel.show();

    // Reset variables
    leftBox = null;
    centerBox = null;
    rightBox = null;
    startButton = null;
    appDock = null;
    darkToggle = null;
    inputIndicator = null;
    clockWidget = null;
    powerButton = null;

    log('[Yulo Shell] disabled');
}

// ===== Bottom Panel =====

function createBottomPanel() {
    bottomPanel = new St.BoxLayout({
        style_class: 'yulo-bottom-panel',
        reactive: true,
        track_hover: true,
        height: 48,
        x: 0,
        y: global.stage.height - 48,
        width: global.stage.width,
    });

    // Left section
    leftBox = new St.BoxLayout({
        style_class: 'yulo-panel-left',
        x_align: Clutter.ActorAlign.START,
        x_expand: true,
    });

    // Center section (app dock)
    centerBox = new St.BoxLayout({
        style_class: 'yulo-panel-center',
        x_align: Clutter.ActorAlign.CENTER,
        x_expand: true,
    });

    // Right section (system tray)
    rightBox = new St.BoxLayout({
        style_class: 'yulo-panel-right',
        x_align: Clutter.ActorAlign.END,
        x_expand: true,
    });

    bottomPanel.add_child(leftBox);
    bottomPanel.add_child(centerBox);
    bottomPanel.add_child(rightBox);

    global.stage.add_child(bottomPanel);

    // Handle resize
    global.stage.connect('notify::width', () => {
        if (bottomPanel) {
            bottomPanel.width = global.stage.width;
        }
    });
}

// ===== Start Button =====

function createStartButton() {
    startButton = new St.Button({
        style_class: 'yulo-start-button',
        reactive: true,
        track_hover: true,
        can_focus: true,
        child: new St.Icon({
            icon_name: 'yulo-logo',
            icon_size: 28,
            style_class: 'yulo-start-icon',
        }),
    });

    startButton.connect('clicked', () => {
        Main.overview.toggle();
    });

    leftBox.add_child(startButton);
}

// ===== App Dock =====

function createAppDock() {
    appDock = new St.BoxLayout({
        style_class: 'yulo-app-dock',
        spacing: 4,
    });

    // Get favorite apps
    let favorites = [];
    try {
        favorites = AppFavorites.getAppFavorites().getFavorites();
    } catch (e) {
        log('[Yulo Shell] could not get favorites: ' + e);
    }

    // Default apps if no favorites
    if (favorites.length === 0) {
        const defaultApps = [
            'org.gnome.Nautilus.desktop',
            'firefox.desktop',
            'org.gnome.Terminal.desktop',
            'org.gnome.Settings.desktop',
            'org.gnome.TextEditor.desktop',
        ];
        for (const id of defaultApps) {
            const app = Shell.AppSystem.get_default().lookup_app(id);
            if (app) favorites.push(app);
        }
    }

    for (const app of favorites) {
        addAppToDock(app);
    }

    // Add running apps that aren't in favorites
    const running = Shell.AppSystem.get_default().get_running();
    const favIds = new Set(favorites.map(a => a.get_id()));
    for (const app of running) {
        if (!favIds.has(app.get_id())) {
            addAppToDock(app);
        }
    }

    centerBox.add_child(appDock);

    // Refresh dock when apps change
    try {
        Shell.AppSystem.get_default().connect('app-state-changed', () => {
            refreshAppDock();
        });
    } catch (e) {}
}

function addAppToDock(app) {
    const icon = app.create_icon_texture(32);
    const button = new St.Button({
        style_class: 'yulo-dock-app',
        reactive: true,
        track_hover: true,
        can_focus: true,
        child: icon,
        width: 40,
        height: 40,
    });

    button.connect('clicked', () => {
        app.activate();
    });

    // Running indicator
    const windows = app.get_windows();
    if (windows.length > 0) {
        button.add_style_class_name('yulo-dock-app-running');
    }

    appDock.add_child(button);
}

function refreshAppDock() {
    if (!appDock) return;
    appDock.destroy_all_children();

    let favorites = [];
    try {
        favorites = AppFavorites.getAppFavorites().getFavorites();
    } catch (e) {}

    if (favorites.length === 0) {
        const defaultApps = [
            'org.gnome.Nautilus.desktop',
            'firefox.desktop',
            'org.gnome.Terminal.desktop',
            'org.gnome.Settings.desktop',
        ];
        for (const id of defaultApps) {
            const app = Shell.AppSystem.get_default().lookup_app(id);
            if (app) favorites.push(app);
        }
    }

    for (const app of favorites) {
        addAppToDock(app);
    }

    const running = Shell.AppSystem.get_default().get_running();
    const favIds = new Set(favorites.map(a => a.get_id()));
    for (const app of running) {
        if (!favIds.has(app.get_id())) {
            addAppToDock(app);
        }
    }
}

// ===== System Tray (Right Side) =====

function createSystemTray() {
    // Dark mode toggle (sun/moon)
    createDarkToggle();

    // Input method indicator
    createInputIndicator();

    // Clock
    createClockWidget();

    // Power button
    createPowerButton();
}

function createDarkToggle() {
    darkToggle = new St.Button({
        style_class: 'yulo-dark-toggle',
        reactive: true,
        track_hover: true,
        can_focus: true,
        width: 36,
        height: 36,
        child: new St.Icon({
            icon_name: 'weather-clear-symbolic',
            icon_size: 20,
            style_class: 'yulo-toggle-icon',
        }),
    });

    darkToggle.connect('clicked', () => {
        isDarkMode = !isDarkMode;
        applyTheme(isDarkMode);
        updateDarkToggleIcon();
    });

    rightBox.add_child(darkToggle);
}

function updateDarkToggleIcon() {
    if (!darkToggle) return;
    const icon = darkToggle.get_child();
    if (isDarkMode) {
        icon.icon_name = 'weather-clear-night-symbolic';
        darkToggle.add_style_class_name('yulo-dark-toggle-active');
    } else {
        icon.icon_name = 'weather-clear-symbolic';
        darkToggle.remove_style_class_name('yulo-dark-toggle-active');
    }
}

function createInputIndicator() {
    inputIndicator = new St.Button({
        style_class: 'yulo-input-indicator',
        reactive: true,
        track_hover: true,
        can_focus: true,
        width: 40,
        height: 36,
        child: new St.Label({
            text: '中',
            style_class: 'yulo-input-label',
            y_align: Clutter.ActorAlign.CENTER,
        }),
    });

    inputIndicator.connect('clicked', () => {
        // Toggle input method
        try {
            const ibus = global.get_ibus_manager();
            if (ibus) {
                // Cycle through input sources
                const sources = ibus.get_input_sources();
                const current = ibus.get_current_input_source();
                const next = (current + 1) % sources.length;
                ibus.set_input_source(next);
            }
        } catch (e) {
            log('[Yulo Shell] input toggle: ' + e);
        }

        // Update label
        const label = inputIndicator.get_child();
        if (label.text === '中') {
            label.text = 'EN';
        } else {
            label.text = '中';
        }
    });

    rightBox.add_child(inputIndicator);
}

function createClockWidget() {
    clockWidget = new St.Button({
        style_class: 'yulo-clock-widget',
        reactive: true,
        track_hover: true,
        can_focus: true,
        child: new St.BoxLayout({
            vertical: true,
            spacing: 0,
            children: [
                new St.Label({
                    text: getTimeString(),
                    style_class: 'yulo-clock-time',
                    y_align: Clutter.ActorAlign.CENTER,
                }),
                new St.Label({
                    text: getDateString(),
                    style_class: 'yulo-clock-date',
                    y_align: Clutter.ActorAlign.CENTER,
                }),
            ],
        }),
    });

    clockWidget.connect('clicked', () => {
        // Open calendar/date menu
        Main.panel.statusArea.dateMenu.menu.toggle();
    });

    rightBox.add_child(clockWidget);

    // Update clock every second
    clockWidget._timeout = GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 1, () => {
        if (!clockWidget) return false;
        const box = clockWidget.get_child();
        if (box && box.get_n_children() >= 2) {
            box.get_child_at_index(0).text = getTimeString();
            box.get_child_at_index(1).text = getDateString();
        }
        return true;
    });
}

function getTimeString() {
    const now = new Date();
    const h = String(now.getHours()).padStart(2, '0');
    const m = String(now.getMinutes()).padStart(2, '0');
    return `${h}:${m}`;
}

function getDateString() {
    const now = new Date();
    const y = now.getFullYear();
    const mo = String(now.getMonth() + 1).padStart(2, '0');
    const d = String(now.getDate()).padStart(2, '0');
    return `${y}/${mo}/${d}`;
}

function createPowerButton() {
    powerButton = new St.Button({
        style_class: 'yulo-power-button',
        reactive: true,
        track_hover: true,
        can_focus: true,
        width: 36,
        height: 36,
        child: new St.Icon({
            icon_name: 'system-shutdown-symbolic',
            icon_size: 20,
            style_class: 'yulo-power-icon',
        }),
    });

    powerButton.connect('clicked', () => {
        // Open power menu
        try {
            const menu = new PopupMenu.PopupMenu(powerButton, 0.5, St.Side.TOP);
            const restartItem = new PopupMenu.PopupMenuItem('重启');
            const shutdownItem = new PopupMenu.PopupMenuItem('关机');
            const sleepItem = new PopupMenu.PopupMenuItem('睡眠');
            const logoutItem = new PopupMenu.PopupMenuItem('注销');

            restartItem.connect('activate', () => {
                Meta.restart(Meta.RestartFlags.NONE);
            });
            shutdownItem.connect('activate', () => {
                Meta.shutdown(Meta.ShutdownFlags.NONE);
            });
            sleepItem.connect('activate', () => {
                try {
                    const proxy = Gio.DBusProxy.new_sync(
                        Gio.bus_get_sync(Gio.BusType.SYSTEM, null),
                        Gio.DBusProxyFlags.NONE, null,
                        'org.freedesktop.login1',
                        '/org/freedesktop/login1',
                        'org.freedesktop.login1.Manager', null
                    );
                    proxy.SuspendRemote(true);
                } catch (e) {
                    log('[Yulo Shell] sleep error: ' + e);
                }
            });
            logoutItem.connect('activate', () => {
                global.get_performances().goto_overview();
                Meta.quit(Meta.QuitFlags.NONE);
            });

            menu.addMenuItem(restartItem);
            menu.addMenuItem(shutdownItem);
            menu.addMenuItem(sleepItem);
            menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
            menu.addMenuItem(logoutItem);
            menu.open();
        } catch (e) {
            log('[Yulo Shell] power menu error: ' + e);
        }
    });

    rightBox.add_child(powerButton);
}

// ===== Theme Application =====

function applyTheme(dark) {
    try {
        // GTK theme
        const ifaceSettings = new Gio.Settings({ schema: 'org.gnome.desktop.interface' });
        ifaceSettings.set_string('gtk-theme', dark ? GTK_THEME_DARK : GTK_THEME_LIGHT);
        ifaceSettings.set_string('color-scheme', dark ? 'prefer-dark' : 'prefer-light');
        ifaceSettings.set_string('icon-theme', ICON_THEME);

        // Wallpaper
        const bgSettings = new Gio.Settings({ schema: 'org.gnome.desktop.background' });
        bgSettings.set_string('picture-uri', dark ? WALLPAPER_DARK : WALLPAPER_LIGHT);
        bgSettings.set_string('picture-uri-dark', dark ? WALLPAPER_DARK : WALLPAPER_LIGHT);
        bgSettings.set_string('picture-options', 'zoom');

        // Shell theme
        try {
            Main.setThemeStylesheet(dark ? '/usr/share/themes/Yulo-Dark/gnome-shell/gnome-shell.css' : '/usr/share/themes/Yulo/gnome-shell/gnome-shell.css');
            Main.loadTheme();
        } catch (e) {
            log('[Yulo Shell] shell theme error: ' + e);
        }

        log('[Yulo Shell] theme applied: ' + (dark ? 'dark' : 'light'));
    } catch (e) {
        log('[Yulo Shell] applyTheme error: ' + e);
    }
}

// ===== Window Close Scale Animation =====

function setupWindowAnimations() {
    // Scale animation when closing windows
    windowRemovedHandler = global.display.connect('window-removed', (display, window) => {
        try {
            const actor = window.get_compositor_private();
            if (!actor) return;

            // Save original state
            const origX = actor.x;
            const origY = actor.y;
            const origW = actor.width;
            const origH = actor.height;

            // Scale down and fade out
            actor.set_pivot_point(0.5, 0.5);

            const scaleTransition = new Clutter.PropertyTransition({
                property_name: 'scale-x',
                duration: 250,
                progress_mode: Clutter.AnimationMode.EASE_IN_QUAD,
                from: 1.0,
                to: 0.3,
            });
            const scaleYTransition = new Clutter.PropertyTransition({
                property_name: 'scale-y',
                duration: 250,
                progress_mode: Clutter.AnimationMode.EASE_IN_QUAD,
                from: 1.0,
                to: 0.3,
            });
            const opacityTransition = new Clutter.PropertyTransition({
                property_name: 'opacity',
                duration: 250,
                progress_mode: Clutter.AnimationMode.EASE_IN_QUAD,
                from: 255,
                to: 0,
            });

            actor.add_transition('yulo-close-scale-x', scaleTransition);
            actor.add_transition('yulo-close-scale-y', scaleYTransition);
            actor.add_transition('yulo-close-opacity', opacityTransition);

            // Remove actor after animation
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 260, () => {
                try {
                    if (actor && actor.get_parent()) {
                        actor.get_parent().remove_child(actor);
                    }
                } catch (e) {}
                return false;
            });
        } catch (e) {
            log('[Yulo Shell] close animation error: ' + e);
        }
    });

    // Scale animation when opening windows
    windowAddedHandler = global.display.connect('window-created', (display, window) => {
        try {
            const actor = window.get_compositor_private();
            if (!actor) return;

            // Small delay to let window initialize
            GLib.timeout_add(GLib.PRIORITY_DEFAULT, 10, () => {
                try {
                    if (!actor || !actor.get_parent()) return false;

                    actor.set_pivot_point(0.5, 0.5);
                    actor.scale_x = 0.85;
                    actor.scale_y = 0.85;
                    actor.opacity = 0;

                    const scaleX = new Clutter.PropertyTransition({
                        property_name: 'scale-x',
                        duration: 200,
                        progress_mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                        from: 0.85,
                        to: 1.0,
                    });
                    const scaleY = new Clutter.PropertyTransition({
                        property_name: 'scale-y',
                        duration: 200,
                        progress_mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                        from: 0.85,
                        to: 1.0,
                    });
                    const opacity = new Clutter.PropertyTransition({
                        property_name: 'opacity',
                        duration: 200,
                        progress_mode: Clutter.AnimationMode.EASE_OUT_QUAD,
                        from: 0,
                        to: 255,
                    });

                    actor.add_transition('yulo-open-scale-x', scaleX);
                    actor.add_transition('yulo-open-scale-y', scaleY);
                    actor.add_transition('yulo-open-opacity', opacity);
                } catch (e) {
                    log('[Yulo Shell] open animation error: ' + e);
                }
                return false;
            });
        } catch (e) {
            log('[Yulo Shell] window-created error: ' + e);
        }
    });
}
