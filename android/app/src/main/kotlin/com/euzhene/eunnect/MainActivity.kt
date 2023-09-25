package com.euzhene.eunnect

import android.content.Context
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import android.text.format.Formatter
import androidx.core.content.ContentProviderCompat.requireContext
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "a").setMethodCallHandler { call, result ->
            val wm = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
            if (call.method == "a") {
                val ip = Formatter.formatIpAddress(wm.getConnectionInfo().getIpAddress())
                result.success(ip)
            } else if (call.method == "b") {
                val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
                val activeNetwork = cm.activeNetworkInfo
                val connectionINfo = wm.connectionInfo
                val ipAddress = connectionINfo.ipAddress
            }
        }
    };
}
