package classes;


import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import models.FileMessage;
import models.SocketMessage;
import com.fasterxml.jackson.databind.JsonNode;

import javax.swing.*;

import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.io.*;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;

public class DeviceAction {
    public static void pairDevices(SocketMessage socketMessage, DataOutputStream dos, ArrayNode jsonArray, ObjectMapper objectMapper, String deviceId) throws IOException {
        try {
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
                    responseMessage = new SocketMessage(socketMessage.getCall(), null, null, null);
                    jsonArray.add(data);
                    JsonHandler.saveJsonToFile(jsonArray);
                    System.out.println("JsonArray pair - " + jsonArray);
                } else {
                    responseMessage = new SocketMessage(socketMessage.getCall(), null, "4", null);
                }
            } else {
                responseMessage = new SocketMessage(socketMessage.getCall(), null, "2", null);
            }

            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
        } finally {
            if (dos != null) {
                dos.close();
            }
        }
    }

    public static void getBuffer(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper) throws IOException {
        try {
            String data = socketMessage.getData();

            StringSelection buf = new StringSelection(data);
            Clipboard clip = Toolkit.getDefaultToolkit().getSystemClipboard();
            clip.setContents(buf, null);

            SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, null, null);
            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
            new Notification("Буфер получен");
        } finally {
            if (dos != null) {
                dos.close();
            }
        }
    }

    public static void getFile(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper, /*InputStream inputStream*/DataInputStream dis, FileMessage fileMessage) throws IOException {
        try (FileOutputStream fos = new FileOutputStream(fileMessage.getName())) {
            int bytesRead;
            byte[] buffer = new byte[1024];
            long size = fileMessage.getSize();

            while (size > 0 && (bytesRead = dis.read(buffer, 0, (int) Math.min(buffer.length, size))) != -1) {
                fos.write(buffer, 0, bytesRead);
                size -= bytesRead;
            }

            System.out.println("File is Received");

            SocketMessage responseMessage = new SocketMessage(socketMessage.getCall(), null, null, null);
            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
        } catch (IOException e) {
            e.printStackTrace();
        } finally {
            dos.close(); // Закрывайте DataOutputStream после использования
        }
    }

    public static void executeCommand(SocketMessage socketMessage) throws IOException {
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
}
