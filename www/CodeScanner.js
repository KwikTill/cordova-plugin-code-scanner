
'use strict'
const exec = require('cordova/exec');

// function to wrap callback functions to create an error object 
// from the error message before calling them
function errorCallbackGenerator(cb) {
  return (msg) => {
    cb(new Error(msg))
  }
}


function successCallbackGenerator(resolve, onSuccess) {
  return (result) => {
    onSuccess();
    resolve(result);
  }
}

// function to create promises for the native calls
function nativeCallPromiseGenerator(methodName, onSuccess=()=>{}, args=[]) {
  return new Promise((resolve, reject) => {
    exec(successCallbackGenerator(resolve, onSuccess), errorCallbackGenerator(reject), 'CodeScanner', methodName, args);
  });
}


function setScanning() {
  scanning = true;
}

function setNotScanning() {
  scanning = false;
}

let scanning = false;

const scan = () => nativeCallPromiseGenerator('scan');
const start = () => nativeCallPromiseGenerator('start', setScanning);
const stop = () => nativeCallPromiseGenerator('stop', setNotScanning);

// close the scanner when the back button is pressed;
document.addEventListener('backbutton', e => {

  console.log("back button pressed")
  
  if (!scanning) 
    return;

  e.preventDefault();
  stop();

});



module.exports = {
  scan,
  start,
  stop,
}
