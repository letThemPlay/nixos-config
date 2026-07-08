_: {
  flake.nixosModules.git =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      config = {
        environment.systemPackages = [ pkgs.git ];

        home-manager.users = lib.mapAttrs (_: profile: {
          programs.git = {
            enable = true;
            userName = profile.fullName or "";
            userEmail = profile.email or "";
          };

          programs.zsh.shellAliases = {
            g = "git";
            gs = "git status -sb";
            ga = "git add";
            gaa = "git add --all";
            gc = "git commit -m";
            gca = "git commit --amend";
            gp = "git push";
            gpf = "git push --force-with-lease";
            gl = "git pull";
            gd = "git diff";
            gb = "git branch";
            gco = "git checkout";
            gcb = "git checkout -b";
            gsw = "git switch";
            gsc = "git switch -c";

            glog = "git log --graph --oneline --decorate --all";
          };
        }) config.ltp.users.registry;
      };
    };
}
