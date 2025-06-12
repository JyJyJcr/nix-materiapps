{ stdenv, cmake, pkg-config, lib, blas, lapack, llvmPackages, fetchFromGitHub
, debug ? false, openmp ? null }:

let
  name = "itensor";
  #openblas_default_use_openmp = builtins.elem "USE_OPENMP=1" openblas.makeFlags;
  #openblas_default_use_thread = builtins.elem "USE_THREAD=1" openblas.makeFlags;
  # possible values: (0,0),(0,1),(1,1)
  build-type = if debug then "Debug" else "Release";

  buildInputs = (lib.optionals (openmp != null) [ openmp ]) ++ [ blas lapack ];
in stdenv.mkDerivation {
  pname = "${name}";
  version = "3.2.0";

  outputs = [ "dev" "out" ];

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = buildInputs;

  propagatedBuildInputs = buildInputs;

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

  src = fetchFromGitHub {
    owner = "JyJyJcr";
    repo = "ITensor";
    rev = "e8d664f6996790e52cb6160429d606a29bb57144";
    hash = "sha256-vt1WMe14OLKgXrlGVgwy3jJjjQymBvLZLKRZy/QKA6U=";
  };

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=${build-type}"
    "-DBLA_PREFER_PKGCONFIG=ON"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=YES"
    "-DNIX_LIBRARY_NAME=${name}"
    # other flags...
  ] ++ lib.optionals (openmp != null) [ "-DITENSOR_USE_OPENMP=ON" ];

  meta = {
    description =
      "An efficient and flexible C++ library for performing tensor network calculations";
    license = lib.licenses.asl20;
  };
}
