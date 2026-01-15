{ lib, gccStdenv, fetchFromGitLab, fetchFromGitHub, git, cmake, gfortran
, pkg-config, fftw, blas, lapack, scalapack, hdf5-fortran, libxc
, enableMpi ? false, mpi,
# wannier90, libmbd,
}:

assert !blas.isILP64;
assert !lapack.isILP64;

let
  # "rev"s must exactly match the git submodule commits in the QE repo
  gitSubmodules = {
    devxlib = fetchFromGitLab {
      group = "max-centre";
      owner = "components";
      repo = "devicexlib";
      rev = "08558f7609b8aa916b55caf36c92b73af6887b13";
      hash = "sha256-sn87e5qrCSyeDsuSHudNWzRz7f3HlKvDHv2mmohWSus=";
    };

    pw2qmcpack = fetchFromGitHub {
      owner = "QMCPACK";
      repo = "pw2qmcpack";
      rev = "385bc318c63beb6d673b4602c4981bbfa3724edf";
      hash = "sha256-TgVV8dcbwvcBT9qPJRtx63bhQsxrih8QoKcddlad27E=";
    };

    wannier90 = fetchFromGitHub {
      owner = "wannier-developers";
      repo = "wannier90";
      rev = "1d6b187374a2d50b509e5e79e2cab01a79ff7ce1";
      hash = "sha256-+Mq7lM6WuwAnK/2FlDz9gNRIg2sRazQRezb3BfD0veY=";
    };

    # mbd = fetchFromGitHub {
    #   owner = "libmbd";
    #   repo = "libmbd";
    #   rev = "89a3cc199c0a200c9f0f688c3229ef6b9a8d63bd";
    #   hash = "sha256-TTvfEjoGl2fIjMsweT122B2zBqQnoz+Upo+kRK1zlz4=";
    # };

    mbd = builtins.fetchTarball {
      url =
        "https://github.com/libmbd/libmbd/releases/download/0.12.8/libmbd-0.12.8.tar.gz";
      sha256 = "sha256:0fnqmbaycf85g9vv33q32zdwpb1iklbhiglzv1mig3b94r1k1p90";
    };
  };

in gccStdenv.mkDerivation rec {
  version = "7.4.1";
  pname = "quantum-espresso";

  src = fetchFromGitHub {
    owner = "JyJyJcr";
    repo = "q-e";
    rev = "7fe8102023e5ba60f0d3378dc2e72ad12343ae4c";
    hash = "sha256-8Y5LLbEdFU5uzkK4SlrXeYMVtVD9K88nrlZOE/ceyDs=";
  };

  # add git submodules manually and fix pkg-config file
  prePatch = ''
    chmod -R +rwx external/

    substituteInPlace external/wannier90.cmake \
      --replace "qe_git_submodule_update(external/wannier90)" ""
    substituteInPlace external/devxlib.cmake \
      --replace "qe_git_submodule_update(external/devxlib)" ""
    substituteInPlace external/mbd.cmake \
      --replace "qe_git_submodule_update(external/mbd)" ""
    substituteInPlace external/CMakeLists.txt \
      --replace "qe_git_submodule_update(external/pw2qmcpack)" "" \
      --replace "qe_git_submodule_update(external/d3q)" "" \
      --replace "qe_git_submodule_update(external/qe-gipaw)" ""

    ${builtins.toString (builtins.attrValues (builtins.mapAttrs (name: val: ''
      # echo "${val}/ >> external/${name}/"
      cp -r ${val}/. external/${name}/
      # echo "what? $(ls external/${name}/src/)"
      chmod -R +rwx external/${name}
    '') gitSubmodules))}

    substituteInPlace cmake/quantum_espresso.pc.in \
      --replace 'libdir="''${prefix}/@CMAKE_INSTALL_LIBDIR@"' 'libdir="@CMAKE_INSTALL_FULL_LIBDIR@"'
  '';

  patches = [
    # this patch reverts commit 5fb5a679, which enforced static library builds.
    ./findLibxc.patch
    ./link.patch
  ];

  outputs = [ "out" "dev" ];

  passthru = { inherit mpi; };

  nativeBuildInputs = [ cmake gfortran git pkg-config ];

  buildInputs = [
    fftw
    blas
    lapack
    libxc
    hdf5-fortran
  ]
  # ++ lib.optionals stdenv.cc.isClang [
  #   # TODO: This may mismatch the LLVM version sin the stdenv, see #79818.
  #   # llvmPackages.openmp
  # ]
    ++ lib.optional enableMpi scalapack;

  #    ++ lib.optional enableMpi mpi;

  propagatedBuildInputs = lib.optional enableMpi mpi;
  propagatedUserEnvPkgs = lib.optional enableMpi mpi;

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBLA_PREFER_PKGCONFIG=ON"
    "-DQE_ENABLE_OPENMP=OFF"
    "-DQE_ENABLE_LIBXC=OFF"
    "-DQE_ENABLE_HDF5=OFF"
    "-DQE_ENABLE_PLUGINS=pw2qmcpack"
  ] ++ (lib.optionals enableMpi [
    "-DQE_ENABLE_MPI=ON"
    "-DQE_ENABLE_MPI_MODULE=ON"
    "-DQE_ENABLE_SCALAPACK=ON"
  ]) ++ (lib.optionals (!enableMpi) [ "-DQE_ENABLE_MPI=OFF" ]);

  meta = with lib; {
    description =
      "Electronic-structure calculations and materials modeling at the nanoscale";
    longDescription = ''
      Quantum ESPRESSO is an integrated suite of Open-Source computer codes for
      electronic-structure calculations and materials modeling at the
      nanoscale. It is based on density-functional theory, plane waves, and
      pseudopotentials.
    '';
    homepage = "https://www.quantum-espresso.org/";
    license = licenses.gpl2;
  };
}
