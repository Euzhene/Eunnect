package classes;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.SerializationFeature;

import java.io.File;
import java.io.IOException;
import java.util.Iterator;

public class JsonHandler {

    private static final String DEVICE_INFO_FILE = "device_info.json";

    public static void saveJsonToFile(ArrayNode jsonArray) {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
            objectMapper.writeValue(new File(DEVICE_INFO_FILE), jsonArray);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при записи JSON в файл", e);
        }
    }

    public static ArrayNode loadJsonFromFile() {
        try {
            File file = new File(DEVICE_INFO_FILE);
            if (!file.exists()) {
                return null;
            }

            ObjectMapper objectMapper = new ObjectMapper();
            return (ArrayNode) objectMapper.readTree(file);
        } catch (IOException e) {
            throw new RuntimeException("Ошибка при чтении JSON из файла", e);
        }
    }

    public static void createInitialJsonFile() {
        try {
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.enable(SerializationFeature.INDENT_OUTPUT);
            objectMapper.writeValue(new File(DEVICE_INFO_FILE), objectMapper.createArrayNode());
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