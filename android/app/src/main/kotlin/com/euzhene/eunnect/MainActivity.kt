package com.euzhene.eunnect

import android.content.Context
import android.net.wifi.WifiManager
import android.net.wifi.WifiManager.MulticastLock
import android.net.wifi.WifiManager.WifiLock
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.InetSocketAddress


class MainActivity : FlutterActivity() {
    private lateinit var mLock: MulticastLock

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "multicast").setMethodCallHandler { call, result ->
            when (call.method) {
                "acquire" -> acquireMulticastLock()
                "release" -> releaseMulticastLock()
                else -> result.notImplemented()
            }
            result.success(null)
        }
    }

    private fun acquireMulticastLock() {
        val wifi = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        mLock = wifi.createMulticastLock("makuku-multicast-lock")
        mLock.acquire()
    }

    private fun releaseMulticastLock() {
        val wifi = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
        mLock = wifi.createMulticastLock("makuku-multicast-lock")
        if (mLock.isHeld) mLock.release()
    }

    override fun onDestroy() {
        super.onDestroy()
        mLock.release();
    }
}
