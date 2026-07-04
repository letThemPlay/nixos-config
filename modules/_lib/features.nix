{ inputs, ... }:
{
  resolveFeatures =
    requestedTokens:
    builtins.filter (x: x != null) (
      map (
        name:
        if builtins.hasAttr name inputs.self.nixosModules then inputs.self.nixosModules.${name} else null
      ) requestedTokens
    );
}
