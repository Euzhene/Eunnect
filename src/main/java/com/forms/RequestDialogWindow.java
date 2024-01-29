package com.forms;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class RequestDialogWindow extends JDialog {
    private JPanel contentPane;
    private JLabel requestDeviceLabel;
    private JButton allowButton;
    private JButton rejectButton;

    private boolean isPairAllowed = false;
    public boolean isPairAllowed() {
        return isPairAllowed;
    }

    public RequestDialogWindow(JFrame parent, String deviceInfo) {
        setContentPane(contentPane);
        setModal(true);

        requestDeviceLabel.setText(deviceInfo);

        setSize(270, 150);
        setLocationRelativeTo(parent);
        setResizable(false);

        allowButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                allowPair();
            }
        });
        rejectButton.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                rejectPair();
            }
        });
    }

    private void allowPair() {
        isPairAllowed = true;
        dispose();
    }

    private void rejectPair() {
        isPairAllowed = false;
        dispose();
    }
}
