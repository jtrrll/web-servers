{
  lib,
  lolcat,
  uutils-coreutils-noprefix,
  writeShellApplication,
}:
writeShellApplication rec {
  meta = {
    description = "Prints a splash screen";
    mainProgram = name;
    platforms = lib.platforms.all;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
  name = "splash";
  runtimeInputs = [
    lolcat
    uutils-coreutils-noprefix
  ];
  text = ''
    printf "┬ ┬┌─┐┌┐    ┌─┐┌─┐┬─┐┬  ┬┌─┐┬─┐┌─┐
    │││├┤ ├┴┐───└─┐├┤ ├┬┘└┐┌┘├┤ ├┬┘└─┐
    └┴┘└─┘└─┘   └─┘└─┘┴└─ └┘ └─┘┴└─└─┘\n" | lolcat
  '';
}
