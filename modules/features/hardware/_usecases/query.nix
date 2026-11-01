{ lib }:
let
  inherit (lib) attrValues filter;

  first = list: if list == [ ] then null else builtins.head list;
in
rec {

  all = model: attrValues model.gpus;

  integrated = model: filter (gpu: gpu.integrated) (all model);

  nvidia = model: filter (gpu: gpu.vendor == "nvidia") (all model);

  # The PRIME pair's members, or null.
  integratedGpu = model: first (integrated model);

  nvidiaGpu = model: first (nvidia model);

  # True when nvidia renders the display (no offload to an iGPU).
  nvidiaPrimary = model: nvidia model != [ ] && (model.prime.mode == "sync" || !model.prime.active);

}
