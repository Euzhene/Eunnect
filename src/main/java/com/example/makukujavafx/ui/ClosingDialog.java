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
        Stage loadingDialog = new Stage();
        loadingDialog.setResizable(false);
        loadingDialog.setAlwaysOnTop(true);
        loadingDialog.initStyle(StageStyle.UTILITY);
        loadingDialog.initModality(Modality.APPLICATION_MODAL); // This makes the dialog block events to other windows
        loadingDialog.setTitle("Завершение программы");

        VBox vbox = new VBox(10);
        vbox.getChildren().addAll(new ProgressIndicator());
        vbox.alignmentProperty().set(Pos.CENTER);

        // Create a Scene and set it to the Stage
        Scene scene = new Scene(vbox, 200, 100);
        loadingDialog.setScene(scene);

        loadingDialog.show();

        Task<Void> task = new Task<Void>() {
            @Override
            protected Void call() throws Exception {
                serverHandler.stopService();
                return null;
            }
        };

        task.setOnSucceeded(e -> {
            Platform.exit();
            System.exit(0);
        });

        new Thread(task).start();
    }
}
