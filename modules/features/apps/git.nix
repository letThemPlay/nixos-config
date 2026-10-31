_: {
  flake.nixosModules.git =
    {
      pkgs,
      ...
    }:
    {
      config = {
        environment.systemPackages = [ pkgs.git ];

        ltp.shell.aliases = {
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

        home-manager.sharedModules = [
          (
            { config, osConfig, ... }:
            let
              userProfile = osConfig.ltp.identity.facts.users.${config.home.username} or { };
            in
            {
              programs.git = {
                enable = true;
                settings = {
                  user = {
                    name = userProfile.fullName or "";
                    email = userProfile.email or "";
                  };
                };
              };
            }
          )
        ];
      };
    };
}
