{}:

let
  reflex = import ./reflex-platform {};
  inherit (reflex.nixpkgs) haskell lib;
  overlay = self: super: {
    common = self.local "common" ./common {};
    backend = self.local "backend" ./backend {};
    frontend = self.local "frontend" ./frontend {};


    local = name: src: args:
      let justCabal = builtins.filterSource (name: type: reflex.nixpkgs.lib.hasSuffix ".cabal" name) src;
      in haskell.lib.overrideCabal (self.callCabal2nix name justCabal {}) {
        inherit src;
      };
    ghcWithPackages = self.ghcWithHoogle;
  };
  self = {
    ghc = reflex.ghc.extend overlay;
    ghcjs = reflex.ghcjs.extend overlay;

    ghcShell = reflex.workOnMulti self.ghc ["common" "backend" "frontend"];
    ghcjsShell = reflex.workOnMulti self.ghcjs ["common" "frontend"];
  };
in self
