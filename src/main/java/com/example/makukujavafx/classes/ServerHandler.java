package com.example.makukujavafx.classes;

import com.example.makukujavafx.MainApplication;
import com.example.makukujavafx.MainController;
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
import java.nio.file.Path;
import java.util.Enumeration;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.prefs.Preferences;
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;


public class ServerHandler {
    private DatagramSocket datagramSocket;
    private ScheduledExecutorService scheduledExecutorService;
    private ServerSocket serverSocket;
    private boolean isFirstLaunch;
    private final String FIRST_LAUNCH_KEY = "firstL12345";
    private ArrayNode jsonArray;
    private DeviceInfo deviceInfo;
    private ObjectMapper objectMapper;
    private String deviceId;
    private volatile boolean isServerRunning = true;
    private Scene scene;

    private JmDNS jmdns;
    private ServiceInfo serviceInfo;
    private MulticastSocket multicastSocket;

    private static final String SERVICE_TYPE = "_http._tcp";
    private static final int PORT = 10242;

    public ServerHandler(Scene scene) {
        this.scene = scene;
    }

    public void initialization() {
        objectMapper = new ObjectMapper();
        Preferences prefs = Preferences.userNodeForPackage(ServerHandler.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);

        if (isFirstLaunch) {
            System.out.println("First launch!");

            try {
                deviceInfo = createDeviceInfo();
                prefs.put("device_id", deviceInfo.getId());
                deviceId = prefs.get("device_id", null);
                jsonArray = JsonHandler.loadJsonFromFile();
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
        jmdns = JmDNS.create(InetAddress.getLocalHost());
        serverSocket = new ServerSocket(PORT);
        isServerRunning = true;
        ServiceInfo serviceInfo = ServiceInfo.create(SERVICE_TYPE, "MAKUKU", PORT, "");
        jmdns.registerService(serviceInfo);

        System.out.println(InetAddress.getLocalHost().getHostAddress());

        AnchorPane banner = (AnchorPane) scene.lookup("#banner");
        Label errorLabel = (Label) scene.lookup("#errorLabel");

        // Создаем MulticastSocket и присоединяемся к группе
//        MulticastSocket socket = new MulticastSocket(10242);
        InetAddress group = InetAddress.getByName("224.0.0.251");
//        socket.joinGroup(group);

        // Отправляем пакеты mDNS с информацией о сервисе каждые 3 секунды
        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
                if (isInternetConnectionAvailable()) {
                    deviceInfo.setIpAddress(InetAddress.getLocalHost().getHostAddress());
                    String jsonDeviceInfo = objectMapper.writeValueAsString(deviceInfo);
                    System.out.println(jsonDeviceInfo);
                    byte[] data = jsonDeviceInfo.getBytes();
                    DatagramPacket packet = new DatagramPacket(data, data.length, group, PORT);
//                    socket.send(packet);
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
            } catch (IOException e) {
                e.printStackTrace();
            }
        }, 0, 3, TimeUnit.SECONDS);

        // Отдельный поток для обработки входящих соединений
        new Thread(() -> {
            while (isServerRunning) {
                try {
                    Socket clientSocket = serverSocket.accept();
                    handleClient(clientSocket);
                    clientSocket.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }).start();
    }


/*    public void startServer() throws IOException {
        serverSocket = new ServerSocket(10242);
        isServerRunning = true;
        InetAddress broadcastAddress = InetAddress.getByName("255.255.255.255");
        datagramSocket = new DatagramSocket();
        datagramSocket.setBroadcast(true);
        System.out.println(InetAddress.getLocalHost().getHostAddress());
        System.out.println(broadcastAddress.getHostAddress());

        AnchorPane banner = (AnchorPane) scene.lookup("#banner");
        Label errorLabel = (Label) scene.lookup("#errorLabel");

        scheduledExecutorService = Executors.newSingleThreadScheduledExecutor();
        scheduledExecutorService.scheduleAtFixedRate(() -> {
            try {
                if (isInternetConnectionAvailable()) {
                    deviceInfo.setIpAddress(InetAddress.getLocalHost().getHostAddress());
                    String jsonDeviceInfo = objectMapper.writeValueAsString(deviceInfo);
                    System.out.println(jsonDeviceInfo);
                    byte[] data = jsonDeviceInfo.getBytes();
                    DatagramPacket packet = new DatagramPacket(data, data.length, broadcastAddress, 10242);
                    datagramSocket.send(packet);

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
            } catch (IOException e) {
                e.printStackTrace();
            }
        }, 0, 3, TimeUnit.SECONDS);

        while (isConnection) {
            Socket clientSocket = serverSocket.accept();
            handleClient(clientSocket);
            clientSocket.close();
        }
    }*/

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
