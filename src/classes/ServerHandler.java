package classes;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;

import javax.swing.*;
import java.awt.datatransfer.StringSelection;
import java.io.*;
import java.net.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.prefs.Preferences;
import java.net.Socket;

public class ServerHandler {
    private static final DatagramSocket[] datagramSocket = {null};
    private static ScheduledExecutorService scheduledExecutorService;
    private static ScheduledExecutorService scheduledConnectorService;
    private static final ServerSocket[] serverSocket = {null};
    //    private static final BufferedReader[] bufferedReader = {null};
    private static boolean isFirstLaunch;

    //    private final Thread[] serverThread = {null};
//    private static final Socket[] client = {null};
    private static final String FIRST_LAUNCH_KEY = "firstLaunch";
    private static JsonArray jsonArray;

    private static JLabel connectionState;
    private static DeviceInfo deviceInfo;
    private static String deviceId;
    private static boolean isPairAllowed = false;

    public static void initialization() {
        Preferences prefs = Preferences.userNodeForPackage(ServerHandler.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);

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
                try {
                    stopServer();
                } catch (IOException e) {
                    throw new RuntimeException(e);
                }
            } else {
                connectionState.setText("Есть подключение к интернету");
            }
        }, 0, 3, TimeUnit.SECONDS);


        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
//                    String jsonDeviceInfo = gson.toJson(deviceInfo);
//                    byte[] data = jsonDeviceInfo.getBytes();
                /*JsonObject jsonObject = new JsonObject();
                jsonObject.addProperty("device_type", "linux");
                jsonObject.addProperty("name", System.getProperty("user.name"));
                jsonObject.addProperty("id", deviceId);
                jsonObject.addProperty("ip_address", InetAddress.getLocalHost().getHostAddress());
                System.out.println(jsonObject);
                byte[] data = jsonObject.toString().getBytes();*/
                deviceInfo.setIp_address(InetAddress.getLocalHost().getHostAddress());
                String jsonDeviceInfo = gson.toJson(deviceInfo);
//                System.out.println(jsonDeviceInfo);
                byte[] data = jsonDeviceInfo.getBytes();
                DatagramPacket packet = new DatagramPacket(data, data.length, broadcastAddress, 10242);
                datagramSocket[0].send(packet);
//                System.out.println(packet);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }, 0, 3, TimeUnit.SECONDS);

        while (true) {
            /*Socket clientSocket = serverSocket[0].accept();

            bufferedReader[0] = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
            String jsonInput = bufferedReader[0].readLine();
            SocketMessage socketMessage = gson.fromJson(jsonInput, SocketMessage.class);
            System.out.println(jsonInput);
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
                    responseMessage = new SocketMessage("pair_devices", null, "rejectPairRequest", deviceId);
                    System.out.println("Отклонено сопряжение");
                }
                String jsonResponse = gson.toJson(responseMessage);
                System.out.println(jsonResponse);
                try (DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {
                    dos.write(jsonResponse.getBytes());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            } else if (socketMessage.getCall().equals("buffer")) {
                JsonObject dataObject = gson.fromJson(socketMessage.getData(), JsonObject.class);
                System.out.println("Buffer: " + dataObject.get("data").getAsString());

                StringSelection buf = new StringSelection("heht");

                responseMessage = new SocketMessage("buffer", null, null, deviceId);
                String jsonResponse = gson.toJson(responseMessage);

                try (DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {
                    dos.write(jsonResponse.getBytes());
                } catch (IOException e) {
                    e.printStackTrace();
                }
            } else if (socketMessage.getCall().equals("file")) {

            }*/
            Socket clientSocket = serverSocket[0].accept();
            try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
                 DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {

                String jsonInput = bufferedReader.readLine();
                SocketMessage socketMessage = gson.fromJson(jsonInput, SocketMessage.class);
//                System.out.println(jsonInput);
                System.out.println(socketMessage.getCall());
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
                        responseMessage = new SocketMessage("pair_devices", null, "rejectPairRequest", deviceId);
                        System.out.println("Отклонено сопряжение");
                    }
                    String jsonResponse = gson.toJson(responseMessage);
                    System.out.println(jsonResponse);
                    dos.write(jsonResponse.getBytes());
                    clientSocket.close();
                } else if (socketMessage.getCall().equals("buffer")) {
                    JsonObject dataObject = gson.fromJson(socketMessage.getData(), JsonObject.class);
                    System.out.println("Buffer: " + dataObject.get("data").getAsString());

                    StringSelection buf = new StringSelection("heht");

                    responseMessage = new SocketMessage("buffer", null, null, deviceId);
                    String jsonResponse = gson.toJson(responseMessage);

                    dos.write(jsonResponse.getBytes());
                    clientSocket.close();
                } else if (socketMessage.getCall().equals("file")) {

                }
            } catch (IOException e) {
                e.printStackTrace();
            }

        }

    }

    public static void stopServer() throws IOException {
        if (serverSocket[0] != null) {

            if (datagramSocket[0] != null && !datagramSocket[0].isClosed()) {
                datagramSocket[0].close();
            }

/*            // Закрываем клиентский сокет
            if (client[0] != null && !client[0].isClosed()) {
                System.out.println("Client is closed");
                client[0].close();
            }

            // Закрываем BufferedReader
            if (bufferedReader[0] != null) {
                System.out.println("Buffer is closed");
                bufferedReader[0].close();
            }*/

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
    }

    private static boolean isInternetConnectionAvailable() {
        try (Socket socket = new Socket("www.google.com", 80)) {
            return true;
        } catch (IOException e) {
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