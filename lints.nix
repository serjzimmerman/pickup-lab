{
  pkgs,
  lint-nix,
  tex,
}:
lint-nix.lib.lint-nix rec {
  inherit pkgs;
  src = ./.;

  linters = {
  };

  formatters = {
    latexindent = {
      ext = ".tex";
      cmd = "${tex}/bin/latexindent -g /dev/null -l";
      stdin = true;
    };

    black = {
      ext = ".py";
      cmd = "${pkgs.black}/bin/black $filename";
    };

    alejandra = {
      ext = ".nix";
      cmd = "${pkgs.alejandra}/bin/alejandra --quiet";
      stdin = true;
    };
  };
}
