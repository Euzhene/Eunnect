package com.example.makukujavafx;

import com.example.makukujavafx.classes.DeviceAction;
import com.example.makukujavafx.classes.JsonHandler;
import com.example.makukujavafx.models.CardListener;
import com.example.makukujavafx.models.DeviceActionListener;
import com.example.makukujavafx.models.DeviceInfo;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import javafx.collections.ObservableList;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.geometry.Insets;
import javafx.scene.Node;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.control.ScrollPane;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.text.Text;

import java.io.IOException;
import java.net.URL;
import java.util.*;

public class MainController implements Initializable {

    @FXML
    private AnchorPane banner;

    @FXML
    private Label deviceNameLabel;

    @FXML
    private Label errorLabel;

    @FXML
    private Text filenameLabel;

    @FXML
    private GridPane grid;

    @FXML
    private ProgressBar progressBar;

    @FXML
    private ScrollPane scroll;

    List<DeviceInfo> devices = new ArrayList<>();

    private static int column = 0;
    private static int row = 1;
    private CardListener cardListener;
    private Map<ObjectNode, HBox> deviceElements = new HashMap<>();
    private ArrayNode arrayNode;

    public MainController() {
        DeviceAction.onDeviceAdded = value -> addDeviceToGrid(value);
    }

    @Override
    public void initialize(URL url, ResourceBundle resourceBundle) {
        grid.setPadding(new Insets(-15, 0, 0, 10));
        grid.setHgap(15);
        grid.setVgap(10);

        cardListener = new CardListener() {
            @Override
            public void onClinkBreakPairing(ObjectNode device) {
                removeDeviceFromGrid(device);
            }
        };

        arrayNode = JsonHandler.getDevicesFromJsonFile();
        int counter = 0;
        for (JsonNode node : arrayNode) {
            if (counter > 0) {
                addDeviceToGrid((ObjectNode) node);
            }
            counter++;
        }
    }

    public void addDeviceToGrid(ObjectNode device) {
        try {
            FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("/com/example/makukujavafx/device-card.fxml"));
            HBox deviceCard = fxmlLoader.load();

            CardController cardController = fxmlLoader.getController();
            cardController.setData(device, cardListener);

            if (column == 3) {
                column = 0;
                row++;
            }

            grid.add(deviceCard, column++, row);
            deviceElements.put(device, deviceCard);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void removeDeviceFromGrid(ObjectNode device) {
        HBox deviceCard = deviceElements.get(device);
        if (deviceCard != null) {
            JsonHandler.removeDeviceById(device.get("id").asText(), arrayNode);
            grid.getChildren().remove(deviceCard);
            deviceElements.remove(device);
        }
    }
}
