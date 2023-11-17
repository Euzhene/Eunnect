import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.net.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.prefs.Preferences;

import com.google.gson.Gson;
import classes.DeviceInfo;

public class ServerApp2 extends JFrame {
    private JButton togglePowerBtn;
    private JPanel panel1;
    private JLabel connectionState;
    private boolean isWorking = false;
    private boolean isServerRunning = false;
    //    private final MulticastSocket[] multicastSocket = {null};
    private final DatagramSocket[] datagramSocket = {null};
    private ScheduledExecutorService scheduledExecutorService;
    private ScheduledExecutorService scheduledConnectorService;
    private final ServerSocket[] serverSocket = {null};
    private final Thread[] serverThread = {null};
    private final Socket[] client = {null};
    private final BufferedReader[] bufferedReader = {null};
    private static final String FIRST_LAUNCH_KEY = "firstLaunch";
    private boolean isFirstLaunch;
    private static DeviceInfo deviceInfo;
    private static final String DEVICE_INFO_FILE = "device_info.json";

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            ServerApp2 serverApp = new ServerApp2();
            serverApp.setContentPane(serverApp.panel1);
            serverApp.setDefaultCloseOperation(EXIT_ON_CLOSE);
            serverApp.setResizable(false);
            serverApp.pack();
            serverApp.setVisible(true);
        });
    }

    public ServerApp2() {
        Preferences prefs = Preferences.userNodeForPackage(ServerApp2.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);

        if (isFirstLaunch) {
            System.out.println("First launch!");

            try {
                deviceInfo = createDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            System.out.println("DeviceInfo initialized: " + deviceInfo);

            saveDeviceInfoToFile(deviceInfo);

            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
            isFirstLaunch = false;
        } else {
            DeviceInfo loadedDeviceInfo = loadDeviceInfoFromFile();
            if (loadedDeviceInfo != null) {
                deviceInfo = loadedDeviceInfo;
                System.out.println("DeviceInfo loaded from file: " + deviceInfo);
            } else {
            }
        }

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

    private void saveDeviceInfoToFile(DeviceInfo info) {
        try (Writer writer = new FileWriter(DEVICE_INFO_FILE)) {
            Gson gson = new Gson();
            gson.toJson(info, writer);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private DeviceInfo loadDeviceInfoFromFile() {
        try (Reader reader = new FileReader(DEVICE_INFO_FILE)) {
            Gson gson = new Gson();
            return gson.fromJson(reader, DeviceInfo.class);
        } catch (IOException e) {
            return null;
        }
    }

    private void stopServerAsync() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
                stopServer();
                return null;
            }
        };
        worker.execute();
    }

    private void startServerAsync() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
                startServer();
                return null;
            }
        };
        worker.execute();
    }

    private void startServer() {
        try {
            togglePowerBtn.setText("Turn Off");
            isWorking = true;
            isServerRunning = true;

            System.out.println("Server is running on " + InetAddress.getLocalHost().getHostAddress());
            serverSocket[0] = new ServerSocket(10242);

            InetAddress broadcastAddress = InetAddress.getByName("255.255.255.255");
            datagramSocket[0] = new DatagramSocket();
            datagramSocket[0].setBroadcast(true);

            Gson gson = new Gson();
            scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
            scheduledConnectorService = Executors.newSingleThreadScheduledExecutor();

            scheduledConnectorService.scheduleAtFixedRate(() -> {
                if (!isInternetConnectionAvailable()) {
                    connectionState.setText("Нет подключения к интернету");
                    stopServer();
                }else {
                    connectionState.setText("Подключение установлено");
                }
            }, 0, 3, TimeUnit.SECONDS);


            scheduledExecutorService.scheduleAtFixedRate(() -> {
                try {
                    String jsonDeviceInfo = gson.toJson(deviceInfo);

                    byte[] data = jsonDeviceInfo.getBytes();
                    DatagramPacket packet = new DatagramPacket(data, data.length, broadcastAddress, 10242);
                    datagramSocket[0].send(packet);
                    System.out.println(packet);
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            }, 0, 3, TimeUnit.SECONDS);

        } catch (IOException ex) {
            throw new RuntimeException(ex);
        }
    }


    private void stopServer() {
        try {
            if (serverSocket[0] != null) {
                isWorking = false;
                togglePowerBtn.setText("Turn On");
                isServerRunning = false;

                if (datagramSocket[0] != null && !datagramSocket[0].isClosed()) {
                    datagramSocket[0].close();
                }

                // Закрываем клиентский сокет
                if (client[0] != null && !client[0].isClosed()) {
                    System.out.println("Client is closed");
                    client[0].close();
                }

                // Закрываем BufferedReader
                if (bufferedReader[0] != null) {
                    System.out.println("Buffer is closed");
                    bufferedReader[0].close();
                }

                System.out.println("scheduledExecutorService closed");
                scheduledExecutorService.shutdownNow();
                System.out.println("scheduledConnectorService closed");
                scheduledConnectorService.shutdownNow();

                // Закрываем серверный сокет
                serverSocket[0].close();

                if (serverSocket[0].isClosed()) {
                    System.out.println("Server is closed");
                }
            }
        } catch (IOException ex) {
        }
    }

    private boolean isInternetConnectionAvailable() {
        try (Socket socket = new Socket("www.google.com", 80)) {
            return true;
        } catch (IOException e) {
            return false;
        }
    }


    private DeviceInfo createDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress());
    }
}
