package com.example.makukujavafx;

import javafx.fxml.FXML;
import javafx.fxml.FXMLLoader;
import javafx.fxml.Initializable;
import javafx.scene.Parent;
import javafx.scene.Scene;
import javafx.scene.control.Label;
import javafx.scene.control.ProgressBar;
import javafx.scene.layout.AnchorPane;
import javafx.scene.text.Text;
import javafx.stage.Stage;

import java.io.IOException;
import java.net.URL;
import java.util.ResourceBundle;

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
    private ProgressBar progressBar;

}
