package com.classes;


import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.forms.RequestDialogWindow;
import com.forms.ServerApp2;
import com.models.FileMessage;
import com.models.SocketMessage;

import javax.swing.*;
import javax.swing.filechooser.FileSystemView;
import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.io.*;

public class DeviceAction {
    public static void pairDevices(SocketMessage socketMessage, DataOutputStream dos, ArrayNode jsonArray, ObjectMapper objectMapper, String deviceId) throws IOException {
        try {
            JsonNode data = objectMapper.readTree(socketMessage.getData());
            System.out.println("data - " + data);

            JFrame frame = new JFrame();
            String deviceInfo = data.get("device_type").asText() + " " + data.get("name").asText();
            RequestDialogWindow dialog = new RequestDialogWindow(frame, deviceInfo);
            dialog.setVisible(true);

            SocketMessage responseMessage;

            if (dialog.isPairAllowed()) {
                if (deviceId != null) {
                    JsonHandler.removeDeviceById(data.get("id").asText(), jsonArray);
                    responseMessage = new SocketMessage(socketMessage.getCall(), null, 200, null);
                    jsonArray.add(data);
                    JsonHandler.saveJsonToFile(jsonArray);

                    ServerApp2.serverApp.readJSON(jsonArray);

                    System.out.println("JsonArray pair - " + jsonArray);
                } else {
                    responseMessage = new SocketMessage(socketMessage.getCall(), null, 105, null);
                }
            } else {
                responseMessage = new SocketMessage(socketMessage.getCall(), null, 103, null);
            }

            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
        } finally {
            if (dos != null) {
                dos.close();
            }
        }
    }

    public static void getBuffer(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper, ArrayNode jsonArray) throws IOException {
        try {
            String data = socketMessage.getData();

            StringSelection buf = new StringSelection(data);
            Clipboard clip = Toolkit.getDefaultToolkit().getSystemClipboard();
            clip.setContents(buf, null);

            SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 200, null);
            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());

            String device_name = getCurrentConnectedDevice(socketMessage, jsonArray);
            new Notification("Получен буфер от устройства " + device_name);
        } finally {
            if (dos != null) {
                dos.close();
            }
        }
    }

    public static void getFile(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper, DataInputStream dis, FileMessage fileMessage, ArrayNode jsonArray) throws IOException {
        String downloadsFolder;
        FileSystemView fileSystemView = FileSystemView.getFileSystemView();
        File downloadDirectory = fileSystemView.getDefaultDirectory();

        if (downloadDirectory.exists() && downloadDirectory.isDirectory()) {
            downloadsFolder = downloadDirectory.getAbsolutePath();
        } else {
            throw new UnsupportedOperationException("Failed to determine the downloads directory.");
        }

        String filePath = downloadsFolder + File.separator + fileMessage.getName();

        try (FileOutputStream fos = new FileOutputStream(filePath)) {
            int bytesRead;
            byte[] buffer = new byte[2 * 1024];
            int totalBytesRead = 0;

            getCurrentConnectedDevice(socketMessage, jsonArray);

            String file_status;
            String file_name = fileMessage.getName();
            if (fileMessage.getName().length() > 30) {
                file_name = fileMessage.getName().substring(0, 30) + "...";
            }
            ServerApp2.serverApp.progressBar1.setVisible(true);
            ServerApp2.serverApp.setFileStatusLabel(file_name);
            while ((bytesRead = dis.read(buffer)) > 0) {
                fos.write(buffer, 0, bytesRead);
                totalBytesRead += bytesRead;

                int percentStatus = (int) (((double) totalBytesRead / fileMessage.getSize()) * 100);

                ServerApp2.serverApp.setProgressBar(percentStatus);
            }
            file_status = file_name + " полностью получен";
            ServerApp2.serverApp.setFileStatusLabel(file_status);

            System.out.println("File is Received");

            SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 200, null);
            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());

            String device_name = getCurrentConnectedDevice(socketMessage, jsonArray);
            new Notification("Получен файл от устройства " + device_name);

        } catch (IOException e) {
            SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 105, null);
            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
            e.printStackTrace();
        } finally {
            dos.close();
        }
    }

    public static void executeCommand(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper) throws IOException {
        String os = System.getProperty("os.name").toLowerCase();
        String command;

        switch (socketMessage.getData()) {
            case "restart":
                command = getRestartCommand(os);
                break;
            case "shut_down":
                command = getShutdownCommand(os);
                break;
            case "sleep":
                command = getSleepCommand(os);
                break;
            default:
                return;
        }

        SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, 200, null);
        String jsonResponse = objectMapper.writeValueAsString(responseMessage);
        dos.write(jsonResponse.getBytes());
        dos.close();
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        executeCommand(command);
    }

    private static String getRestartCommand(String os) {
        if (os.contains("win")) {
            return "shutdown /r /f /t 0";
        } else if (os.contains("nix") || os.contains("nux")) {
            return "sudo reboot";
        } else {
            throw new UnsupportedOperationException("Не поддерживаемая операционная система");
        }
    }

    private static String getShutdownCommand(String os) {
        if (os.contains("win")) {
            return "shutdown /s /f /t 0";
        } else if (os.contains("nix") || os.contains("nux")) {
            return "sudo shutdown -h now";
        } else {
            throw new UnsupportedOperationException("Не поддерживаемая операционная система");
        }
    }

    private static String getSleepCommand(String os) {
        if (os.contains("win")) {
            return "shutdown /h";
        } else if (os.contains("nix") || os.contains("nux")) {
            return "systemctl suspend";
        } else {
            throw new UnsupportedOperationException("Не поддерживаемая операционная система");
        }
    }

    private static void executeCommand(String command) throws IOException {
        try {
            Runtime.getRuntime().exec(command);
            System.exit(0);
        } catch (IOException e) {
            e.printStackTrace();
            throw e;
        }
    }

    private static String getCurrentConnectedDevice(SocketMessage socketMessage, ArrayNode jsonArray) {
        String device_id = socketMessage.getDevice_id();
        for (JsonNode jsonNode : jsonArray) {
            if (jsonNode.get("id").asText().equals(device_id)) {
                String device_name = jsonNode.get("name").asText();
                System.out.println(device_name);
                ServerApp2.serverApp.setCurrentConnectedDeviceLabel(device_name);

                return device_name;
            }
        }
        return null;
    }

}

