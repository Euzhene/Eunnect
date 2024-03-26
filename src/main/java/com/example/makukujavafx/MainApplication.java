package com.example.makukujavafx;

import com.example.makukujavafx.classes.ServerHandler;
import com.example.makukujavafx.network.SslHelper;
import com.example.makukujavafx.ui.ClosingDialog;
import javafx.application.Application;
import javafx.fxml.FXMLLoader;
import javafx.scene.Scene;
import javafx.stage.Stage;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;

import javax.net.ssl.SSLServerSocket;
import javax.net.ssl.SSLSocket;

public class MainApplication extends Application {
    private ServerHandler serverHandler;

    @Override
    public void start(Stage stage) throws Exception {
        FXMLLoader fxmlLoader = new FXMLLoader(MainApplication.class.getResource("main.fxml"));
        Scene scene = new Scene(fxmlLoader.load());
//        scene.getStylesheets().add(MainApplication.class.getResource("styles.css").toString());
        stage.setResizable(false);
        stage.setScene(scene);

        stage.setOnCloseRequest(t -> new ClosingDialog().build(serverHandler));
        stage.show();


        serverHandler = new ServerHandler(scene);
        SslHelper.init();


        startServerAsync();

    }


    private void startServerAsync() {
        new Thread(() -> {
            try {
                serverHandler.startServer();
            } catch (IOException ex) {
                throw new RuntimeException(ex);
            }
        }).start();
    }



    public static void main(String[] args) {
        launch(args);
    }

}
