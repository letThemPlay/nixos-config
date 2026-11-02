{ lib, diagnostics }:
let
  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib) optional;

  #
  # Only the form is checked: whether a keymap, layout or zone exists is
  # known only to packages (kbd, xkeyboard-config, tzdata), and reading
  # them would build them during evaluation.
  #
  matches = regex: value: builtins.match regex value != null;

  diagnostic =
    code: path: target: message:
    mkDiagnostic {
      severity = "error";
      inherit
        code
        path
        target
        message
        ;
    };

  timeZone =
    model:
    mkResult (
      optional (model.timeZone != "UTC" && !matches "[A-Za-z_]+(/[A-Za-z0-9_+-]+)+" model.timeZone) (
        diagnostic "locale.timeZone.format" [
          "timeZone"
        ] model.timeZone "Time zone '${model.timeZone}' is not UTC or Area/Location (e.g. Europe/London)."
      )
    );

  language =
    model:
    mkResult (
      optional (model.language != "C.UTF-8" && !matches "[a-z]{2,3}_[A-Z]{2}(\\.UTF-8)?" model.language) (
        diagnostic "locale.language.format" [
          "language"
        ] model.language "Language '${model.language}' is not C.UTF-8 or ll_CC[.UTF-8] (e.g. en_GB.UTF-8)."
      )
    );

  keyboard =
    model:
    mkResult (
      optional (model.keyboard.console == "") (
        diagnostic "locale.keyboard.console.empty" [
          "keyboard"
          "console"
        ] "console" "The console keymap is empty."
      )

      ++ optional (model.keyboard.session.layout == "") (
        diagnostic "locale.keyboard.session.empty" [
          "keyboard"
          "session"
          "layout"
        ] "session" "The session keyboard layout is empty."
      )
    );

  all =
    model:
    combine [
      (timeZone model)
      (language model)
      (keyboard model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    timeZone
    language
    keyboard
    all
    ;
}
