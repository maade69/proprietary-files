#!/bin/bash
set -o errexit
devices=(flame coral sunfish redfin bramble barbet oriole raven panther cheetah)
source_dir="$1"
repo_dir="$(pwd)"

function get_tag() {
    local factoryImg=$(ls ${source_dir}/vendor/adevtool/dl/$1-t*.zip)
    local zipName=$(basename $factoryImg .zip)
    local aosp_version=$(echo $zipName | cut -d "-" -f 2)
    echo $aosp_version
    #export aosp_version=$(echo $(basename $(ls ${source_dir}/vendor/adevtool/dl/$1-t*.zip) .zip) | cut -d "-" -f 2)

}
cd ${source_dir}
repo sync -c -j16 --force-sync
curl https://raw.githubusercontent.com/maade69/adevtool/13/scripts/append-sha256.py --output vendor/adevtool/scripts/append-sha256.py
source script/envsetup.sh
rm -rf ${source_dir}/vendor/adevtool/dl/*
yarn install --cwd vendor/adevtool
for device in ${devices[@]};do
    # Use frozen tag for 4th generation releases
    #if [[ $device == flame ]] || [[ $device == coral ]];then
    #    export aosp_version=TP1A.221005.002
    #else
    #    source script/common.sh
    #fi
    #aosp_version=${aosp_version,,} # Convert string to lowercase 
    vendor/adevtool/bin/run download vendor/adevtool/dl/ -d $device -t factory ota
    aosp_version=$(get_tag $i)
    sudo vendor/adevtool/bin/run generate-all vendor/adevtool/config/$device.yml -c vendor/state/$device.json -s vendor/adevtool/dl/$device-t*.zip --aapt2=aapt2
    sudo chown -R $(logname):$(logname) vendor/{google_devices,adevtool}
    vendor/adevtool/bin/run ota-firmware vendor/adevtool/config/$device.yml -f vendor/adevtool/dl/$device-ota-*.zip
    vendor/adevtool/scripts/append-sha256.py vendor/google_devices/$device
    cp /vendor/google_devices/$device/*.sha256 $repo_dir/$device.txt
done

cd ${repo_dir}
git add *.txt
git commit -m "update to $aosp_version"
git push -fu origin HEAD:main
git push -u origin HEAD:refs/heads/$aosp_version
