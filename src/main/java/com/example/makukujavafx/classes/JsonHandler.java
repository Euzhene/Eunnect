package com.example.makukujavafx.classes;

import com.example.makukujavafx.models.DeviceInfo;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.nio.file.attribute.*;
import java.util.*;

public class JsonHandler {

    private static final String DEVICE_INFO_FILE = "MaKuKuDevices.json";

    public static void createJsonFile() {
        String homeDir = System.getProperty("user.home");
        Path filePath = Paths.get(homeDir, DEVICE_INFO_FILE);
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
            objectMapper.writeValue(new File(filePath.toString()), objectMapper.createArrayNode());
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при создании начального JSON файла", e);
        }
    }


    public static void removeDeviceById(String id, ArrayNode jsonArray) {
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

    public static void saveDeviceToJsonFile(ArrayNode jsonArray) {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
            String homeDir = System.getProperty("user.home");
            Path filePath = Paths.get(homeDir, DEVICE_INFO_FILE);
            if (!Files.exists(filePath)) {
                createJsonFile();
            }

            File file = new File(String.valueOf(filePath));

            objectMapper.writeValue(file, jsonArray);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при сохранении объекта в JSON-файл", e);
        }
    }

    public static ArrayNode loadDevicesFromJsonFile() {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            String homeDir = System.getProperty("user.home");
            Path filePath = Paths.get(homeDir, DEVICE_INFO_FILE);

            if (!Files.exists(filePath)) {
                createJsonFile();
            }

            byte[] json = Files.readAllBytes(filePath);
            ArrayNode devices = (ArrayNode) objectMapper.readTree(json);
            return devices;
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при чтении JSON-файла", e);
        }
    }


    public static boolean isIdInArray(String id, ArrayNode jsonArray) {
        if (jsonArray != null) {
            for (JsonNode element : jsonArray) {
                if (element.has("id") && id.equals(element.get("id").asText())) {
                    return true;
                }
            }
        }
        return false;
    }
}
