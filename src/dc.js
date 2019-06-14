#!/usr/local/bin/node

var macList = []
var exec = require('child_process').exec;
var scanProcess = exec('tshark -l -Ini mon0 -s 256 type mgt subtype probe-req');

scanProcess.stdout.on('data', function(data) {
    console.log(data); 
    if (data.includes('Probe Request')) {
        lastNumberOfDevice = macList.length; 
        let tempArray = data.split(/\s+/);
        let currentMacAddress = tempArray[3];
        if (!macList.indexOf(currentMacAddress) > -1) {
            macList.push(currentMacAddress);
        }
        newNumberOfDevice = macList.length;
        console.log('Current Wifi client device in range: ' + newNumberOfDevice);
    }
});
