{
  nh,
  runCommand,
  lib,
  stdenv,
  installShellFiles,
}:
runCommand "${nh.name}_darwin-alias" { nativeBuildInputs = [ installShellFiles ]; } (
  ''
    mkdir -p "$out/bin"
    ln -s ${lib.escapeShellArg (lib.getExe nh)} "$out/bin/nh_darwin"
  ''
  +
    lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) # sh
      ''
        installShellCompletion --cmd nh_darwin \
          --bash <("$out/bin/nh_darwin" completions --shell bash) \
          --zsh <("$out/bin/nh_darwin" completions --shell zsh) \
          --fish <("$out/bin/nh_darwin" completions --shell fish)
      ''
)
