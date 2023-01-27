#!/bin/bash
set -o errexit
devices=(flame coral sunfish redfin bramble barbet oriole raven panther cheetah)
source_dir="$1"
repo_dir="$(pwd)"

cd ${source_dir}
repo sync -c -j16 --force-sync
curl https://raw.githubusercontent.com/maade69/adevtool/13/scripts/append-sha256.py --output vendor/adevtool/scripts/append-sha256.py
source script/envsetup.sh
source script/common.sh
for device in ${devices[@]};do
    # Use frozen tag for 4th generation releases
    #if [[ $device == flame ]] || [[ $device == coral ]];then
    #    export aosp_version=TP1A.221005.002
    #else
    #    source script/common.sh
    #fi
    aosp_version=${aosp_version,,} # Convert string to lowercase 
    yarn install --cwd vendor/adevtool
    vendor/adevtool/bin/run download vendor/adevtool/dl/ -d $device -t factory ota
    sudo vendor/adevtool/bin/run generate-all vendor/adevtool/config/$device.yml -c vendor/state/$device.json -s vendor/adevtool/dl/$device-$aosp_version-*.zip --aapt2=aapt2
    sudo chown -R $(logname):$(logname) vendor/{google_devices,adevtool}
    vendor/adevtool/bin/run ota-firmware vendor/adevtool/config/$device.yml -f vendor/adevtool/dl/$device-ota-$aosp_version-*.zip
    vendor/adevtool/scripts/append-sha256.py vendor/google_devices/$device
    cp /vendor/google_devices/$device/*.sha256 $repo_dir/$device.txt
done

cd ${repo_dir}
git add *.txt
git commit -m "update to $aosp_version"
git push -fu origin HEAD:main
git push -u origin HEAD:refs/heads/$aosp_version
