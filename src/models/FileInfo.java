package models;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class FileInfo {
    @JsonProperty("name")
    private String name;

    @JsonProperty("size")
    private int size;

    public FileInfo() {
    }

    @JsonCreator
    public FileInfo(@JsonProperty("name") String name,
                    @JsonProperty("size") int size) {
        this.name = name;
        this.size = size;
    }

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
