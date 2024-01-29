package com.models;

import com.fasterxml.jackson.annotation.JsonProperty;

public class FileMessage {
    @JsonProperty("name")
    private String name;

    @JsonProperty("size")
    private int size;

    public String getName() {
        return name;
    }

    public int getSize() {
        return size;
    }

    @Override
    public String toString() {
        return "FileInfo{" +
                "name='" + name + '\'' +
                ", size=" + size +
                '}';
    }
}
