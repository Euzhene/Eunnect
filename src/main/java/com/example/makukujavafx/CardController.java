package com.example.makukujavafx;

import com.example.makukujavafx.models.CardListener;
import com.example.makukujavafx.models.DeviceActionListener;
import com.fasterxml.jackson.databind.node.ObjectNode;
import javafx.fxml.FXML;
import javafx.scene.control.Label;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.VBox;

import java.awt.event.MouseEvent;

public class CardController {

    @FXML
    private VBox colorField;

    @FXML
    private Label deviceName;

    @FXML
    private ImageView iconDevice;

    @FXML
    private ImageView pairIcon;

/*    @FXML
    public void breakPairing(MouseEvent event) {
    }*/

    private CardListener cardListener;
    private ObjectNode objectNode;

    private String[] colors = {"FF5056", "FE9D3B", "E74C3C", "87CEEB", "90EE90", "D8BFD8", "DA70D6", "DAA520", "FF8C00", "48D1CC",
            "40E0D0", "EE82EE", "CD5C5C", "FA8072", "00FF00", "00FA9A", "00FF7F", "2E8B57", "ADD8E6", "8B008B",
            "F5F5DC", "FFE4B5", "FFDEAD", "D2B48C", "FFA07A", "D3D3D3", "F0E68C", "F5DEB3", "FFE4C4", "F4A460"};

    public void setData(ObjectNode deviceCard, CardListener cardListener) {
        this.objectNode = deviceCard;
        this.cardListener = cardListener;
        deviceName.setText(deviceCard.get("name").asText());
        iconDevice.setImage(new Image(getClass().getResourceAsStream(deviceCard.get("imageSrc").asText())));
        pairIcon.setImage(new Image(getClass().getResourceAsStream("" + ImagePath.UNPAIRING.getPath())));
        colorField.setStyle("-fx-background-color: #" + colors[(int) (Math.random() * colors.length)] + ";" + " -fx-background-radius: 10 0 0 10;");
    }

    public void breakPairing(javafx.scene.input.MouseEvent mouseEvent) {
        cardListener.onClinkBreakPairing(objectNode);
    }

    public ObjectNode getDevice() {
        return objectNode;
    }
}
