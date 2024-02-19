package com.example.makukujavafx.classes;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.node.ArrayNode;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.Iterator;

public class JsonHandler {

    private static final String DEVICE_INFO_FILE = "/com/example/makukujavafx/package.json";

    public static void saveJsonToFile(ArrayNode jsonArray) {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);

            URL resourceUrl = JsonHandler.class.getResource(DEVICE_INFO_FILE);
            if (resourceUrl == null) {
                throw new RuntimeException("Ресурс не найден: " + DEVICE_INFO_FILE);
            }

            File file = new File(resourceUrl.toURI());

            objectMapper.writeValue(file, jsonArray);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException | URISyntaxException e) {
            throw new RuntimeException("Ошибка при записи JSON в файл", e);
        }
    }

    /*    public static ArrayNode loadJsonFromFile() {
            try {
                ObjectMapper objectMapper = new ObjectMapper();

                InputStream inputStream = JsonHandler.class.getResourceAsStream(DEVICE_INFO_FILE);
                if (inputStream == null) {
                    return objectMapper.createArrayNode();
                }

                JsonNode rootNode = objectMapper.readTree(inputStream);

                if (rootNode instanceof ArrayNode) {
                    return (ArrayNode) rootNode;
                } else {
                    throw new RuntimeException("Корень JSON не является массивом");
                }
            } catch (IOException e) {
                throw new RuntimeException("Ошибка при чтении JSON из файла", e);
            }
        }*/
    public static ArrayNode loadJsonFromFile() {
        ObjectMapper objectMapper = new ObjectMapper();
        try (InputStream inputStream = JsonHandler.class.getResourceAsStream(DEVICE_INFO_FILE)) {
            if (inputStream == null) {
                return objectMapper.createArrayNode();
            }
            return objectMapper.readValue(inputStream, ArrayNode.class);
        } catch (IOException e) {
            throw new RuntimeException("Error reading json file", e);
        }
    }

    /*    public static void createInitialJsonFile() {
            try {
                ObjectMapper objectMapper = new ObjectMapper();
                objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
                objectMapper.writeValue(new File(DEVICE_INFO_FILE), objectMapper.createArrayNode());
            } catch (IOException e) {
                throw new RuntimeException("Ошибка при создании начального JSON файла", e);
            }
        }*/
    /*public static void createInitialJsonFile() {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);

            URL resourceUrl = JsonHandler.class.getResource(DEVICE_INFO_FILE);
            if (resourceUrl == null) {
                throw new RuntimeException("Ресурс не найден: " + DEVICE_INFO_FILE);
            }

            try (OutputStream resourceStream = Files.newOutputStream(Paths.get(resourceUrl.toURI()))) {
                objectMapper.writeValue(resourceStream, objectMapper.createArrayNode());
            }

            System.out.println("JSON успешно создан.");
        } catch (IOException | URISyntaxException e) {
            throw new RuntimeException("Ошибка при создании начального JSON файла", e);
        }
    }*/


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
