package com.example.makukujavafx.classes;

import com.example.makukujavafx.helpers.FileUtils;
import com.example.makukujavafx.models.DeviceInfo;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;

import java.io.IOException;
import java.util.Iterator;

public class JsonHandler {

    private static ObjectMapper objectMapper = new ObjectMapper();

    static {
        objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
    }


    public static void removeDeviceById(String id, ArrayNode jsonArray) {
        if (jsonArray != null) {
            Iterator<JsonNode> iterator = jsonArray.elements();
            while (iterator.hasNext()) {
                JsonNode element = iterator.next();
                if (element.has("id") && id.equals(element.get("id").asText())) {
                    iterator.remove();
                    try {
                        objectMapper.writeValue(FileUtils.getDeviceFile(), jsonArray);
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                    break;
                }
            }
        }
    }

    public static void saveDeviceToJsonFile(ArrayNode jsonArray) {
        try {
            objectMapper.writeValue(FileUtils.getDeviceFile(), jsonArray);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при сохранении объекта в JSON-файл", e);
        }
    }

    public static ArrayNode getDevicesFromJsonFile() {
        try {
            byte[] json = FileUtils.getDevicesBytesFromJsonFile();

            ArrayNode devices = (ArrayNode) objectMapper.readTree(json);

            if (devices.isEmpty())
                throw new RuntimeException("JSON-файл не содержит записей устройств");


            return devices;
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при чтении JSON-файла", e);
        }
    }

    public static DeviceInfo getDeviceFromJsonFile() {
        try {
            ArrayNode devices = getDevicesFromJsonFile();
            JsonNode device = devices.get(0);
            return objectMapper.treeToValue(device, DeviceInfo.class);

        } catch (JsonProcessingException e) {
            throw new RuntimeException("Ошибка при обработке JSON-файла", e);
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
