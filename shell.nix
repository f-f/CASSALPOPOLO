# generated using pypi2nix tool (version: 2.0.0)
# See more at: https://github.com/nix-community/pypi2nix
#
# COMMAND:
#   pypi2nix -V 3.7 -e python-osc -e mido -e python-rtmidi
#

{ pkgs ? import <nixpkgs> {},
  overrides ? ({ pkgs, python }: self: super: {})
}:

let

  inherit (pkgs) makeWrapper;
  inherit (pkgs.stdenv.lib) fix' extends inNixShell;

  pythonPackages =
  import "${toString pkgs.path}/pkgs/top-level/python-packages.nix" {
    inherit pkgs;
    inherit (pkgs) stdenv;
    python = pkgs.python37;
    # patching pip so it does not try to remove files when running nix-shell
    overrides =
      self: super: {
        bootstrapped-pip = super.bootstrapped-pip.overrideDerivation (old: {
          patchPhase = old.patchPhase + ''
            if [ -e $out/${pkgs.python37.sitePackages}/pip/req/req_install.py ]; then
              sed -i \
                -e "s|paths_to_remove.remove(auto_confirm)|#paths_to_remove.remove(auto_confirm)|"  \
                -e "s|self.uninstalled = paths_to_remove|#self.uninstalled = paths_to_remove|"  \
                $out/${pkgs.python37.sitePackages}/pip/req/req_install.py
            fi
          '';
        });
      };
  };

  commonBuildInputs = [];
  commonDoCheck = false;

  withPackages = pkgs':
    let
      pkgs = builtins.removeAttrs pkgs' ["__unfix__"];
      interpreterWithPackages = selectPkgsFn: pythonPackages.buildPythonPackage {
        name = "python37-interpreter";
        buildInputs = [ makeWrapper ] ++ (selectPkgsFn pkgs);
        buildCommand = ''
          mkdir -p $out/bin
          ln -s ${pythonPackages.python.interpreter} \
              $out/bin/${pythonPackages.python.executable}
          for dep in ${builtins.concatStringsSep " "
              (selectPkgsFn pkgs)}; do
            if [ -d "$dep/bin" ]; then
              for prog in "$dep/bin/"*; do
                if [ -x "$prog" ] && [ -f "$prog" ]; then
                  ln -s $prog $out/bin/`basename $prog`
                fi
              done
            fi
          done
          for prog in "$out/bin/"*; do
            wrapProgram "$prog" --prefix PYTHONPATH : "$PYTHONPATH"
          done
          pushd $out/bin
          ln -s ${pythonPackages.python.executable} python
          ln -s ${pythonPackages.python.executable} \
              python3
          popd
        '';
        passthru.interpreter = pythonPackages.python;
      };

      interpreter = interpreterWithPackages builtins.attrValues;
    in {
      __old = pythonPackages;
      inherit interpreter;
      inherit interpreterWithPackages;
      mkDerivation = args: pythonPackages.buildPythonPackage (args // {
        nativeBuildInputs = (args.nativeBuildInputs or []) ++ args.buildInputs;
      });
      packages = pkgs;
      overrideDerivation = drv: f:
        pythonPackages.buildPythonPackage (
          drv.drvAttrs // f drv.drvAttrs // { meta = drv.meta; }
        );
      withPackages = pkgs'':
        withPackages (pkgs // pkgs'');
    };

  python = withPackages {};

  generated = self: {
    "mido" = python.mkDerivation {
      name = "mido-1.2.9";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/47/a8/f05e3e6491568de9e03506a869a6039e2892d8350809203bd9abcf4b17a8/mido-1.2.9.tar.gz";
        sha256 = "c4a7d5528fefa3d3dcaa2056d4bc873e2c96a395658d15af5a89c8c3fa7c7acc";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [
        self."python-rtmidi"
      ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://mido.readthedocs.io/";
        license = licenses.mit;
        description = "MIDI Objects for Python";
      };
    };

    "python-osc" = python.mkDerivation {
      name = "python-osc-1.7.2";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/03/5e/6b7b09b08d8810e48b056f2c3b6409d5c5e1d0fd48c357cb9a6f6852fcbf/python-osc-1.7.2.tar.gz";
        sha256 = "d04f223048f461d60fa7214eeb0f605ddf4bd40aba5a03c8cff3ec42f73902b3";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://github.com/attwad/python-osc";
        license = "UNKNOWN";
        description = "Open Sound Control server and client implementations in pure Python";
      };
    };

    "python-rtmidi" = python.mkDerivation {
      name = "python-rtmidi-1.3.0";
      src = pkgs.fetchurl {
        url = "https://files.pythonhosted.org/packages/af/fb/705cbdc6f27bdb428f57f4751034665798ca166fad7acb57a28a148a1549/python-rtmidi-1.3.0.tar.gz";
        sha256 = "61e9d1c1f1202a1577f06644948af985427030984ff956970a22b50f080d4c2d";
};
      doCheck = commonDoCheck;
      buildInputs = commonBuildInputs ++ [ pkgs.jack2 pkgs.pkg-config pkgs.alsaLib ];
      propagatedBuildInputs = [ ];
      meta = with pkgs.stdenv.lib; {
        homepage = "https://chrisarndt.de/projects/python-rtmidi/";
        license = licenses.mit;
        description = "A Python binding for the RtMidi C++ library implemented using Cython.";
      };
    };
  };
  localOverridesFile = ./requirements_override.nix;
  localOverrides = import localOverridesFile { inherit pkgs python; };
  commonOverrides = [
    
  ];
  paramOverrides = [
    (overrides { inherit pkgs python; })
  ];
  allOverrides =
    (if (builtins.pathExists localOverridesFile)
     then [localOverrides] else [] ) ++ commonOverrides ++ paramOverrides;

in python.withPackages
   (fix' (pkgs.lib.fold
            extends
            generated
            allOverrides
         )
   )
