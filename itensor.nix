{ stdenv, cmake, lib, openblas, llvmPackages, fetchFromGitHub, debug ? false
, openmp ? null }:

let
  name = "itensor";
  openblas_default_use_openmp = builtins.elem "USE_OPENMP=1" openblas.makeFlags;
  #openblas_default_use_thread = builtins.elem "USE_THREAD=1" openblas.makeFlags;
  # possible values: (0,0),(0,1),(1,1)
  build-type = if debug then "Debug" else "Release";
in stdenv.mkDerivation {
  pname = "${name}";
  version = "3.2.0";

  outputs = [ "dev" "out" ];

  nativeBuildInputs = [ cmake ];

  buildInputs = lib.optionals (openmp == null) [ openblas ]
    ++ lib.optionals (openmp != null) ([ openmp ]
      ++ (lib.optionals (openblas_default_use_openmp) [
        openblas.override
        { openmp = openmp; }
      ]) ++ (lib.optionals (!openblas_default_use_openmp) [
        openblas.override
        { singleThreaded = true; }
      ]));
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
    rev = "c7ff682147329992594b6c96b3f49514d08ea7b0";
    hash = "sha256-9FFEwrRgcU4Ys4yjqEBNl2G1AsGzL77/c4OyAkl6Khg=";
  };

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=${build-type}"
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
