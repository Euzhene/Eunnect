package com.example.makukujavafx.helpers;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class FileUtils {
    private static final String HOME_DIRECTORY = "Makuku";
    private static final String DEVICE_INFO_FILE = "MaKuKuDevices.json";
    private static final String PRIVATE_KEY_FILE = "private.der";
    private static final String PUBLIC_KEY_FILE = "public.der";
    private static final String CERT_FILE = "cert.der";

    public static byte[] getCert() throws IOException {
        return read(getCertFilePath());
    }
    public static byte[] getPrivateKey() throws IOException {
        return read(getPrivateKeyFilePath());
    }
    public static byte[] getPublicKey() throws IOException {
        return read(getPublicKeyFilePath());
    }

    public static byte[] getDevicesBytesFromJsonFile() throws IOException {
        tryCreateFile(getDeviceFilePath());
        return Files.readAllBytes(getDeviceFilePath());
    }

    public static File getDeviceFile() throws IOException {
        tryCreateFile(getDeviceFilePath());
        return new File(getDeviceFilePath().toString());
    }

    public static void write(byte[] bytes, Path path) throws IOException {
        tryCreateFile(path);
        Files.write(path, bytes);
    }

    private static byte[] read(Path path) throws IOException {
        if (!Files.exists(path)) return null;
        return Files.readAllBytes(path);
    }

    private static Path getHomeDirPath() {
        String homeDir = System.getProperty("user.home");
        return Paths.get(homeDir, HOME_DIRECTORY);
    }

    private static Path getDeviceFilePath() {
        return getHomeDirPath().resolve(DEVICE_INFO_FILE);
    }
    public static Path getPrivateKeyFilePath() {
        return getHomeDirPath().resolve(PRIVATE_KEY_FILE);
    }
    public static Path getPublicKeyFilePath() {
        return getHomeDirPath().resolve(PUBLIC_KEY_FILE);
    }
    public static Path getCertFilePath() {
        return getHomeDirPath().resolve(CERT_FILE);
    }


    private static boolean tryCreateFile(Path path) throws IOException {
        if (Files.exists(path)) return false;

        File  file = path.toFile();
        File parentFile = file.getParentFile();

        Files.createDirectories(parentFile.toPath());
        Files.createFile(file.toPath());
        return true;
    }
}
