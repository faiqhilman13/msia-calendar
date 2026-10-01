package my.sehariselembar.app;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

/**
 * Receives the widget snapshot (next 21 days: dates, peribahasa, events, style)
 * from the web app and refreshes every placed Sehari Selembar widget.
 */
@CapacitorPlugin(name = "WidgetBridge")
public class WidgetBridgePlugin extends Plugin {
    @PluginMethod
    public void setData(PluginCall call) {
        String json = call.getString("json");
        if (json == null) {
            call.reject("Missing json");
            return;
        }
        WidgetData.save(getContext(), json);
        TearOffWidget.refreshAll(getContext());
        call.resolve(new JSObject());
    }
}
