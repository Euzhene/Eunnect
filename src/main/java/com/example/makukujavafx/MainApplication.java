package com.example.makukujavafx;

import com.example.makukujavafx.classes.ServerHandler;
import com.example.makukujavafx.network.SslHelper;
import com.example.makukujavafx.ui.ClosingDialog;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;

import javax.net.ssl.SSLServerSocket;

public class MainApplication extends Application {
    private ServerHandler serverHandler;

    @Override
    public void start(Stage stage) throws Exception {
        FXMLLoader fxmlLoader = new FXMLLoader(MainApplication.class.getResource("main.fxml"));
        Scene scene = new Scene(fxmlLoader.load());
        scene.getStylesheets().add(MainApplication.class.getResource("styles.css").toString());
        stage.setResizable(false);
        stage.setScene(scene);

        stage.setOnCloseRequest(t -> new ClosingDialog().build(serverHandler));
        stage.show();


        serverHandler = new ServerHandler(scene);
        serverHandler.initialization();
        SslHelper.init();

        SSLServerSocket server= SslHelper.getSslServerSocket();

        startServerAsync();

    }

    public static void main(String[] args) {
        launch(args);
    }

    private void startServerAsync() {
        new Thread(() -> {
            try {
                serverHandler.startServer();
            } catch (IOException ex) {
                throw new RuntimeException(ex);
            }
        }).start();
//        thread.setDaemon(true);
    }
}
