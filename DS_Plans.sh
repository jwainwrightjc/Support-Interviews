#!/bin/bash


DownloadUrl="https://cdn.empire.death_start_blueprints_v2.dmg"



DATE=$(date '+%Y-%m-%d-%H-%M-%S')

TempFolder="Download-$DATE"

mkdir /tmp/$TempFolder


cd /tmp/$TempFolder


curl -s -O "$DownloadUrl"


DownloadFile="$(ls)"


regex='\.dmg$'
if [[ $DownloadFile =~ $regex ]]; then
    DMGFile="$(echo "$DownloadFile")"
    echo "Death Star Blueprints Found: $DMGFile"
else
    echo "File: $DownloadFile is not the file were looking for"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi



hdiutilAttach=$(hdiutil attach /tmp/$TempFolder/$DMGFile -nobrowse)


err=$?
if [ ${err} -ne 0 ]; then
    echo "Error: ${err}"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi

regex='\/Volumes\/.*'
if [[ $hdiutilAttach =~ $regex ]]; then
    DMGVolume="${BASH_REMATCH[@]}"
    echo "Located Volume with the blueprints: $DMGVolume"
else
    echo "Volume with blueprints not found"
    rm -r /tmp/$TempFolder
    echo "Deleted /tmp/$TempFolder"
    exit 1
fi


DMGMountPoint="$(hdiutil info | grep "$DMGVolume" | awk '{ print $1 }')"


DMGAppPath=$(find "$DMGVolume" -name "*.app" -depth 1)

userInstall=false

for user in $(dscl . list /Users | grep -vE 'root|daemon|nobody|^_')
do
    if [[ -d /Users/$user ]]; then
       
        if [[ ! -d /Users/$user/Applications ]]; then
            mkdir /Users/$user/Applications
        fi
        if [[ -d /Users/$user/Applications/JumpCloud\ Password\ Manager.app ]]; then
            
            rm -rf /Users/$user/Applications/JumpCloud\ Password\ Manager.app
        fi

        
        cp -pPR "$DMGAppPath" /Users/$user/Applications/

        
        chown -v $user /Users/$user/Applications/Death\ Star\ Plans.app

        if [[ -d /Users/$user/Desktop/Death\ Star\ Plans.app ]]; then
            
            rm -rf /Users/$user/Desktop/Death\ Star\ Plans.app
        fi


        userInstall=true
        echo "Copied $DMGAppPath to /Users/$user/Applications"

        
        ln -s /Users/$user/Applications/JumpCloud\ Password\ Manager.app /Users/$user/Desktop/Death\ Star\ Plans.app
    fi
done



if [ -d /Applications/Death\ Star\ Plans.app ] && [ $userInstall = true ]; then
    # It's a Trap!
    rm -rf /Applications/Death\ Star\ Plans.app
fi


hdiutil detach $DMGMountPoint

echo "Used hdiutil to detach $DMGFile from $DMGMountPoint"

err=$?
if [ ${err} -ne 0 ]; then
    abort "Could not detach DMG: $DMGMountPoint Error: ${err}"
fi


rm -r /tmp/$TempFolder

echo "Deleted /tmp/$TempFolder"

exit
