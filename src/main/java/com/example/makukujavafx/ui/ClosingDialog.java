package com.example.makukujavafx.ui;

import com.example.makukujavafx.classes.ServerHandler;
import javafx.application.Platform;
import javafx.concurrent.Task;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.control.ProgressIndicator;
import javafx.scene.layout.VBox;
import javafx.stage.Modality;
import javafx.stage.Stage;
import javafx.stage.StageStyle;

public class ClosingDialog {
    public void build(ServerHandler serverHandler) {
        // Create a new Stage for the loading dialog
        Stage loadingDialog = new Stage();
        loadingDialog.setResizable(false);
        loadingDialog.setAlwaysOnTop(true);
        loadingDialog.initStyle(StageStyle.UTILITY);
        loadingDialog.initModality(Modality.APPLICATION_MODAL); // This makes the dialog block events to other windows
        loadingDialog.setTitle("Завершение программы");


        // Put the ProgressIndicator and Label in a VBox
        VBox vbox = new VBox(10);
        vbox.getChildren().addAll(new ProgressIndicator());
        vbox.alignmentProperty().set(Pos.CENTER);

        // Create a Scene and set it to the Stage
        Scene scene = new Scene(vbox, 200, 100);
        loadingDialog.setScene(scene);

        // Show the loading dialog
        loadingDialog.show();

        // Create a Task to simulate the loading process
        Task<Void> task = new Task<Void>() {
            @Override
            protected Void call() throws Exception {
                serverHandler.stopService();
                return null;
            }
        };

        // When the task is done, close the loading dialog
        task.setOnSucceeded(e ->{
            Platform.exit();
            System.exit(0);
        });

        // Start the task in a background thread
        new Thread(task).start();
    }
}
