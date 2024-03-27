package com.example.makukujavafx.classes;

import com.example.makukujavafx.ImagePath;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionListener;

public class MyNotification {
    public static void createNotification() {
        if (!SystemTray.isSupported()) {
            System.out.println("System tray is not supported on this platform.");
            return;
        }
        Image image = Toolkit.getDefaultToolkit().getImage(MyNotification.class.getResource("" + ImagePath.LINUX.getPath()));

        TrayIcon trayIcon = new TrayIcon(image, "System Tray Notification", null);
        SystemTray tray = SystemTray.getSystemTray();

        try {
            tray.add(trayIcon);
        } catch (AWTException e) {
            throw new RuntimeException(e);
        }
        ActionListener okListener = e -> {
            System.out.println("OK button clicked.");
            tray.remove(trayIcon); // Удаляем уведомление из SystemTray
        };

        ActionListener cancelListener = e -> {
            System.out.println("Cancel button clicked.");
            tray.remove(trayIcon); // Удаляем уведомление из SystemTray
        };

        Object[] options = {"OK", "Cancel"};
        int result = JOptionPane.showOptionDialog(null, "This is a system notification with buttons.", "Notification",
                JOptionPane.DEFAULT_OPTION, JOptionPane.INFORMATION_MESSAGE, null, options, options[0]);

        if (result == 0) {
            okListener.actionPerformed(null);
        } else if (result == 1) {
            cancelListener.actionPerformed(null);
        }

        trayIcon.displayMessage("Notification", "This is a system notification with buttons.", TrayIcon.MessageType.INFO);
    }
}
