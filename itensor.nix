{ stdenv, cmake, lib, gcc, openblas, debug ? false, llvmPackages
, fetchFromGitHub }:

let
  name = "itensor";

  build-type = if debug then "Debug" else "Release";
in stdenv.mkDerivation {
  pname = "${name}";
  version = "3.2.0";

  outputs = [ "dev" "out" ];

  nativeBuildInputs = [ cmake ];

  buildInputs = [ openblas ]
    ++ (lib.optionals stdenv.cc.isClang [ llvmPackages.openmp ]);

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
    rev = "6037d13bd353b843ab7b3649b1a968bcb27e2881";
    hash = "sha256-xIczneEmNwX+kdEhxtW3D9DuYMOcTuu+BQEcx4QMWas=";
  };

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=${build-type}"
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=YES"
    "-DNIX_LIBRARY_NAME=${name}"
    # other flags...
  ];

  meta = {
    description =
      "An efficient and flexible C++ library for performing tensor network calculations";
    license = lib.licenses.asl20;
  };
}
