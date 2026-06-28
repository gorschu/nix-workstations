{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  gnutar,
  makeDesktopItem,
  wrapGAppsHook3,
  glibc,
  gtk3,
  libx11,
  libpng,
  libxkbcommon,
  systemd,
  util-linux,
  zlib,
}:

let
  desktopItem = makeDesktopItem {
    name = "vuescan";
    desktopName = "VueScan";
    genericName = "Scanning Program";
    comment = "Scanning Program";
    icon = "vuescan";
    exec = "vuescan";
    terminal = false;
    type = "Application";
    startupNotify = true;
    categories = [
      "Graphics"
      "Scanning"
    ];
    keywords = [
      "scan"
      "scanner"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vuescan";
  version = "9.8";

  src = fetchurl {
    url = "https://www.hamrick.com/files/vuex6498.tgz";
    hash = "sha256-Q9oWI7m4KpQbOSMiRoYUeYogEOxbfFyOtlkEzzUv6UQ=";
  };

  # Stripping breaks the binary's license form.
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    gnutar
    wrapGAppsHook3
  ];

  buildInputs = [
    glibc
    gtk3
    libx11
    libpng
    libxkbcommon
    systemd
    util-linux
    zlib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -m755 -D vuescan $out/bin/vuescan
    install -m644 -D vuescan.svg $out/share/icons/hicolor/scalable/apps/vuescan.svg
    install -m644 -D vuescan.rul $out/lib/udev/rules.d/60-vuescan.rules

    mkdir -p $out/share/applications
    ln -s ${desktopItem}/share/applications/* $out/share/applications/

    runHook postInstall
  '';

  meta = {
    description = "Scanner software supporting a wide range of devices";
    homepage = "https://www.hamrick.com/";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "vuescan";
  };
})
