{ stdenv
, lib
, rustPlatform
, installShellFiles
, makeBinaryWrapper
, darwin
, nvd
, use-nom ? true
, nix-output-monitor ? null
, rev ? "dirty"
, crate2nix
, callPackage
, buildRustCrate
, defaultCrateOverrides
}:
assert use-nom -> nix-output-monitor != null; let
  runtimeDeps = [ nvd ] ++ lib.optionals use-nom [ nix-output-monitor ];
  cargoToml = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  generated = crate2nix.tools.${stdenv.hostPlatform.system}.generatedCargoNix {
    name = "nh";
    src = ./.;
  };
  crates = callPackage "${generated}/default.nix" {
    buildRustCrateForPkgs = _: buildRustCrate.override {
      defaultCrateOverrides = defaultCrateOverrides // {
        nh = attrs: {
          version = "${cargoToml.package.version}-${rev}";
          nativeBuildInputs = [
            installShellFiles
            makeBinaryWrapper
          ];

          buildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.SystemConfiguration ];

          postInstall = ''
            wrapProgram $out/bin/nh \
              --prefix PATH : ${lib.makeBinPath runtimeDeps}
            mkdir completions
            $out/bin/nh completions --shell bash > completions/nh.bash
            $out/bin/nh completions --shell zsh > completions/nh.zsh
            $out/bin/nh completions --shell fish > completions/nh.fish
            installShellCompletion completions/*
          '';

          meta = {
            description = "Yet another nix cli helper";
            homepage = "https://github.com/ToyVo/nh_darwin";
            license = lib.licenses.eupl12;
            mainProgram = "nh";
            maintainers = with lib.maintainers; [ drupol viperML ToyVo ];
          };
        };
      };
    };
  };
in
crates.rootCrate.build
