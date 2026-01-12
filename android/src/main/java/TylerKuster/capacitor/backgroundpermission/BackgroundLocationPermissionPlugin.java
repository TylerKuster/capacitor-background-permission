package TylerKuster.capacitor.backgroundpermission;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * Please read the Capacitor Android Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/android
 */
@CapacitorPlugin(name = "BackgroundLocationPermission")
public class BackgroundLocationPermissionPlugin extends Plugin {

    @PluginMethod
    public void checkAndRequestPermission(PluginCall call) {
        // TODO: Implement Android logic
        call.reject("Not implemented yet");
    }
}

