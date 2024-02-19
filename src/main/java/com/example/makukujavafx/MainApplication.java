package com.example.makukujavafx;

import com.example.makukujavafx.classes.ServerHandler;
import javafx.application.Application;
import javafx.application.Platform;
import javafx.event.EventHandler;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;

import javafx.stage.WindowEvent;
import org.controlsfx.control.Notifications;
import org.controlsfx.control.action.Action;
import javafx.application.Application;

public class MainApplication extends Application {
    private ServerHandler serverHandler;

    @Override
    public void start(Stage stage) throws Exception {
        FXMLLoader fxmlLoader = new FXMLLoader(MainApplication.class.getResource("main.fxml"));
        Scene scene = new Scene(fxmlLoader.load());
        scene.getStylesheets().add(MainApplication.class.getResource("styles.css").toString());
        stage.setResizable(false);
        stage.setScene(scene);
        stage.setOnCloseRequest(new EventHandler<WindowEvent>() {
            @Override
            public void handle(WindowEvent t) {
                Platform.exit();
                System.exit(0);
            }
        });
        stage.show();
        serverHandler = new ServerHandler(scene);
        serverHandler.initialization();

        startServerAsync();
    }

    public static void main(String[] args) {
        launch(args);
    }

    private void startServerAsync() {
        Thread thread = new Thread(() -> {
            try {
                serverHandler.startServer();
            } catch (IOException ex) {
                throw new RuntimeException(ex);
            }
        });
        thread.setDaemon(true);
        thread.start();
    }
}
