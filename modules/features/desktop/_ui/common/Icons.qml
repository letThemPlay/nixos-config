pragma Singleton

import Quickshell
import QtQuick

// The shell's only icon vocabulary: what a surface means -> a ligature of the
// theme's icon font. Surfaces name these, never a glyph.
Singleton {
  readonly property var names: ({
    "launcher": "apps",
    "search": "search",
    "clipboard": "content_paste",
    "calculator": "calculate",
    "close": "close",

    "notifications": "notifications",
    "notificationsUnread": "notifications_unread",
    "notificationsPaused": "notifications_paused",
    "clearAll": "clear_all",

    "wifiFull": "wifi",
    "wifiMedium": "wifi_2_bar",
    "wifiLow": "wifi_1_bar",
    "wifiOff": "wifi_off",
    "wired": "lan",

    "bluetooth": "bluetooth",
    "bluetoothConnected": "bluetooth_connected",
    "bluetoothOff": "bluetooth_disabled",

    "settings": "tune",
    "more": "chevron_right",

    "microphone": "mic",
    "microphoneMuted": "mic_off",

    "profileSaver": "eco",
    "profileBalanced": "balance",
    "profilePerformance": "speed",

    "keepAwake": "coffee",
    "nightLight": "nightlight",

    "recording": "fiber_manual_record",
    "recordScreen": "videocam",
    "recordRegion": "crop_free",
    "recordAudio": "graphic_eq",
    "recordStop": "stop_circle",

    "brightness": "brightness_medium",

    "volumeHigh": "volume_up",
    "volumeLow": "volume_down",
    "volumeMuted": "volume_off",

    "batteryFull": "battery_full",
    "batteryHigh": "battery_5_bar",
    "batteryMedium": "battery_3_bar",
    "batteryLow": "battery_1_bar",
    "batteryCharging": "battery_charging_full",

    "mediaPlay": "play_arrow",
    "mediaPause": "pause",

    "lock": "lock",
    "suspend": "bedtime",
    "logout": "logout",
    "reboot": "restart_alt",
    "poweroff": "power_settings_new",

    "warning": "warning"
  })

  function glyph(name) {
    return names[name] ?? "";
  }
}
