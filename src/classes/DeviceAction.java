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
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.net.Socket;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;

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
                    new Notification("Разрешено сопряжение");
                    System.out.println("JsonArray pair - " + jsonArray);
                } else {
                    responseMessage = new SocketMessage(socketMessage.getCall(), null, "4", null);
                    new Notification("Сопряжение отклонено");
                }
            } else {
                responseMessage = new SocketMessage(socketMessage.getCall(), null, "2", null);
                new Notification("Сопряжение отклонено");
            }

            String jsonResponse = objectMapper.writeValueAsString(responseMessage);
            dos.write(jsonResponse.getBytes());
        } finally {
            if (dos != null) {
                System.out.println("dos closed");
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
                System.out.println("dos closed");
                dos.close();
            }
        }
    }

    public static void getFile(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper, Socket clientSocket, FileMessage fileMessage) {

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
            return "shutdown /r /t 0";
        } else if (os.contains("nix") || os.contains("nux")) {
            return "sudo reboot";
        } else {
            throw new UnsupportedOperationException("Не поддерживаемая операционная система");
        }
    }

    private static String getShutdownCommand(String os) {
        if (os.contains("win")) {
            return "shutdown /s /t 0";
        } else if (os.contains("nix") || os.contains("nux")) {
            return "sudo shutdown -h now";
        } else {
            throw new UnsupportedOperationException("Не поддерживаемая операционная система");
        }
    }

    private static String getSleepCommand(String os) {
        if (os.contains("win")) {
            return "shutdown.exe -s -t 0";
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

    private static FileMessage parseFileInfo(String initialMessage) {
        // Здесь реализуйте ваш код для извлечения информации о файле из начального сообщения
        // Пример: разбор JSON или другого формата
        return new FileMessage("example.txt", 1024); // Пример, замените на реальные значения
    }
}

