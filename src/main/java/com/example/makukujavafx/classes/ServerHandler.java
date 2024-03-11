package com.example.makukujavafx.classes;

import com.example.makukujavafx.MainApplication;
import com.example.makukujavafx.MainController;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.example.makukujavafx.models.*;
import javafx.application.Platform;
import javafx.fxml.FXMLLoader;
import javafx.scene.Node;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.layout.AnchorPane;
import javafx.scene.paint.Color;
import javafx.stage.Stage;
import org.w3c.dom.ls.LSOutput;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.prefs.Preferences;
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;


public class ServerHandler {
    private ScheduledExecutorService scheduledExecutorService;
    private ServerSocket serverSocket;
    private ArrayNode jsonArray;
    private DeviceInfo deviceInfo;
    private ObjectMapper objectMapper;
    private String deviceId;
    private Scene scene;
    private JmDNS jmdns;
    private ServiceInfo serviceInfo;
    private final Preferences prefs;
    private final String FIRST_LAUNCH_KEY = "makuku";

    private final String SERVICE_TYPE = "_makuku._tcp.local.";
    private final int PORT = 10242;
    private InetAddress address;
    private Thread clientThread;

    public ServerHandler(Scene scene) throws SocketException {
        this.scene = scene;
        objectMapper = new ObjectMapper();
        prefs = Preferences.userNodeForPackage(ServerHandler.class);
        jsonArray = JsonHandler.loadDevicesFromJsonFile();
    }

    public void initialization() {
        boolean isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
        if (!isFirstLaunch) {
            System.out.println("First launch!");
            try {
                address = getWirelessAddresses().isEmpty() ? InetAddress.getLocalHost() : getWirelessAddresses().get(0);
                deviceInfo = new DeviceInfo(System.getProperty("os.name").toLowerCase(), System.getProperty("user.name"), address.getHostAddress());
                System.out.println("ID - " + deviceId);
                jsonArray.add(objectMapper.valueToTree(deviceInfo));
                JsonHandler.saveDeviceToJsonFile(jsonArray);
            } catch (UnknownHostException | SocketException e) {
                throw new RuntimeException(e);
            }
            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
        } else {
            try {
                deviceInfo = getDeviceInfo();
            } catch (UnknownHostException e) {
                throw new RuntimeException(e);
            }
        }
        jsonArray = JsonHandler.loadDevicesFromJsonFile();
        System.out.println(jsonArray);
        deviceId = deviceInfo.getId();

    }

    private boolean isConnection = true;

    public void startServer() throws IOException {
        serverSocket = new ServerSocket(PORT, 0, address);
        deviceInfo.setIpAddress(String.valueOf(address));
        jmdns = JmDNS.create(address);
        Map<String, Object> txtMap = new HashMap<>();
        txtMap.put("id", deviceId);
        txtMap.put("ip", deviceInfo.getIpAddress());
        txtMap.put("name", deviceInfo.getName());
        txtMap.put("type", deviceInfo.getDeviceType());

        serviceInfo = ServiceInfo.create(SERVICE_TYPE, deviceInfo.getId(), PORT, 0, 0, txtMap);
        jmdns.registerService(serviceInfo);

        AnchorPane banner = (AnchorPane) scene.lookup("#banner");
        Label errorLabel = (Label) scene.lookup("#errorLabel");
        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            if (isInternetConnectionAvailable()) {
                try {
                    address = getWirelessAddresses().isEmpty() ? InetAddress.getLocalHost() : getWirelessAddresses().get(0);
                } catch (SocketException e) {
                    throw new RuntimeException(e);
                } catch (UnknownHostException e) {
                    throw new RuntimeException(e);
                }
                if (!isConnection) {
                    Platform.runLater(() -> {
                        banner.setStyle("-fx-background-color: green;-fx-background-radius: 10;");
                        errorLabel.setVisible(false);
                    });
                }

                isConnection = true;
            } else {
                isConnection = false;
                Platform.runLater(() -> {
                    banner.setStyle("-fx-background-color: red;-fx-background-radius: 10;");
                    errorLabel.setVisible(true);
                    errorLabel.setText("No internet connection!");
                });
            }
        }, 0, 3, TimeUnit.SECONDS);

        clientThread = new Thread(() -> {
            while (!Thread.currentThread().isInterrupted() && !serverSocket.isClosed()) {
                try {
                    Socket clientSocket = serverSocket.accept();
                    handleClient(clientSocket);
                    clientSocket.close();
                } catch (IOException e) {
                    if (!serverSocket.isClosed()) {
                        throw new RuntimeException(e);
                    }
                }
            }
        });

        clientThread.start();
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
                        DeviceAction.pairDevices(/*scene, */socketMessage, dos, jsonArray, objectMapper, deviceId);
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
        } catch (IOException e) {
            return false;
        }
    }

    private DeviceInfo getDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress(), deviceId);
    }

    private List<InetAddress> getWirelessAddresses() throws SocketException {
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
                System.out.println("Add: " + address);
                wirelessAddresses.add(address);
            }
        }
        return wirelessAddresses;
    }


    public void stopService() throws IOException {
        isConnection = false;
        clientThread.interrupt();
        if (serverSocket != null && !serverSocket.isClosed()) {
            serverSocket.close();
        }
        if (jmdns != null) {
            jmdns.unregisterAllServices();
            jmdns.close();
        }
        if (scheduledExecutorService != null) {
            scheduledExecutorService.shutdownNow();
        }
    }

}
