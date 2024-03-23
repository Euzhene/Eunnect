package com.example.makukujavafx.classes;

import com.example.makukujavafx.network.NetworkUtil;
import com.example.makukujavafx.network.SslHelper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.example.makukujavafx.models.*;
import com.fasterxml.jackson.databind.node.ObjectNode;
import javafx.scene.Scene;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.*;
import java.util.*;
import java.util.prefs.Preferences;
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;
import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;


public class ServerHandler {
    private ServerSocket serverSocket;
    private ArrayNode jsonArray;
    private DeviceInfo deviceInfo;
    private ObjectMapper objectMapper;
    private Scene scene;
    private JmDNS jmdns;
    private ServiceInfo serviceInfo;
    private final Preferences prefs;
    private final String FIRST_LAUNCH_KEY = "makuku";
    private JsonHandler jsonHandler;

    private final String SERVICE_TYPE = "_makuku._tcp.local.";
    public static final int PORT = 10242;
    private InetAddress address;
    private volatile boolean isRunning = true;
    private SSLSocket clientSocket;


    public ServerHandler(Scene scene) throws SocketException {
        this.scene = scene;
        objectMapper = new ObjectMapper();
        prefs = Preferences.userNodeForPackage(ServerHandler.class);
        jsonArray = objectMapper.createArrayNode();
        jsonHandler = new JsonHandler();
        boolean isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
        try {
            address = NetworkUtil.getWirelessAddresses().isEmpty() ? InetAddress.getLocalHost() : NetworkUtil.getWirelessAddresses().get(0);
        } catch (SocketException e) {
            throw new RuntimeException(e);
        } catch (UnknownHostException e) {
            throw new RuntimeException(e);
        }
        if (isFirstLaunch) {
            deviceInfo = new DeviceInfo(System.getProperty("os.name").toLowerCase(), System.getProperty("user.name"), address.getHostAddress());
            jsonArray.add(objectMapper.valueToTree(deviceInfo));
            jsonHandler.saveDeviceToJsonFile(jsonArray);
            prefs.putBoolean(FIRST_LAUNCH_KEY, false);
        } else {
            jsonArray = jsonHandler.getDevicesFromJsonFile();
            JsonNode firstDevice = jsonArray.get(0);
            ((ObjectNode) firstDevice).put("ip", address.getHostAddress());
            jsonHandler.saveDeviceToJsonFile(jsonArray);
            deviceInfo = new JsonHandler().getDeviceFromJsonFile();
        }
    }


    /*        public void startServer() throws IOException {
                try {
        //            serverSocket = new ServerSocket(PORT, 0, address);
                    serverSocket = SslHelper.getSslServerSocket(address);

                    jmdns = JmDNS.create(address);
                    Map<String, Object> txtMap = new HashMap<>();
                    txtMap.put("id", deviceInfo.getId());
                    txtMap.put("ip", deviceInfo.getIp());
                    txtMap.put("name", deviceInfo.getName());
                    txtMap.put("type", deviceInfo.getType());

                    serviceInfo = ServiceInfo.create(SERVICE_TYPE, deviceInfo.getId(), PORT, 0, 0, txtMap);
                    jmdns.registerService(serviceInfo);
                    while (isRunning) {
                        try {
                            clientSocket = (SSLSocket) serverSocket.accept();
        //                    Socket clientSocket = serverSocket.accept();
                            handleClient(clientSocket);
                        } catch (IOException e) {
                            if (!serverSocket.isClosed()) {
                                throw new RuntimeException(e);
                            }
                        }
                    }
                } finally {
                    if (serverSocket != null && !serverSocket.isClosed()) {
                        serverSocket.close();
                    }
                }
            }*/
    public void startServer() throws IOException {
        serverSocket = SslHelper.getSslServerSocket(address);

        jmdns = JmDNS.create(address);
        Map<String, Object> txtMap = new HashMap<>();
        txtMap.put("id", deviceInfo.getId());
        txtMap.put("ip", deviceInfo.getIp());
        txtMap.put("name", deviceInfo.getName());
        txtMap.put("type", deviceInfo.getType());

        serviceInfo = ServiceInfo.create(SERVICE_TYPE, deviceInfo.getId(), PORT, 0, 0, txtMap);
        jmdns.registerService(serviceInfo);
        while (isRunning) {
            try {
                clientSocket = (SSLSocket) serverSocket.accept();
                handleClient(clientSocket);
            } catch (IOException e) {
                if (!serverSocket.isClosed()) {
                    throw new RuntimeException(e);
                }
            }
        }
    }


    private void handleClient(SSLSocket clientSocket) throws IOException {
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
            if (socketMessage.getCall().equals("pair_devices") || jsonHandler.isIdInArray(id, jsonArray)) {
                switch (socketMessage.getCall()) {
                    case "pair_devices":
                        DeviceAction.pairDevices(/*scene, */socketMessage, dos, jsonArray, objectMapper, deviceInfo.getId());
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
        } finally {
            clientSocket.close();
        }
    }


    public void stopService() throws IOException {
        isRunning = false;
        if (jmdns != null) {
            jmdns.unregisterService(serviceInfo);
            jmdns.close();
        }
        if (clientSocket != null && !clientSocket.isClosed()) {
            clientSocket.close();
        }
        if (serverSocket != null && !serverSocket.isClosed()) {
            serverSocket.close();
        }
    }
}
