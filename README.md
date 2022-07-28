# cordova-plugin-kwiktill-codescanner

Android and iOS QR and barcode scanner
## Usage

After the `deviceready` event, an object `codescanner` will be available globally. It has the following methods

* `start`: start the scanner.
* `scan`: wait for the scanner to pick a code on the camera, then return that code
* `stop`: stop the scanner

## Example
```javascript
document.addEventListener('deviceready', () => {
   await codescanner.start();
   const code = await codescanner.scan();
   console.log('Scanned code:', code);
   await codescanner.stop();
});
```