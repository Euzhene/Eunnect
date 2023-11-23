package classes;


import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import models.SocketMessage;
import com.fasterxml.jackson.databind.JsonNode;

import javax.swing.*;

import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.io.DataOutputStream;
import java.io.IOException;

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

    public static void buffer(SocketMessage socketMessage, DataOutputStream dos, ObjectMapper objectMapper) throws IOException {
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
}

