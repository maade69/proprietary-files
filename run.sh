#!/bin/bash
devices=(flame coral sunfish redfin bramble barbet oriole raven panther cheetah)

git clone https://github.com/GrapheneOS/script /home/runner/working/script
git clone https://github.com/GrapheneOS/vendor_state /home/runner/working/state
source /home/runner/working/script/common.sh

yarn install --cwd /home/runner/working/adevtool/
mkdir /home/runner/working/vendor
for device in ${devices[@]};do
    # Use frozen tag for 4th generation releases
    if [[ $device == flame ]] || [[ $device == coral ]];then
        cd /home/runner/working/script
        git checkout 13-coral
        source /home/runner/working/script/common.sh
    fi
    /home/runner/working/adevtool/bin/run download /home/runner/working/adevtool/dl/ -d $device -b $aosp_version -t factory ota
    sudo /home/runner/working/adevtool/bin/run generate-all /home/runner/working/adevtool/config/$device.yml -c /home/runner/working/state/$device.json -s /home/runner/working/adevtool/dl/$device-$aosp_version-*.zip --aapt2=/home/runner/working/bin/aapt2
    sudo chown -R runner:runner /home/runner/working/{google_devices,adevtool}
    /home/runner/working/adevtool/bin/run ota-firmware /home/runner/working/adevtool/config/$device.yml -f /home/runner/working/adevtool/dl/$device-ota-$aosp_version-*.zip
    /home/runner/working/adevtool/scripts/append-sha256.py /home/runner/working/vendor/google_devices/$device
    cp /home/runner/working/vendor/google_devices/$device/*.sha256 $GITHUB_WORKSPACE/$device.txt
done

git add *.txt
git commit -m "update to $aosp_version"
git push -fu origin HEAD:main
git push -u origin HEAD:refs/heads/$aosp_version
