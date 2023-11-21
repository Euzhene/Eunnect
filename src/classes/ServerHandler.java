package classes;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import javax.swing.*;
import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.io.*;
import java.net.*;
import java.util.concurrent.*;
import java.util.prefs.Preferences;
import java.net.Socket;

public class ServerHandler {
    private static DatagramSocket datagramSocket;
    private static ScheduledExecutorService scheduledExecutorService;
    private static ExecutorService executorService;
    private static ServerSocket serverSocket;
    private static boolean isFirstLaunch;

    //    private final Thread[] serverThread = {null};
//    private static final Socket[] client = {null};
    private static final String FIRST_LAUNCH_KEY = "firstLaunch";
    private static JsonArray jsonArray;
    private static JLabel connectionState;
    private static DeviceInfo deviceInfo;
    private static String deviceId;
    private static final Object lock = new Object();
    private static Gson gson;
    private static volatile boolean isServerRunning = true;

    public static void initialization() {
        Preferences prefs = Preferences.userNodeForPackage(ServerHandler.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
        gson = new Gson();

        if (isFirstLaunch) {
            System.out.println("First launch!");

            try {
                deviceInfo = createDeviceInfo();
                prefs.put("deviceId", deviceInfo.getId());
                deviceId = prefs.get("deviceId", null);
                jsonArray = new JsonArray();
                JsonHandler.saveJsonToFile(jsonArray);
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            System.out.println("DeviceInfo initialized: " + deviceInfo);

            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
            isFirstLaunch = false;
        } else {
            deviceId = prefs.get("deviceId", null);
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            System.out.println("ID - " + deviceId);
            jsonArray = JsonHandler.loadJsonFromFile();
        }
    }

    public static void startServer() throws IOException {
        System.out.println("Server is running on " + InetAddress.getLocalHost().getHostAddress());
        serverSocket = new ServerSocket(10242);
        isServerRunning = true;

        InetAddress broadcastAddress = InetAddress.getByName("255.255.255.255");
        datagramSocket = new DatagramSocket();
        datagramSocket.setBroadcast(true);

        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();

        scheduledExecutorService.scheduleAtFixedRate(() -> {
/*        scheduledExecutorService.scheduleWithFixedDelay(() -> {
            if (!isInternetConnectionAvailable()) {
                System.out.println("Нет подключения к интернету");
                try {
                    stopServer();
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            } else {
                System.out.println("Есть подключение к интернету");
            }*/
            try {
                deviceInfo.setIp_address(InetAddress.getLocalHost().getHostAddress());
                String jsonDeviceInfo = gson.toJson(deviceInfo);
//                System.out.println(jsonDeviceInfo);
                byte[] data = jsonDeviceInfo.getBytes();
                DatagramPacket packet = new DatagramPacket(data, data.length, broadcastAddress, 10242);
//                datagramSocket[0].send(packet);
                datagramSocket.send(packet);
//                System.out.println(packet);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }, 0, 3, TimeUnit.SECONDS);

        while (isServerRunning) {
            Socket clientSocket = serverSocket.accept();
            handleClient(clientSocket);
            clientSocket.close();
        }

    }

    private static void handleClient(Socket clientSocket) throws IOException {
        try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {
            String jsonInput = bufferedReader.readLine();
            if (jsonInput == null || jsonInput.isBlank()) return ;

            SocketMessage socketMessage = gson.fromJson(jsonInput, SocketMessage.class);
//                System.out.println(jsonInput);
//            System.out.println(socketMessage.getCall());
            SocketMessage responseMessage;
            if (socketMessage.getCall().equals("pair_devices")) {
                JsonObject dataObject = gson.fromJson(socketMessage.getData(), JsonObject.class);
                System.out.println(socketMessage.getData());

                JFrame frame = new JFrame();
                String deviceInfo = dataObject.get("device_type").getAsString() + " " + dataObject.get("name").getAsString();
                RequestDialog dialog = new RequestDialog(frame, deviceInfo);
                dialog.setVisible(true);
                if (dialog.isPairAllowed()) {
                    System.out.println("Разрешено сопряжение");
                    if (deviceId != null)
                        responseMessage = new SocketMessage("pair_devices", null, null, deviceId);
                    else
                        responseMessage = new SocketMessage("pair_devices", null, "device_id is null", null);
                } else {
                    responseMessage = new SocketMessage("pair_devices", null, "Отклонено сопряжение", deviceId);
                    System.out.println("Отклонено сопряжение");
                }
                String jsonResponse = gson.toJson(responseMessage);
                System.out.println(jsonResponse);
                dos.write(jsonResponse.getBytes());
            } else if (socketMessage.getCall().equals("buffer")) {
                //   JsonObject dataObject = gson.fromJson(socketMessage.getData(), JsonObject.class);
                String dataObject = socketMessage.getData();
                System.out.println("Buffer: " + dataObject);

                StringSelection buf = new StringSelection(dataObject);
                Clipboard clip = Toolkit.getDefaultToolkit().getSystemClipboard();
                clip.setContents(buf, null);
                responseMessage = new SocketMessage("buffer", null, null, deviceId);
                String jsonResponse = gson.toJson(responseMessage);

                dos.write(jsonResponse.getBytes());
            } else if (socketMessage.getCall().equals("file")) {
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static void stopServer() throws IOException {
        /*if (serverSocket != null) {
            if (datagramSocket != null && !datagramSocket.isClosed()) {
                datagramSocket.close();
            }
            System.out.println("scheduledExecutorService closed");
            executorService.shutdownNow();
            scheduledExecutorService.shutdownNow();
            serverSocket.close();
            if (serverSocket.isClosed()) {
                System.out.println("Server is closed");
            }
        }*/
        isServerRunning = false;

        if (serverSocket != null && !serverSocket.isClosed()) {
            System.out.println("server is closed");
            serverSocket.close();
        }

        if (datagramSocket != null && !datagramSocket.isClosed()) {
            System.out.println("datagramSocket is closed");
            datagramSocket.close();
        }

        if (scheduledExecutorService != null) {
            System.out.println("scheduledExecutorService is closed");
            scheduledExecutorService.shutdownNow();
        }
    }

    private static boolean isInternetConnectionAvailable() {
        try (Socket socket = new Socket("www.google.com", 80)) {
            return true;
        } catch (
                IOException e) {
            return false;
        }

    }

    private static DeviceInfo createDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress());
    }

    private static DeviceInfo getDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress(), deviceId);
    }
}