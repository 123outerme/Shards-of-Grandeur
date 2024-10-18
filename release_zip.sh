#!/bin/bash

#working_dir=${PWD}

# expected to be in working_dir aka directory of this script
prepare_temp_dir() {
    mkdir release/temp
    cp README.md LICENSE release/temp/
    cp graphics/LICENSE release/temp/GRAPHICS_LICENSE.txt
    cp audio/LICENSE release/temp/AUDIO_LICENSE.txt
    cp audio/sfx/credits.md release/temp/SFX_CREDITS.md
    cp audio/music/credits.md release/temp/MUSIC_CREDITS.md
}

# expected to be in working_dir aka directory of this script
cleanup_temp_dir() {
    rm -rf release/temp/*
    rmdir release/temp
}

read -p "Release version string? Format X-Y-Z for ver X.Y.Z: " version

cleanup_temp_dir
prepare_temp_dir
echo Building Linux release...
cp -r release/linux_x86_64/* release/temp/
pushd release/temp
zip -r "shards_of_grandeur_${version}_linux_x86_64.zip" ./*
mv "shards_of_grandeur_${version}_linux_x86_64.zip" ..
popd
cleanup_temp_dir

prepare_temp_dir
echo Building Windows release...
cp -r release/windows/* release/temp/
pushd release/temp
zip -r "shards_of_grandeur_${version}_windows.zip" ./*
mv "shards_of_grandeur_${version}_windows.zip" ..
popd
cleanup_temp_dir

prepare_temp_dir
echo Building Mac release...
pushd release
unzip mac/ShardsOfGrandeur.zip -d ./temp_mac/
popd
cp -r release/temp_mac/* release/temp/
pushd release/temp
zip -r "shards_of_grandeur_${version}_mac.zip" ./*
mv "shards_of_grandeur_${version}_mac.zip" ..
popd
cleanup_temp_dir
rm -rf release/temp_mac/*
rmdir release/temp_mac

echo Copying Android APK to base release/ directory...
cp release/android/ShardsOfGrandeur-android-both-arch.apk release/ShardsOfGrandeur.apk

echo "Done compressing release build for Shards of Grandeur version ${version}!"
