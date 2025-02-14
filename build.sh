#!/bin/bash

git clone https://github.com/perkinslr/buildroot-sedna && \
git clone https://github.com/perkinslr/buildroot --depth=1 && \

cp buildroot-sedna/config buildroot/.config && \
cp buildroot-sedna/linuxconfig buildroot && \
pushd buildroot || exit 1

export JOBS="-j$(python -c 'print(__import__("os").cpu_count() * 3 // 4)') -l$(python -c 'print(__import__("os").cpu_count() * 3 // 4)')"

make $JOBS linux-configure  || exit 1 
mv linuxconfig ./output/build/linux-6*/.config || exit 1
make $JOBS || exit 1

mkdir -p src/main/resources/generated/ 
cp output/images/rootfs.cramfs src/main/resources/generated/ || exit 1

./gradlew build || exit 1

popd

git clone https://github.com/fnuecke/ceres/ || exit 1

pushd ceres || exit 1 
chmod +x gradlew || exit 1 
./gradlew build || exit 1 

popd
git clone https://github.com/perkinslr/sedna || exit 1 

mkdir sedna/libs || exit 1 
cp ceres/build/libs/* sedna/libs || exit 1  

pushd sedna || exit 1 
chmod +x gradlew || exit 1 
./gradlew build || exit 1 

popd

git clone https://github.com/perkinslr/sedna-mc --depth=1 || exit 1 
pushd sedna-mc || exit 1 
./gradlew build || exit 1 
popd

mkdir merged || exit 1 
echo "Making Merged Jar!"
pushd merged || exit 1 
unzip -o ../buildroot/build/libs/*.jar
unzip -o ../ceres/build/libs/*.jar
unzip -o ../sedna-mc/build/libs/*.jar
unzip -o ../sedna/build/libs/*.jar
cp ../buildroot-sedna/MANIFEST.MF META-INF || exit 1  

zip -9 -r ../sedna.jar ./* || exit 1  

popd
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



