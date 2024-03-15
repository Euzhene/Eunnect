package com.example.makukujavafx.network;

import org.bouncycastle.jce.provider.BouncyCastleProvider;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.NoSuchAlgorithmException;

public class KeyGenerator {
    private final String FILE_FOR_KEYS = "keys.txt";
    private KeyPair key;

    public void createKey() {
        try {
            KeyPairGenerator keyPairGenerator = KeyPairGenerator.getInstance("RSA", new BouncyCastleProvider());
            keyPairGenerator.initialize(2048);
            key = keyPairGenerator.generateKeyPair();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    public KeyPair getKey() {
        return key;
    }

    private String getHomeDir() {
        String homeDir = System.getProperty("user.home");
        Path filePath = Paths.get(homeDir, "Makuku");
        if (!Files.exists(filePath)) {
            try {
                Files.createDirectory(filePath);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        return filePath.toString();
    }

    private Path getDeviceFilepath() {
        return Path.of(getHomeDir(), FILE_FOR_KEYS);
    }
}
