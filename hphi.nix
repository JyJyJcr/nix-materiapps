{ stdenv, cmake, pkg-config, lib, blas, lapack, llvmPackages, fetchurl, gfortran
, debug ? false, mpi, scalapack, openmp ? null }:

let
  name = "hphi";
  ver = "3.5.2";
  #openblas_default_use_openmp = builtins.elem "USE_OPENMP=1" openblas.makeFlags;
  #openblas_default_use_thread = builtins.elem "USE_THREAD=1" openblas.makeFlags;
  # possible values: (0,0),(0,1),(1,1)
  #build-type = if debug then "Debug" else "Release";

  buildInputs = (lib.optionals (openmp != null) [ openmp ])
    ++ [ blas lapack mpi scalapack ];
in stdenv.mkDerivation {
  pname = "${name}";
  version = ver;

  outputs = [ "dev" "out" ];

  nativeBuildInputs = [ cmake gfortran pkg-config ];

  buildInputs = buildInputs;

  propagatedBuildInputs = buildInputs;

  passthru = { inherit mpi; };

  # lib.optionals (openmp == null) [ openblas ]
  # ++ lib.optionals (openmp != null) ([ openmp ]
  #   ++ (lib.optionals (openblas_default_use_openmp) [
  #     openblas.override
  #     { openmp = openmp; }
  #   ]) ++ (lib.optionals (!openblas_default_use_openmp) [
  #     openblas.override
  #     { singleThreaded = true; }
  #   ]));
  #   openblas.override { openmp = openmp }
  #   openmp
  # ];
  # this is completely safe because:
  # if openblas is built with openmp, it is guaranteed to use same openmp with itensor
  # if openblas is built without openmp, of course no problem!

  #propagatedBuildInputs = (lib.optionals stdenv.cc.isGNU [ ])

  # buildInputs = (lib.optionals stdenv.cc.isGNU [ gcc openblas ])
  #   ++ (lib.optionals stdenv.cc.isClang [
  #     # TODO: This may mismatch the LLVM version sin the stdenv, see #79818.
  #     # llvmPackages.openblas
  #     llvmPackages.openmp
  #   ]);

  src = fetchurl {
    url =
      "https://github.com/issp-center-dev/HPhi/releases/download/v3.5.2/HPhi-3.5.2.tar.gz";
    sha256 = "sha256-gH/36qrfRCyRNzB18Lp07dH5nC3Ev0FieQAhZU4K6sU=";
  };

  cmakeFlags = [
    #"-DCMAKE_BUILD_TYPE=${build-type}"
    "-DBLA_PREFER_PKGCONFIG=ON"
    #"-DCMAKE_EXPORT_COMPILE_COMMANDS=YES"
    #"-DNIX_LIBRARY_NAME=${name}"
    #"-DCMAKE_VERBOSE_MAKEFILE=1"
    "-DUSE_SCALAPACK=ON"
    "-DSCALAPACK_LIBRARIES=-lscalapack"
    # other flags...
  ];

  meta = {
    description = "Quantum Lattice Model Simulator Package";
    license = lib.licenses.gpl3;
  };
}
