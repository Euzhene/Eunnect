package com.classes;

import java.awt.*;
import java.awt.image.BufferedImage;

public class Notification {
    public Notification(String message) {
        if (SystemTray.isSupported()) {
            SystemTray tray = SystemTray.getSystemTray();

            TrayIcon trayIcon = new TrayIcon(new BufferedImage(16, 16, BufferedImage.TYPE_INT_ARGB), "Tray Demo");
            trayIcon.setImageAutoSize(true);
            trayIcon.setToolTip("System tray icon demo");
            try {
                tray.add(trayIcon);
            } catch (AWTException e) {
                throw new RuntimeException(e);
            }

            trayIcon.displayMessage("MaKuKu Connect", message, TrayIcon.MessageType.INFO);
        } else {
            System.err.println("System tray not supported!");
        }
    }
}



