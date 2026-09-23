{ lib
, stdenvNoCC
, makeWrapper
, jdk21
, copyDesktopItems
, makeDesktopItem
, shared-mime-info
, ghdl
, iverilog
, gtkwave
, jdk ? jdk21
, withHdlTools ? false
}:

let
  javaFlags = import ./java-flags.nix;

  hdlTools = lib.optionals withHdlTools [ ghdl iverilog gtkwave ];
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "digital";
  version = "0.31";

  src = lib.cleanSourceWith {
    src = ../.;
    filter = path: type:
      let base = baseNameOf (toString path); in
      !(lib.hasSuffix ".exe" base)
      && base != "result"
      && base != ".git"
      && base != "flake.lock";
  };

  nativeBuildInputs = [ makeWrapper ] ++ lib.optional stdenvNoCC.hostPlatform.isLinux copyDesktopItems;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 Digital.jar   -t $out/share/digital
    install -Dm644 icon.svg         $out/share/icons/hicolor/scalable/apps/digital-simulator.svg
    install -Dm644 Version.txt ReleaseNotes.txt -t $out/share/doc/digital

    # Digital resolves its component library and examples relative to the jar,
    # so they have to sit next to it.
    cp -r lib examples docu $out/share/digital/

    install -Dm644 linux/digital-simulator.xml \
      -t $out/share/mime/packages

    makeWrapper ${lib.getExe' jdk "java"} $out/bin/digital \
      --add-flags ${lib.escapeShellArg (lib.escapeShellArgs javaFlags)} \
      --add-flags "-jar $out/share/digital/Digital.jar" \
      --set-default _JAVA_AWT_WM_NONREPARENTING 1 \
      ${lib.optionalString (hdlTools != []) ''--prefix PATH : ${lib.makeBinPath hdlTools}''}

    # Headless entry point: `digital-cli test foo.dig`, `digital-cli svg ...`.
    makeWrapper ${lib.getExe' jdk "java"} $out/bin/digital-cli \
      --add-flags ${lib.escapeShellArg (lib.escapeShellArgs javaFlags)} \
      --add-flags "-cp $out/share/digital/Digital.jar CLI" \
      ${lib.optionalString (hdlTools != []) ''--prefix PATH : ${lib.makeBinPath hdlTools}''}

    runHook postInstall
  '';

  desktopItems = lib.optional stdenvNoCC.hostPlatform.isLinux (makeDesktopItem {
    name = "digital-simulator";
    desktopName = "Digital";
    comment = "Easy-to-use digital logic designer and circuit simulator";
    exec = "digital %f";
    icon = "digital-simulator";
    categories = [ "Education" "Electronics" ];
    mimeTypes = [ "text/x-digital" ];
    keywords = [ "simulator" "digital" "circuits" ];
    terminal = false;
  });

  passthru = {
    inherit withHdlTools;
    mimeInfo = shared-mime-info;
  };

  meta = {
    description = "Easy-to-use digital logic designer and circuit simulator";
    homepage = "https://github.com/hneemann/Digital";
    license = lib.licenses.gpl3Only;
    mainProgram = "digital";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
  };
})
