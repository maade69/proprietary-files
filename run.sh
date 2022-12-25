#!/bin/sh
devices=(flame coral sunfish redfin bramble barbet oriole raven panther cheetah)

git clone https://github.com/GrapheneOS/{script,state} /work/{script,state}
source /work/script/common.sh

yarn install --cwd work/adevtool/
mkdir /work/vendor
for device in ${devices[@]};do
    work/adevtool/bin/run download work/adevtool/dl/ -d $device -b $aosp_version -t factory ota
    sudo work/adevtool/bin/run generate-all work/adevtool/config/$device.yml -c work/state/$device.json -s work/adevtool/dl/$device-$aosp_version-*.zip --aapt2=/work/bin/aapt2
    sudo chown -R $(logname):$(logname) work/{google_devices,adevtool}
    work/adevtool/bin/run ota-firmware work/adevtool/config/$device.yml -f work/adevtool/dl/$device-ota-$aosp_version-*.zip
    work/adevtool/scripts/append-sha256.py /work/vendor/google_devices/$device
    cp /work/vendor/google_devices/$device/*.sha256 $GITHUB_WORKSPACE/$device.txt
done

git add *.txt
git commit -m "update to $aosp_version"
git push -fu origin HEAD:main
git push -u origin HEAD:refs/heads/$aosp_version
