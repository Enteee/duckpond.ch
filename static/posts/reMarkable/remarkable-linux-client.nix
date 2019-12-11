{
  mkDerivation,
  fetchurl, dpkg,
  glibc, stdenv,

  qtbase, qtdeclarative, qtsvg, qtwebsockets,
  qtquickcontrols, qtquickcontrols2, qtgraphicaleffects,

  libsForQt511,
  libGLU_combined,
}:

let

in mkDerivation rec {

  name = "reMarkable-client";

  src = fetchurl {
    url = https://remarkable.engineering/remarkable-linux-client-0.0.5-16-1408-g7eca2b66.tgz;
    sha256 = "sha256:1305scjyi4b1wh4vr8ccszz11dvgwyka9hivyzv5j8ynqsnij58s";
  };

  buildInputs = [
    stdenv.cc.cc.lib

    libGLU_combined
    libsForQt511.karchive

    qtbase

    qtdeclarative
    qtsvg
    qtbase
    qtwebsockets

    qtquickcontrols
    qtquickcontrols2
    qtgraphicaleffects

  ];


  installPhase = ''
    mkdir -p $out/{bin,lib}
    cp reMarkable $out/bin
    cp libpdfium.so.1 $out/lib

    patchelf --set-interpreter \
      "${glibc}/lib/ld-linux-x86-64.so.2" \
      "$out/bin/reMarkable"


    patchelf \
      --set-rpath \
      "$out/lib:${libsForQt511.karchive}/lib:${qtdeclarative}/lib:${qtsvg}/lib:${qtbase.out}/lib:${qtwebsockets}/lib:${libGLU_combined}/lib:${stdenv.cc.cc.lib}/lib" \
      "$out/bin/reMarkable"
  '';
}
