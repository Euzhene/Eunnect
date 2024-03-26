package com.example.makukujavafx;

import com.example.makukujavafx.models.DeviceInfo;
import com.fasterxml.jackson.databind.node.ObjectNode;
import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.geometry.Insets;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.control.ScrollPane;
import javafx.scene.layout.AnchorPane;
import javafx.scene.layout.GridPane;
import javafx.scene.layout.HBox;
import javafx.scene.text.Text;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class MainController {

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

    public void addDevice(ObjectNode device) {
        int column = 0;
        int row = 1;
        try {
            FXMLLoader fxmlLoader = new FXMLLoader(getClass().getResource("com/example/makukujavafx/device-card.fxml"));
            HBox deviceCard = fxmlLoader.load();

            CardController cardController = fxmlLoader.getController();
            cardController.setData(device);

            if (column == 3) {
                column = 0;
                row++;
            }

            grid.add(deviceCard, column++, row); // Adjust the column and row index as needed

            GridPane.setMargin(deviceCard, new Insets(10)); // Add spacing around the card if needed
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
