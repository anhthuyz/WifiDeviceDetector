#!/usr/local/bin/node

var macList = []
var exec = require('child_process').exec;
var scanProcess = exec('tshark -l -Ini en0 -s 256 type mgt subtype probe-req');

scanProcess.stdout.on('data', function(data) {
    console.log(data); 
    if (data.includes('Probe Request')) {
        lastNumberOfDevice = macList.length; 
        let tempArray = data.split(/\s+/);
        let currentMacAddress = tempArray[3];
        if (!macList.includes(currentMacAddress)) {
            macList.push(currentMacAddress);
        }
        newNumberOfDevice = macList.length;
        if (newNumberOfDevice != lastNumberOfDevice) {
            console.log('Wifi client device in range: ' + newNumberOfDevice);
            // console.log(macList.toString());
        }
    }
});
