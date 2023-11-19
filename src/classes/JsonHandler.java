package classes;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.google.gson.stream.JsonWriter;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class JsonHandler {

    private static final String DEVICE_INFO_FILE = "device_info.json";

    public static void saveJsonToFile(JsonArray jsonArray) {
        try (JsonWriter jsonWriter = new JsonWriter(new FileWriter(DEVICE_INFO_FILE))) {
            Gson gson = new Gson();
            gson.toJson(jsonArray, jsonWriter);
            System.out.println("JSON успешно обновлен.");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static JsonArray loadJsonFromFile() {
        try (FileReader fileReader = new FileReader(DEVICE_INFO_FILE)) {
            return JsonParser.parseReader(fileReader).getAsJsonArray();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }
}
