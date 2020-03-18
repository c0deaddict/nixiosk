{ pkgs, config, ... }:

let

  git = pkgs.git.override {
    withManual = false;
    pythonSupport = false;
    withpcre2 = false;
    perlSupport = false;
  };

  configuration = pkgs.runCommand "configuration.git" { nativeBuildInputs = [ pkgs.buildPackages.gitMinimal ]; } ''
    git clone ${builtins.path {
      path = ../.git;
      name = "configuration-bare.git";
    }} configuration

    cd configuration
    cp ${builtins.toFile "kioskix.json" (builtins.toJSON config.kioskix)} kioskix.json
    git add --force kioskix.json

    env GIT_AUTHOR_NAME="NixOS Basalt Module" \
        GIT_AUTHOR_EMAIL=matthewbauer@users.noreply.github.com \
        GIT_COMMITTER_NAME="NixOS Basalt Module" \
        GIT_COMMITTER_EMAIL=matthewbauer@users.noreply.github.com \
      git commit -m "Add config.json"

    git clone --bare . $out
    rm -rf $out/hooks/*
  '';

in {

  boot.postBootCommands = ''
    if ! [ -d /etc/nixos/configuration.git ]; then
      mkdir -p /etc/nixos
      ${git}/bin/git clone --bare ${configuration} /etc/nixos/configuration.git

      rm -rf /etc/nixos/configuration.git/hooks
      ln -s ../basalt/targets/nixos/git-hooks /etc/nixos/configuration.git/hooks
      cp -r ${../basalt} /etc/nixos/basalt
    fi
  '';

}
