{ pkgs ? import (builtins.fetchTarball {
    url = "https://github.com/matthewbauer/nixpkgs/archive/19f78b3461c95433e7b58df7488d460f8df8049d.tar.gz";
    sha256 = "0qi3w6zm9dlc0nlvm9wck0sqz61kqgyvrcr76x2i9i9vdlx9ssxq";
  }) {}
, hostName
, programFunc
, authorizedKeys
, crossSystem }:

(import (pkgs.path + /nixos/lib/eval-config.nix) {
  modules = [
    (pkgs.path + /nixos/modules/profiles/clone-config.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/channel.nix)
    (pkgs.path + /nixos/modules/installer/cd-dvd/sd-image.nix)
    ./rpi-sd.nix
    ./cage.nix
    ({lib, pkgs, ...}: {
      sdImage.compressImage = false;

      networking.hostName = hostName;

      services.openssh = {
        enable = true;
        permitRootLogin = "without-password";
      };

      users.users.root = {
        openssh.authorizedKeys.keys = authorizedKeys;
      };

      users.users.kiosk = {
        isNormalUser = true;
        useDefaultShell = true;
      };

      services.cage = {
        enable = true;
        user = "kiosk";
        program = programFunc pkgs;
      };

      # Setup cross compilation.
      nixpkgs = {
        overlays = [(self: super: {
          gtk3 = super.gtk3.override { cupsSupport = false; };
          webkitgtk = super.webkitgtk.override {
            gst-plugins-bad = null;
            enableGeoLocation = false;
            stdenv = super.stdenv;
          };
          epiphany = super.epiphany.override {
            gst_all_1 = super.gst_all_1 // {
              gst-plugins-bad = null;
              gst-plugins-ugly = null;
              gst-plugins-good = null;
            };
          };
          python37 = super.python37.override {
            packageOverrides = self: super: { cython = super.cython.override { gdb = null; }; };
          };
          libass = super.libass.override { encaSupport = false; };
          libproxy = super.libproxy.override { networkmanager = null; };
          enchant2 = super.enchant2.override { hspell = null; };
          cage = super.cage.override { xwayland = null; };
        }) ];
        inherit crossSystem;
      };

      # Disable some stuff that doesn’t cross compile / take a long time.
      boot.supportedFilesystems = lib.mkForce [ "vfat" ];
      programs.command-not-found.enable = false;
      security.pam.services.su.forwardXAuth = lib.mkForce false;
      powerManagement.enable = false;
      documentation.enable = false;
      services.udisks2.enable = false;
      fonts.fontconfig.enable = false;
      security.polkit.enable = false;
    }) ];
}).config.system.build.sdImage