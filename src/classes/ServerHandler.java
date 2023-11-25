package classes;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import models.DeviceInfo;
import models.FileMessage;
import models.SocketMessage;

import javax.swing.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.concurrent.*;
import java.util.prefs.Preferences;
import java.net.Socket;

public class ServerHandler {
    private DatagramSocket datagramSocket;
    private ScheduledExecutorService scheduledExecutorService;
    private ServerSocket serverSocket;
    private boolean isFirstLaunch;
    private final String FIRST_LAUNCH_KEY = "firstLaunch";
    private ArrayNode jsonArray;
    private DeviceInfo deviceInfo;
    private ObjectMapper objectMapper;
    private String deviceId;
    private volatile boolean isServerRunning = true;

    public void initialization() {
        Preferences prefs = Preferences.userNodeForPackage(ServerHandler.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
        objectMapper = new ObjectMapper();

        if (isFirstLaunch) {
            System.out.println("First launch!");

            try {
                deviceInfo = createDeviceInfo();
                prefs.put("deviceId", deviceInfo.getId());
                deviceId = prefs.get("deviceId", null);
                JsonHandler.createInitialJsonFile();
                jsonArray = JsonHandler.loadJsonFromFile();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            System.out.println("DeviceInfo initialized: " + deviceInfo);
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }

            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
            isFirstLaunch = false;
        } else {
            deviceId = prefs.get("deviceId", null);
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            jsonArray = JsonHandler.loadJsonFromFile();
            System.out.println("JsonArray start - " + jsonArray);
        }
    }

    public void startServer() throws IOException {
        serverSocket = new ServerSocket(10242);
        isServerRunning = true;

        InetAddress broadcastAddress = InetAddress.getByName("255.255.255.255");
        datagramSocket = new DatagramSocket();
        datagramSocket.setBroadcast(true);

        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
                if (isInternetConnectionAvailable()) {
                    deviceInfo.setIpAddress(InetAddress.getLocalHost().getHostAddress());
                    String jsonDeviceInfo = objectMapper.writeValueAsString(deviceInfo);
                    byte[] data = jsonDeviceInfo.getBytes();
                    DatagramPacket packet = new DatagramPacket(data, data.length, broadcastAddress, 10242);
                    datagramSocket.send(packet);
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }, 0, 3, TimeUnit.SECONDS);

        while (isServerRunning) {
            Socket clientSocket = serverSocket.accept();
            handleClient(clientSocket);
            clientSocket.close();
        }
    }

    private void handleClient(Socket clientSocket) throws IOException {
        /*try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream());
             DataInputStream dis = new DataInputStream(clientSocket.getInputStream())) {

            String jsonInput = bufferedReader.readLine();
            System.out.println("JsonInput - " + jsonInput);
            if (jsonInput == null || jsonInput.isBlank()) return;

            SocketMessage socketMessage = objectMapper.readValue(jsonInput, SocketMessage.class);
            switch (socketMessage.getCall()) {
                case "pair_devices":
                    DeviceAction.pairDevices(socketMessage, dos, jsonArray, objectMapper, deviceId);
                    break;
                case "buffer":
                    DeviceAction.getBuffer(socketMessage, dos, objectMapper);
                    break;
                case "file":
                    FileMessage fileMessage = objectMapper.readValue(socketMessage.getData(), FileMessage.class);
                    DeviceAction.getFile(socketMessage, dos, objectMapper, *//*isr*//*dis, fileMessage);
                    break;
                case "pc_state":
                    DeviceAction.executeCommand(socketMessage);
                    break;
                default:
                    SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, "1", null);
                    String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                    dos.write(jsonResponse.getBytes());
                    break;
            }

        } catch (IOException e) {
            e.printStackTrace();
        }*/
        try (DataInputStream dis = new DataInputStream(clientSocket.getInputStream());
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {

            byte[] jsonBytes = new byte[4096];
            int bytesRead = dis.read(jsonBytes);
            if (bytesRead == -1) return;

            String jsonInput = new String(jsonBytes, 0, bytesRead);
            System.out.println("JsonInput - " + jsonInput);

            SocketMessage socketMessage = objectMapper.readValue(jsonInput, SocketMessage.class);
            String id = socketMessage.getDevice_id();
            if (socketMessage.getCall().equals("pair_devices") || JsonHandler.isIdInArray(id, jsonArray)) {
                switch (socketMessage.getCall()) {
                    case "pair_devices":
                        DeviceAction.pairDevices(socketMessage, dos, jsonArray, objectMapper, deviceId);
                        break;
                    case "buffer":
                        DeviceAction.getBuffer(socketMessage, dos, objectMapper);
                        break;
                    case "file":
                        FileMessage fileMessage = objectMapper.readValue(socketMessage.getData(), FileMessage.class);
                        DeviceAction.getFile(socketMessage, dos, objectMapper, dis, fileMessage);
                        break;
                    case "pc_state":
                        DeviceAction.executeCommand(socketMessage);
                        break;
                    default:
                        SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 102, null);
                        String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                        dos.write(jsonResponse.getBytes());
                        break;
                }
            } else {
                SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 101, null);
                String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                dos.write(jsonResponse.getBytes());
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void stopServer() throws IOException {
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

    private boolean isInternetConnectionAvailable() {
        try (Socket socket = new Socket("www.google.com", 80)) {
            return true;
        } catch (
                IOException e) {
            return false;
        }
    }

    private DeviceInfo createDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress());
    }

    private DeviceInfo getDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress(), deviceId);
    }
}