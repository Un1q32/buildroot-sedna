#!/usr/bin/env bash
# shellcheck disable=2086

git clone https://github.com/OpenComputers2-Reimagined/buildroot-sedna && \
git clone https://github.com/OpenComputers2-Reimagined/buildroot --depth=1 && \

pushd buildroot || exit 1


if command -v nproc > /dev/null; then
    cpus=$(nproc)
else
    cpus=$(sysctl -n hw.ncpu 2> /dev/null)
    [ -z "$cpus" ] && cpus=1
fi

jobs=$((cpus * 2 / 3))
[ "$jobs" = 0 ] && jobs=1

export JOBS="-j$jobs -l$jobs"

make $JOBS || exit 1

mkdir -p src/main/resources/generated/ 
cp output/images/rootfs.cramfs src/main/resources/generated/ || exit 1

./gradlew build || exit 1

popd || exit 1

git clone https://github.com/fnuecke/ceres || exit 1

pushd ceres || exit 1 
chmod +x gradlew || exit 1 
./gradlew build || exit 1 

popd || exit 1
git clone https://github.com/perkinslr/sedna || exit 1 

mkdir sedna/libs || exit 1 
cp ceres/build/libs/* sedna/libs || exit 1  

pushd sedna || exit 1 
chmod +x gradlew || exit 1 
./gradlew build || exit 1 

popd || exit 1

git clone https://github.com/perkinslr/sedna-mc --depth=1 || exit 1 
pushd sedna-mc || exit 1 
./gradlew build || exit 1 
popd || exit 1

mkdir merged || exit 1 
echo "Making Merged Jar!"
pushd merged || exit 1 
unzip -o ../buildroot/build/libs/*.jar
unzip -o ../ceres/build/libs/*.jar
unzip -o ../sedna-mc/build/libs/*.jar
unzip -o ../sedna/build/libs/*.jar
cp ../buildroot-sedna/MANIFEST.MF META-INF || exit 1  

zip -9 -r ../sedna.jar ./* || exit 1  

popd || exit 1
git clone https://github.com/perkinslr/oc2r || exit 1 

rm -rf sedna sedna-mc ceres || exit 1  

pushd oc2r || exit 1  
mkdir libs || exit 1  
cp ../sedna.jar libs/ || exit 1  

git checkout 1.18.x 
./gradlew build 

git checkout 1.20.1 
./gradlew build 

git checkout 1.19.2
wget https://proxy-maven.covers1624.net/repository/maven-public/mrtjp/ProjectRed/1.19.2-4.19.0-beta%2B33/ProjectRed-1.19.2-4.19.0-beta%2B33-api.jar -O libs/ProjectRed.jar

./gradlew build
