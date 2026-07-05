_: {
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        quickshell-pill =
          let
            pname = "quickshell-pill";
            version = "0.0.2";
          in
          pkgs.stdenv.mkDerivation {
            inherit pname version;

            src = ./_quickshell-pill;

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/quickshell
              cp -r ./* $out/share/quickshell/

              mkdir -p $out/bin

              runHook postInstall
            '';

            postFixup = ''
              makeWrapper ${pkgs.quickshell}/bin/quickshell $out/bin/quickshell \
                --add-flags "-p $out/share/quickshell/shell.qml"
            '';
          };
      };

    };
}
