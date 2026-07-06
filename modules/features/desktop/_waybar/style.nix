# modules/features/wm/waybar.nix snippet inside home-manager module context
{ config, ... }: {
  # 👑 THE STYLIX INTERCEPT BYPASS:
  # Prevents Stylix from applying global generic styling overrides over your Waybar elements.
  # This unblocks our custom CSS variable bindings down below! [INDEX: 1.1.6]
  stylix.targets.waybar.enable = false;

  programs.waybar.style = ''
    /* 👑 THE NATIVE STYLIX BASE16 VARIABLE INJECTION MAP:
       We explicitly pull your machine's cryptographically secure colors straight from 
       the active theme profile, keeping everything consistent over your ribbons! [INDEX: 1.1.6] */
    @define-color base00 #${config.lib.stylix.colors.base00}; /* Default Background */
    @define-color base01 #${config.lib.stylix.colors.base01}; /* Lighter Background */
    @define-color base02 #${config.lib.stylix.colors.base02}; /* Selection Background */
    @define-color base03 #${config.lib.stylix.colors.base03}; /* Comments, Arrows */
    @define-color base04 #${config.lib.stylix.colors.base04}; /* Dark Foreground */
    @define-color base05 #${config.lib.stylix.colors.base05}; /* Default Foreground */
    @define-color base06 #${config.lib.stylix.colors.base06}; /* Light Foreground */
    @define-color base07 #${config.lib.stylix.colors.base07}; /* Light Background */
    @define-color base08 #${config.lib.stylix.colors.base08}; /* Variables, Alerts (Red) */
    @define-color base09 #${config.lib.stylix.colors.base09}; /* Integers, Warning (Orange) */
    @define-color base0A #${config.lib.stylix.colors.base0A}; /* Classes, Warning (Yellow) */
    @define-color base0B #${config.lib.stylix.colors.base0B}; /* Strings, Positive (Green) */
    @define-color base0C #${config.lib.stylix.colors.base0C}; /* Support, Teal */
    @define-color base0D #${config.lib.stylix.colors.base0D}; /* Functions, Secondary Accent (Blue) */
    @define-color base0E #${config.lib.stylix.colors.base0E}; /* Keywords, Primary Accent (Purple) */
    @define-color base0F #${config.lib.stylix.colors.base0F}; /* Deprecated, Brown */

    @define-color transparent-base alpha(@base00, 0);

    * {
        border: none;
        border-radius: 0;
        min-height: 0;
        margin: 3px;
        padding: 0;
    }

    window#waybar {
        background-color: @transparent-base;
        color: @base05;
        transition-property: background-color;
        transition-duration: .5s;
        font-family: "JetBrains Mono", "Symbols Nerd Font Mono", sans-serif;
    }

    .modules-left,
    .modules-center,
    .modules-right {
        background-color: alpha(@base01, 0.85); /* 👑 Uses exact Stylix Base01 with your 0.85 opacity */
        border-radius: 10px;
        color: @base05;
        font-family: 'Inter', 'Noto Sans', sans-serif;
        font-size: 12px;
        padding: 5px;
    }

    /* 🏷️ Workspace Navigation Module Layout Styling */
    #workspaces button {
        border-radius: 8px;
        color: @base04;
        padding: 0px 6px;
        transition: all 0.1s ease-in-out;
    }

    #workspaces button.active {
        color: @base00;               /* Solid deep background contrasting text */
        background-color: @base0D;    /* 👑 FIXED: Uses your exact active Stylix function blue accent! */
    }

    #workspaces button.persistent,
    #workspaces button.special {
        font-weight: bold;
        font-style: italic;
        color: @base0E;
    }

    #workspaces button:hover {
        background-color: alpha(@base02, 0.5);
        color: @base05;
    }

    /* 📱 Hardware System Tray Element Modules Alignment Space */
    #clock,
    #custom-weather,
    #cpu,
    #memory,
    #network,
    #mpris,
    #wireplumber,
    #tray,
    #battery,
    #bluetooth {
        padding: 0.2rem 0.5rem;
    }

    /* ⚠️ System Warning Alert Metrics color maps */
    #cpu.warning,
    #memory.warning,
    #network.disconnected,
    #wireplumber.muted,
    #bluetooth.disabled,
    #bluetooth.off {
        color: @base0A; /* 👑 FIXED: Standardizes warning alerts to your active Stylix Yellow! */
    }

    /* 🚨 System Critical Alert Metrics color maps */
    #cpu.critical,
    #memory.critical {
        color: @base08; /* 👑 FIXED: Maps critical states directly to Stylix Red! */
    }

    /*  Bluetooth State Module Maps */
    #bluetooth.connected {
        color: @base0B; /* 👑 FIXED: Toggles positive connections to your active Stylix Green! */
    }

    #bluetooth.discoverable {
        text-decoration: underline;
        color: @base0C;
    }

    /*    Battery State Module Maps */
    #battery.warning {
        color: @base09; /* Matches your Stylix Warning Orange */
    }

    #battery.critical:not(.charging) {
        color: @base08; /* Matches your Stylix Critical Red */
        animation: blink 0.5s linear infinite alternate;
    }

    /*    MPRIS Music Player Card Styles */
    #mpris {
        color: @base0D; /* Functions Blue accent track marker */
    }

    #mpris.paused {
        color: @base04; /* Darker foreground text sleep fill */
    }
  '';
}
