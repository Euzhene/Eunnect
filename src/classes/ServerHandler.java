package classes;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import models.DeviceInfo;
import models.FileMessage;
import models.SocketMessage;

import javax.swing.*;
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
        try (BufferedReader bufferedReader = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));
             DataOutputStream dos = new DataOutputStream(clientSocket.getOutputStream())) {

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

                    // Создаем файл на сервере, куда будем записывать данные
                    File receivedFile = new File("путь_к_папке_на_сервере/" + fileMessage.getName());

                    try (FileOutputStream fos = new FileOutputStream(receivedFile);
                         InputStream is = clientSocket.getInputStream()) {

                        // Создаем буфер для чтения данных
                        byte[] buffer = new byte[1024];
                        int bytesRead;

                        // Читаем данные из InputStream и записываем в файл
                        while ((bytesRead = is.read(buffer)) != -1) {
                            fos.write(buffer, 0, bytesRead);
                        }
                    }

                    // Отправляем клиенту подтверждение
                    SocketMessage responseMessage = new SocketMessage("file", null, null, deviceId);
                    String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                    dos.write(jsonResponse.getBytes());
                    break;
                case "pc_state":
                    DeviceAction.executeCommand(socketMessage);
                    break;
                default:
/*                    SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, "1", null);
                    String jsonResponse = objectMapper.writeValueAsString(responseMessage);
                    dos.write(jsonResponse.getBytes());*/
                    break;
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
/*        try {
            URL url = new URL("http://www.google.com");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("HEAD");
            int responseCode = connection.getResponseCode();
            return responseCode == HttpURLConnection.HTTP_OK;
        } catch (IOException e) {
            return false;
        }*/
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