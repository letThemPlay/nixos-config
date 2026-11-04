{
  lib,
  hardware,
  diagnostics,
}:
let
  inherit (hardware) query;

  inherit (diagnostics)
    combine
    mkDiagnostic
    mkResult
    ;

  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    length
    mapAttrsToList
    optional
    ;

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

  busIds =
    model:
    mkResult (
      mapAttrsToList
        (
          name: gpu:
          diagnostic "hardware.gpu.busId.format" [ "gpus" name "busId" ] name
            "GPU '${name}' has bus ID '${gpu.busId}'; expected PCI:<bus>:<device>:<function> in decimal (lspci's hex 01:00.0 is PCI:1:0:0)."
        )
        (
          filterAttrs (
            _: gpu: gpu.busId != null && builtins.match "PCI:[0-9]+:[0-9]+:[0-9]+" gpu.busId == null
          ) model.gpus
        )
    );

  gpus =
    model:
    let
      nvidia = query.nvidia model;
      integrated = query.integrated model;
      pairWanted = model.prime.mode != "none" && nvidia != [ ];
    in
    mkResult (
      optional (length integrated > 1) (
        diagnostic "hardware.gpu.integrated.multiple" [
          "gpus"
        ] "integrated" "Only one GPU may be integrated."
      )

      ++ optional (length nvidia > 1) (
        diagnostic "hardware.gpu.nvidia.multiple" [ "gpus" ] "nvidia" "Only one nvidia GPU is supported."
      )

      ++ optional (pairWanted && integrated == [ ]) (
        diagnostic "hardware.gpu.prime.integrated.missing" [ "prime" ] model.prime.mode
          "PRIME ${model.prime.mode} needs an integrated GPU next to the nvidia GPU; mark one integrated or set prime = \"none\"."
      )

      ++ optional (model.prime.active && builtins.any (gpu: gpu.busId == null) (nvidia ++ integrated)) (
        diagnostic "hardware.gpu.prime.busId.missing" [
          "gpus"
        ] model.prime.mode "PRIME needs the bus IDs of both the nvidia and the integrated GPU."
      )
    );

  guest =
    model:
    mkResult (
      optional (!model.guest.known) (
        diagnostic "hardware.guest.unknown" [ "guest" ] model.guest.name
          "Unknown guest type '${model.guest.name}' (known: ${concatStringsSep ", " (attrNames hardware.guests)})."
      )
    );

  #
  # The levels are what a discharging battery passes through, so out of order
  # the action would run before a warning does.
  #
  battery =
    model:
    let
      inherit (model.battery)
        active
        lowAt
        criticalAt
        actionAt
        action
        actionKnown
        ;
    in
    mkResult (
      optional (active && !actionKnown) (
        diagnostic "hardware.battery.action.unknown" [ "battery" "criticalAction" ] action
          "Unknown battery action '${action}' (known: ${concatStringsSep ", " hardware.batteryActions})."
      )

      ++ optional (active && !(lowAt > criticalAt && criticalAt > actionAt)) (
        diagnostic "hardware.battery.levels.order" [ "battery" ] "levels"
          "Battery levels must fall in order: lowAt (${toString lowAt}) > criticalAt (${toString criticalAt}) > actionAt (${toString actionAt})."
      )
    );

  all =
    model:
    combine [
      (busIds model)
      (gpus model)
      (guest model)
      (battery model)
    ];
in
{
  inherit
    mkDiagnostic
    mkResult
    busIds
    gpus
    guest
    battery
    all
    ;
}
