package com.example.makukujavafx.helpers;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileUtils {
    private static final String HOME_DIRECTORY = "Makuku";
    private static final String DEVICE_INFO_FILE = "MaKuKuDevices.json";

    public static byte[] getDevicesBytesFromJsonFile() throws IOException {
        tryCreateDeviceFile();
        return Files.readAllBytes(getDeviceFilePath());
    }

    public static File getDeviceFile() throws IOException {
        tryCreateDeviceFile();
        return new File(getDeviceFilePath().toString());
    }


    private static Path getHomeDirPath() {
        String homeDir = System.getProperty("user.home");
        return Paths.get(homeDir, HOME_DIRECTORY);
    }

    private static Path getDeviceFilePath() {
        return getHomeDirPath().resolve(DEVICE_INFO_FILE);
    }


    private static boolean tryCreateDeviceFile() throws IOException {
        Path deviceFile = getDeviceFilePath();
        if (Files.exists(deviceFile)) return false;

        Files.createDirectories(deviceFile);
        return true;
    }
}
