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

#read -p "Release version string? Format X-Y-Z for ver X.Y.Z: " version

# read the version config from the project.godot file
versioncfg=$(cat ./project.godot | grep "config/version=")

# parse the config to get the version string: erase up to the first instance of ="
version=${versioncfg#*=\"}
# erase the last instance of " and anything afterwards
version=${version%\"*}

# then replace . with -
version=$(echo $version | sed y/./-/)

echo "Creating release archives for game version ${version}."
read -p "Is this OK? [Y/n/(c)hange] " answer

if [[ $answer == "c" || $answer == "change" || $answer == "C" || $answer == "Change" ]]; then
	read -p "What's the new release version, then? (Format X-Y-Z for ver X.Y.Z): " version
	echo "Creating release archives for game version ${version}, then."
elif [[ $answer != "" && $answer != "y" && $answer != "Y" ]]; then	
	echo "Bailing out of creating release."
	exit 1
fi

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
