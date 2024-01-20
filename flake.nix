{
  description = "Jupyter Lab flake with tools for data processing and tex compilation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    lint-nix.url = "github:xc-jp/lint.nix";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    self,
    lint-nix,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-linux"];
    systemDependent = flake-utils.lib.eachSystem systems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [];
      };

      pythonEnv =
        pkgs.python310.withPackages
        (pyPkgs:
          with pyPkgs; [
            jupyter
            ipywidgets
            ipython
            ipympl
            numpy
            scipy
            pandas
            matplotlib
            black
            autopep8
          ]);

      envPackages = with pkgs; [
        pythonEnv
        bashInteractive
        coreutils
        nodePackages.pyright
        tex
        just
        pgf
        pgfplots
      ];

      lints = import ./lints.nix {
        inherit lint-nix;
        inherit pkgs;
        inherit tex;
      };

      # Yanked from: https://flyx.org/nix-flakes-latex/
      # NOTE: I do not take any credit for this stuff
      tex = pkgs.texlive.combine {
        inherit
          (pkgs.texlive)
          scheme-full
          latex-bin
          latexmk
          latexindent
          fancyhdr
          amsmath
          amscls
          cyrillic
          babel-russian
          cm-unicode
          tempora
          newtx
          biblatex
          biber
          tcolorbox
          environ
          etoolbox
          pgf
          tikzfill
          ;
      };

      # OSFONTDIR=${pkgs.corefonts}/share/fonts \
      document = pkgs.stdenvNoCC.mkDerivation rec {
        name = "document";
        src = self;
        buildInputs = with pkgs; [coreutils tex];
        phases = ["unpackPhase" "buildPhase" "installPhase"];
        buildPhase = ''
          export PATH="${pkgs.lib.makeBinPath buildInputs}";
          mkdir -p .cache/texmf-var
          env TEXMFHOME=.cache TEXMFVAR=.cache/texmf-var \
              OSFONTDIR=${pkgs.liberation_ttf}/share/fonts \
              latexmk -interaction=nonstopmode -pdf -lualatex \
              document.tex
        '';

        installPhase = ''
          mkdir -p $out
          cp document.pdf $out/
        '';
      };

      jupyterRunScript = pkgs.writeShellScriptBin "jupyter-run" ''
        ${pythonEnv}/bin/jupyter lab --no-browser --ip 0.0.0.0
      '';
    in {
      packages = {
        inherit jupyterRunScript;
        inherit document;

        inherit
          (lints)
          all-checks
          all-formats
          all-lints
          format-all
          ;

        default = document;
      };

      apps.default = {
        type = "app";
        program = "${jupyterRunScript}/bin/jupyter-run";
      };

      devShells.default = pkgs.mkShell {
        packages = envPackages;
      };
    });
  in
    systemDependent;
}
