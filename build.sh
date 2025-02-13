#!/bin/sh

git clone https://github.com/perkinslr/buildroot-sedna
git clone https://github.com/perkinslr/buildroot --depth=1

cp buildroot-sedna/config buildroot/.config
cp buildroot-sedna/linuxconfig buildroot
pushd buildroot

make $JOBS linux-configure
mv linuxconfig ./output/build/linux-6*/.config
make $JOBS

cp output/images/rootfs.cramfs src/main/resources/generated/

./gradlew build

popd

git clone https://github.com/fnuecke/ceres/

pushd ceres
chmod +x gradlew
./gradlew build

popd
git clone https://github.com/perkinslr/sedna

mkdir sedna/libs
cp ceres/build/libs/* sedna/libs

pushd sedna
chmod +x gradlew
./gradlew build

popd

git clone https://github.com/perkinslr/sedna-mc --depth=1
pushd sedna-mc
./gradlew build
popd

mkdir merged
echo "Making Merged Jar!"
pushd merged
unp ../buildroot/build/libs/*.jar -- -o
unp ../ceres/build/libs/*.jar -- -o
unp ../sedna-mc/build/libs/*.jar -- -o
unp ../sedna/build/libs/*.jar -- -o
cp ../buildroot-sedna/MANIFEST.MF META-INF

zip -9 -r ../sedna.jar ./*

popd
git clone https://github.com/perkinslr/oc2r

rm -rf sedna sedna-mc ceres

pushd oc2r
mkdir libs
mv ../sedna.jar libs/

git checkout 1.18.x
./gradlew build

git checkout 1.20.1
./gradlew build

git checkout 1.19.2
wget https://proxy-maven.covers1624.net/repository/maven-public/mrtjp/ProjectRed/1.19.2-4.19.0-beta%2B33/ProjectRed-1.19.2-4.19.0-beta%2B33-api.jar -O libs/ProjectRed.jar

./gradlew build



