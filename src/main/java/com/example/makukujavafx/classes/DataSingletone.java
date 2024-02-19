package com.example.makukujavafx.classes;

public class DataSingletone {
    private static final DataSingletone instance = new DataSingletone();
    private String data;

    private DataSingletone() {
    }

    public static DataSingletone getInstance() {
        return instance;
    }

    public String getData() {
        return data;
    }

    public void setData(String data) {
        this.data = data;
    }
}
