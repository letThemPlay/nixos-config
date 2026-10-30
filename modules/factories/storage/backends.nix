{ config, ... }:
{
  #
  # Storage backend registry. The keys are the valid values of
  # ohmydarlings.storage.filesystem.type; types.backend and validation
  # derive from them, and the storage module renders the selected one.
  #
  # A backend provides:
  #
  #   disko    : { model } -> { devices; rootDevice; }
  #   rollback : { model, rootDevice, pkgs, utils } -> { active; script; service; }
  #
  # Backend-agnostic adapters (preservation) live outside the registry.
  #
  flake.library.storageBackends = {
    btrfs = config.flake.library.storageTransformBtrfs;
  };
}
