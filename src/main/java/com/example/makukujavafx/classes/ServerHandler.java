package com.example.makukujavafx.classes;

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
import java.util.concurrent.ScheduledExecutorService;
import java.util.prefs.Preferences;
import javax.jmdns.JmDNS;
import javax.jmdns.ServiceInfo;


public class ServerHandler {
    private ScheduledExecutorService scheduledExecutorService;
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
    private final int PORT = 10242;
    private InetAddress address;
    private volatile boolean isRunning = true;


    public ServerHandler(Scene scene) throws SocketException {
        this.scene = scene;
        objectMapper = new ObjectMapper();
        prefs = Preferences.userNodeForPackage(ServerHandler.class);
        jsonHandler = new JsonHandler();
        jsonArray = jsonHandler.getDevicesFromJsonFile();
    }

    public void initialization() {
        boolean isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
        try {
            address = getWirelessAddresses().isEmpty() ? InetAddress.getLocalHost() : getWirelessAddresses().get(0);
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
            JsonNode firstDevice = jsonArray.get(0);
            ((ObjectNode) firstDevice).put("ip", address.getHostAddress());
            jsonHandler.saveDeviceToJsonFile(jsonArray);
            deviceInfo = new JsonHandler().getDeviceFromJsonFile();
        }
        System.out.println(jsonArray);
    }


    public void startServer() throws IOException {
        try {
            serverSocket = new ServerSocket(PORT, 0, address);

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
                    Socket clientSocket = serverSocket.accept();
                    handleClient(clientSocket);
                    clientSocket.close();
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
        }
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
                wirelessAddresses.add(address);
            }
        }
        return wirelessAddresses;
    }


    public void stopService() throws IOException {
        isRunning = false;
        if (jmdns != null) {
            jmdns.unregisterService(serviceInfo);
            jmdns.close();
        }
    }

}
