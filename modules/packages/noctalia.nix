{
  lib,
  ...
}:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages = {
        noctalia-beta =
          let
            pname = "noctalia";
            version = "5.0.0-beta1";
          in
          pkgs.stdenv.mkDerivation {
            inherit pname version;

            src = pkgs.fetchFromGitHub {
              owner = "noctalia-dev";
              repo = "noctalia";
              rev = "v${version}";
              hash = "sha256-6fvuoptg/RzxtebP+OC2LtqVZSjzs4fBg6ilYzuFjqQ="; # Update with actual hash
            };

            nativeBuildInputs = [
              pkgs.meson
              pkgs.ninja
              pkgs.pkg-config
              pkgs.cmake
              pkgs.systemd
              pkgs.wayland-protocols
              pkgs.freetype
              pkgs.fontconfig
              pkgs.cairo
              pkgs.pango
              pkgs.librsvg
              pkgs.pipewire
              pkgs.pam
              pkgs.wireplumber
              pkgs.curl
              pkgs.sdbus-cpp_2
              pkgs.makeWrapper
              pkgs.wayland-scanner
            ];

            buildInputs = [
              pkgs.sdbus-cpp_2
              pkgs.wayland
              pkgs.libGL
              pkgs.libxkbcommon
              pkgs.libwebp
              pkgs.wuffs
              pkgs.libqalculate
              pkgs.jemalloc
              pkgs.polkit
            ];

            mesonFlags = [
              "-Djemalloc=enabled"
            ];

            postInstall = ''
              wrapProgram $out/bin/noctalia \
                --prefix PATH : ${lib.makeBinPath [ pkgs.polkit ]}
            '';

            meta = with lib; {
              description = "Sleek and minimal desktop shell thoughtfully crafted for Wayland";
              homepage = "https://github.com/noctalia-dev/noctalia";
              license = licenses.mit;
              platforms = platforms.linux;
            };
          };
      };

      packages.default = config.packages.noctalia-dev;
    };
}
