rm -rf /usr/local/include/boost
mkdir /usr/local/include/boost
brew install boost
export MACOSX_DEPLOYMENT_TARGET=14.0
export DEVELOPER_DIR=/Applications/Xcode_14.3.1.app/Contents/Developer
export DYLD_LIBRARY_PATH=$GITHUB_WORKSPACE/scip_install/lib:$HOME/gcc/lib


curl -O https://ftp.gwdg.de/pub/misc/gcc/releases/gcc-14.2.0/gcc-14.2.0.tar.xz
curl -O https://raw.githubusercontent.com/Homebrew/formula-patches/d5dcb918a951b2dcf2d7702db75eb29ef144f614/gcc/gcc-14.2.0.diff
tar xJf gcc-14.2.0.tar.xz

pushd gcc-14.2.0
./contrib/download_prerequisites
patch -p1 < ../gcc-14.2.0.diff

./configure --prefix=$HOME/gcc --enable-checking=release --enable-languages="fortran" --disable-multilib --disable-nls --with-sysroot=/Library/Developer/CommandLineTools/SDKs/MacOSX14.sdk CC=clang CXX=clang++

make -j8
make install
export FC=$HOME/gcc/bin/gfortran
popd


wget https://boostorg.jfrog.io/artifactory/main/release/1.82.0/source/boost_1_82_0.tar.bz2
tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
mv $GITHUB_WORKSPACE/boost_1_82_0/boost/* /usr/local/include/boost/.

wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip
mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/scip_install/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis\"" > scip_install/share/config.site

rm -f /usr/local/lib/libgmp*
#wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
#tar xvf gmp-6.3.0.tar.xz
#cd gmp-6.3.0
#./configure --with-pic --disable-shared --enable-cxx --prefix=$GITHUB_WORKSPACE/scip_install
#make install -j

cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/metis
cd $GITHUB_WORKSPACE/metis-5.1.0
make config prefix=$GITHUB_WORKSPACE/scip_install/
make
make install

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis"
make
make install


cd $GITHUB_WORKSPACE
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/ --disable-java --enable-shared=no --disable-sipopt --enable-static=yes --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis"
make -j
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
unzip release-$SOPLEX_VERSION.zip
cd soplex-release-$SOPLEX_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false -DMPFR=false -DBOOST=true -DBOOST_INCLUDE_DIR=/usr/local/include/boost/
make -j$(nproc)
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DBOOST=true -DTPI=tny
make -j
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION.zip
unzip v$GCG_VERSION.zip
cd gcg-$GCG_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DSYM=none
make -j
make test
make install

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-macos-arm.zip scip_install/lib scip_install/include scip_install/bin
