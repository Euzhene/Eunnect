package classes;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import models.DeviceInfo;
import models.FileInfo;
import models.SocketMessage;

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
    private DatagramSocket datagramSocket;
    private ScheduledExecutorService scheduledExecutorService;
    private ServerSocket serverSocket;
    private boolean isFirstLaunch;

    //    private final Thread[] serverThread = {null};
//    private static final Socket[] client = {null};
    private final String FIRST_LAUNCH_KEY = "firstLaunch";
    private SocketMessage responseMessage;
    //    private JsonArray jsonArray;
//    private JsonNode jsonArray;
    private ArrayNode jsonArray;
    private JLabel connectionState;
    private DeviceInfo deviceInfo;
    private ObjectMapper objectMapper;
    private String deviceId;
    //    private Gson gson;
    private volatile boolean isServerRunning = true;

    public void initialization() {
        Preferences prefs = Preferences.userNodeForPackage(ServerHandler.class);
        isFirstLaunch = prefs.getBoolean(FIRST_LAUNCH_KEY, true);
//        gson = new Gson();
        objectMapper = new ObjectMapper();

        if (isFirstLaunch) {
            System.out.println("First launch!");

            try {
                deviceInfo = createDeviceInfo();
                prefs.put("deviceId", deviceInfo.getId());
                deviceId = prefs.get("deviceId", null);
                JsonHandler.createInitialJsonFile();
                jsonArray = JsonHandler.loadJsonFromFile();
/*                jsonArray = new JsonArray();
                JsonHandler.saveJsonToFile(jsonArray);*/
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
            jsonArray = JsonHandler.loadJsonFromFile();
//            jsonArray = JsonHandler.loadJsonFromFile();
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
                deviceInfo.setIpAddress(InetAddress.getLocalHost().getHostAddress());
//                String jsonDeviceInfo = gson.toJson(deviceInfo);
                String jsonDeviceInfo = objectMapper.writeValueAsString(deviceInfo);
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

    private void handleClient(Socket clientSocket) throws IOException {
        try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {

            String jsonInput = bufferedReader.readLine();
            System.out.println("JsonInput - " + jsonInput);
            if (jsonInput == null || jsonInput.isBlank()) return;

            SocketMessage socketMessage = objectMapper.readValue(jsonInput, SocketMessage.class);


            if (socketMessage.getCall().equals("pair_devices")) {
                JsonNode data = objectMapper.readTree(socketMessage.getData());
                System.out.println("data - " + data);

                JFrame frame = new JFrame();
                String deviceInfo = data.get("device_type").asText() + " " + data.get("name").asText();
                RequestDialog dialog = new RequestDialog(frame, deviceInfo);
                dialog.setVisible(true);

                SocketMessage responseMessage;

                if (dialog.isPairAllowed()) {
                    if (deviceId != null) {
                        JsonHandler.removeDeviceById(data.get("id").asText(), jsonArray);
                        responseMessage = new SocketMessage("pair_devices", null, null, null);
                        jsonArray.add(data);
                        JsonHandler.saveJsonToFile(jsonArray);
                        new Notification("Разрешено сопряжение");
                        System.out.println("JsonArray pair - " + jsonArray);
                    } else {
                        responseMessage = new SocketMessage("pair_devices", null, "4", null);
                        new Notification("Сопряжение отклонено");
                    }
                } else {
                    responseMessage = new SocketMessage("pair_devices", null, "2", null);
                    new Notification("Сопряжение отклонено");
                }

                String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                dos.write(jsonResponse.getBytes());
            } else if (socketMessage.getCall().equals("buffer")) {
                String dataObject = socketMessage.getData();

                StringSelection buf = new StringSelection(dataObject);
                Clipboard clip = Toolkit.getDefaultToolkit().getSystemClipboard();
                clip.setContents(buf, null);

                responseMessage = new SocketMessage("buffer", null, null, null);
                String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                dos.write(jsonResponse.getBytes());
                new Notification("Буфер получен");
            } else if (socketMessage.getCall().equals("file")) {
                System.out.println("JsonInput - " + jsonInput);
                FileInfo fileInfo = objectMapper.readValue(socketMessage.getData(), FileInfo.class);
                System.out.println("FileInfo - " + fileInfo);

                System.out.println("Принят файл: " + fileInfo.getName() + ", размер: " + fileInfo.getSize() + " байт");

                SocketMessage responseMessage = new SocketMessage("file", null, null, deviceId);
                String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                dos.write(jsonResponse.getBytes());

/*                Thread progressThread = new Thread(() -> reportProgress(clientSocket, fileInfo.getSize()));
                progressThread.start();*/

                byte[] fileBytes = new byte[fileInfo.getSize()];
                int bytesRead;
                while ((bytesRead = clientSocket.getInputStream().read(fileBytes)) != -1) {
                    System.out.println("Принято " + bytesRead + " байт файла");
                }

/*                try {
                    progressThread.join();
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }*/

                responseMessage = new SocketMessage("file", null, null, deviceId);
                jsonResponse = objectMapper.writeValueAsString(responseMessage);
                dos.write(jsonResponse.getBytes());
            } else if (socketMessage.getCall().equals("pc_state")) {
            }


        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    /*private static void reportProgress(Socket clientSocket, int fileSize) {
        try (DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {
            int progress = 0;
            while (progress < fileSize) {
//                String progressJson = gson.toJson(new ProgressMessage(progress, fileSize));
*//*                dos.write(progressJson.getBytes());
                dos.flush();*//*

            }
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }*/

    public void stopServer() throws IOException {
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