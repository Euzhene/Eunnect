package com.example.makukujavafx.network;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class NetworkUtil {
    public static List<InetAddress> getWirelessAddresses() throws SocketException {
        List<InetAddress> wirelessAddresses = new ArrayList<>();
        List<NetworkInterface> networkInterfaces = Collections.list(NetworkInterface.getNetworkInterfaces());
        for (NetworkInterface networkInterface : networkInterfaces) {
            if (networkInterface.getDisplayName().contains("VirtualBox"))
                continue;
            List<InetAddress> addresses = Collections.list(networkInterface.getInetAddresses());
            for (InetAddress address : addresses) {
                if (address.getHostAddress().equals("127.0.0.1"))
                    continue;
                if (address.getHostAddress().contains(":"))
                    continue;
                wirelessAddresses.add(address);
            }
        }
        return wirelessAddresses;
    }

}
