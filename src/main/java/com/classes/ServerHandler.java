package com.classes;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.forms.ServerApp2;
import com.models.DeviceInfo;
import com.models.FileMessage;
import com.models.SocketMessage;

import java.awt.*;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.prefs.Preferences;

public class ServerHandler {
    private DatagramSocket datagramSocket;
    private ScheduledExecutorService scheduledExecutorService;
    private ServerSocket serverSocket;
    private boolean isFirstLaunch;
    private final String FIRST_LAUNCH_KEY = "firstL1234";
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
                prefs.put("device_id", deviceInfo.getId());
                deviceId = prefs.get("device_id", null);
                JsonHandler.createInitialJsonFile();
                jsonArray = JsonHandler.loadJsonFromFile();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }

            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
            isFirstLaunch = false;
        } else {
            deviceId = prefs.get("device_id", null);
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
            jsonArray = JsonHandler.loadJsonFromFile();
        }
    }

    private boolean isConnection = true;

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

                    if (!isConnection) {
                        ServerApp2.serverApp.setTopPanel(new Color(0x1B5FB4));
                        ServerApp2.serverApp.setCurrentConnectedDeviceLabel("");
                        ServerApp2.serverApp.setFileStatusLabel("");
                        System.out.println("internet");
                    }

                    isConnection = true;
                } else {
                    isConnection = false;

                    ServerApp2.serverApp.setTopPanel(new Color(0xff0033));
                    ServerApp2.serverApp.setCurrentConnectedDeviceLabel("Нет подключения к интернету");
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
        try (DataInputStream dis = new DataInputStream(clientSocket.getInputStream());
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {

            byte[] jsonBytes = new byte[4096];
            int bytesRead = dis.read(jsonBytes);
            if (bytesRead == -1) return;

            String jsonInput = new String(jsonBytes, 0, bytesRead);
            System.out.println("JsonInput - " + jsonInput);

            SocketMessage socketMessage = objectMapper.readValue(jsonInput, SocketMessage.class);
            String id = socketMessage.getDevice_id();
            System.out.println("Array - " + jsonArray);
            if (socketMessage.getCall().equals("pair_devices") || JsonHandler.isIdInArray(id, jsonArray)) {
                switch (socketMessage.getCall()) {
                    case "pair_devices":
                        DeviceAction.pairDevices(socketMessage, dos, jsonArray, objectMapper, deviceId);
                        break;
                    case "buffer":
                        DeviceAction.getBuffer(socketMessage, dos, objectMapper, jsonArray);
                        break;
                    case "file":
                        FileMessage fileMessage = objectMapper.readValue(socketMessage.getData(), FileMessage.class);
                        DeviceAction.getFile(socketMessage, dos, objectMapper, dis, fileMessage, jsonArray);
                        break;
                    case "pc_state":
                        DeviceAction.executeCommand(socketMessage, dos, objectMapper);
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