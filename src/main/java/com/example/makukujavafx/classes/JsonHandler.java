package com.example.makukujavafx.classes;

import com.example.makukujavafx.models.DeviceInfo;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;

import java.io.File;
import java.io.IOException;
import java.nio.file.*;
import java.util.*;

public class JsonHandler {

    private final String DEVICE_INFO_FILE = "MaKuKuDevices.json";

    private ObjectMapper objectMapper;

    public JsonHandler() {
        objectMapper = new ObjectMapper();
        objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
    }

    public void createJsonFile() {
        try {
            objectMapper.writeValue(new File(getDeviceFilepath().toString()), objectMapper.createArrayNode());
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при создании начального JSON файла", e);
        }
    }


    public void removeDeviceById(String id, ArrayNode jsonArray) {
        if (jsonArray != null) {
            Iterator<JsonNode> iterator = jsonArray.elements();
            while (iterator.hasNext()) {
                JsonNode element = iterator.next();
                if (element.has("id") && id.equals(element.get("id").asText())) {
                    iterator.remove();
                    break;
                }
            }
        }
    }

    public void saveDeviceToJsonFile(ArrayNode jsonArray) {
        try {
            if (!Files.exists(getDeviceFilepath())) {
                createJsonFile();
            }

            File file = new File(String.valueOf(getDeviceFilepath()));

            objectMapper.writeValue(file, jsonArray);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при сохранении объекта в JSON-файл", e);
        }
    }

    public ArrayNode getDevicesFromJsonFile() {
        try {
            if (!Files.exists(getDeviceFilepath())) {
                createJsonFile();
            }

            byte[] json = Files.readAllBytes(getDeviceFilepath());
            ArrayNode devices = (ArrayNode) objectMapper.readTree(json);
            return devices;
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при чтении JSON-файла", e);
        }
    }

    public DeviceInfo getDeviceFromJsonFile() {
        try {
            if (!Files.exists(getDeviceFilepath())) {
                createJsonFile();
            }

            byte[] json = Files.readAllBytes(getDeviceFilepath());
            ArrayNode devices = (ArrayNode) objectMapper.readTree(json);

            if (devices.size() == 0) {
                throw new RuntimeException("JSON-файл не содержит записей устройств");
            }

            JsonNode device = devices.get(0);
            return objectMapper.treeToValue(device, DeviceInfo.class);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Ошибка при обработке JSON-файла", e);
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при чтении JSON-файла", e);
        }
    }


    public boolean isIdInArray(String id, ArrayNode jsonArray) {
        if (jsonArray != null) {
            for (JsonNode element : jsonArray) {
                if (element.has("id") && id.equals(element.get("id").asText())) {
                    return true;
                }
            }
        }
        return false;
    }

    private String getHomeDir() {
        String homeDir = System.getProperty("user.home");
        Path filePath = Paths.get(homeDir, "Makuku");
        if (!Files.exists(filePath)) {
            try {
                Files.createDirectory(filePath);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        return filePath.toString();
    }

    private Path getDeviceFilepath() {
        return Path.of(getHomeDir(), DEVICE_INFO_FILE);
    }
}
