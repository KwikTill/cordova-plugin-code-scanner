
package com.kwiktill.codescanner;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaActivity;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import com.budiyev.android.codescanner.CodeScanner;
import com.budiyev.android.codescanner.CodeScannerView;
import com.budiyev.android.codescanner.DecodeCallback;
import com.budiyev.android.codescanner.ErrorCallback;
import com.budiyev.android.codescanner.ScanMode;
import com.budiyev.android.codescanner.AutoFocusMode
import android.widget.Toast;
import android.view.ViewGroup
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import android.media.ToneGenerator;
import android.media.AudioManager;




class KwikCodeScanner: CordovaPlugin() {

   private lateinit var callbackContext: CallbackContext
   private lateinit var prevCallbackContext: CallbackContext;
   private lateinit var scanner: CodeScanner
   private lateinit var scannerView: CodeScannerView
   private var scanning: Boolean = false;
   private var currentAction: String = "";


   override fun onResume(multitasking: Boolean) {

      if (scanning) {
         resumeScanner();
      }
   }

   override fun onPause(multitasking: Boolean) {
      if (scanning) {
         pauseScanner();
      }
   }


   fun startScanner() {

      val activity = cordova.getActivity();
      val context = activity.getApplicationContext();

      activity.runOnUiThread {

         try {

            val scannerView = CodeScannerView(context);
            val scanner = CodeScanner(activity, scannerView);
            scanner.autoFocusMode = AutoFocusMode.SAFE // or CONTINUOUS
            scanner.scanMode = ScanMode.CONTINUOUS

            scanner.decodeCallback = DecodeCallback {

               val code: String = it.text;
               
               if (code.equals(""))
                  return@DecodeCallback;

               this.callbackContext.success(code);

            }

            scanner.errorCallback = ErrorCallback { // or ErrorCallback.SUPPRESS
               val msg: String? = it.message;
               this.callbackContext.error(msg);
            }

            if (!checkPermissions()) {
               this.callbackContext.error("Permission denied. Accept the permission and try again");
               return@runOnUiThread;
            }

            var container: ViewGroup? = webView.getView().getParent() as ViewGroup
            container?.addView(scannerView);
            scannerView.bringToFront();
            
            scanner.startPreview();


            this.scanner = scanner;
            this.scannerView = scannerView;

            this.callbackContext.success("");
            this.scanning = true;

         } catch (e: Exception) {
            this.callbackContext.error(e.toString())
         }
      }
   }

   fun pauseScanner() {
      scanner.releaseResources();
   }

   fun resumeScanner() {
      scanner.startPreview();
   }

   fun stopScanner() {
      cordova.getActivity().runOnUiThread {
         var container: ViewGroup? = this.webView.getView().getParent() as ViewGroup?
         scanner.releaseResources();
         container?.removeView(scannerView);
         this.callbackContext.success("");
         this.scanning = false;
      }
   }

   override fun execute(action: String, args: JSONArray, callbackContext: CallbackContext): Boolean {

      if (this::callbackContext.isInitialized)
         prevCallbackContext = this.callbackContext;
      
      this.callbackContext = callbackContext;
      
      if (action.equals("start")) {
         startScanner();
      } else if (action.equals("scan")) {
         
      } else if (action.equals("stop")) {
         
         if (currentAction.equals("scan") && this::prevCallbackContext.isInitialized) {
            prevCallbackContext.error("Cancelled");
         }

         stopScanner();
      } else {
         currentAction = action;
         callbackContext.error("Unknown action: " + action);
         return false;
      }

      currentAction = action;
      return true;

   }

   fun checkPermissions(): Boolean {

      val activity = cordova.getActivity();

      if (ContextCompat.checkSelfPermission(activity, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
         ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.CAMERA), 200)
         return false
      } else {
         return true;
      }

   }
     
}