document_file := "result/document.pdf"

alias f := format
alias l := lint

show:
  @nix build
  @xdg-open {{justfile_directory()}}/{{document_file}} &

build:
  @jupyter execute data-processing.ipynb
  @just show

check:
  @nix build ".#all-checks" -L

check-format:
  @nix build ".#all-formats" -L

format:
  @nix build ".#format-all"
  @result/bin/format-all

lint: check format
