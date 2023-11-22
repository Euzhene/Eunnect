import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;

import classes.ServerHandler;


public class ServerApp2 extends JFrame {
    private JButton togglePowerBtn;
    private JPanel panel1;
    private boolean isWorking = false;
    private ServerHandler serverHandler;


    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            ServerApp2 serverApp = new ServerApp2();
            serverApp.setContentPane(serverApp.panel1);
            serverApp.setDefaultCloseOperation(EXIT_ON_CLOSE);
            serverApp.setResizable(false);
            serverApp.pack();
            serverApp.setVisible(true);

//            serverApp.startServerAsync();
        });
    }

    public ServerApp2() {
        serverHandler = new ServerHandler();
        serverHandler.initialization();
        startServerAsync();
        togglePowerBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (!isWorking) {
                    startServerAsync();
                } else {
                    stopServerAsync();
                }
            }
        });
    }

    private void stopServerAsync() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
//                stopServer();
                try {
                    isWorking = false;
                    togglePowerBtn.setText("Turn On");

//                    stopServer();
                    serverHandler.stopServer();
                } catch (IOException ex) {
                }
                return null;
            }
        };
        worker.execute();
    }

    private void startServerAsync() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
//                startServer();
                try {
                    isWorking = true;
                    togglePowerBtn.setText("Turn Off");

                    serverHandler.startServer();
//                    startServer();
                } catch (IOException ex) {
                    throw new RuntimeException(ex);
                }
                return null;
            }
        };
        worker.execute();
    }
}
