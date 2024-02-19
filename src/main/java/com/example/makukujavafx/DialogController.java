package com.example.makukujavafx;

import com.example.makukujavafx.classes.DataSingletone;
import javafx.event.ActionEvent;
import javafx.fxml.FXML;
import javafx.fxml.Initializable;
import javafx.scene.control.Button;
import javafx.scene.control.Label;
import javafx.scene.input.MouseEvent;
import javafx.scene.layout.AnchorPane;

import java.net.URL;
import java.util.ResourceBundle;

public class DialogController /*implements Initializable*/ {

    @FXML
    private Button allowBtn;

    @FXML
    private Label deviceName;

    @FXML
    private AnchorPane pairingPane;

    @FXML
    private Button rejectBtn;

    @FXML
    void allowPairing(ActionEvent event) {
        System.out.println("Allow");
    }

    @FXML
    void rejectPairing(ActionEvent event) {
        System.out.println("Reject");
    }

//    DataSingletone data = DataSingletone.getInstance();

/*    @Override
    public void initialize(URL url, ResourceBundle resourceBundle) {
        deviceName.setText(data.getData());
    }*/

    public void initializeData(String data) {
        deviceName.setText(data);
    }

}
