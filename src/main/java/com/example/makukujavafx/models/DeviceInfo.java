package com.example.makukujavafx.models;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.Serializable;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.UUID;

public class DeviceInfo implements Serializable {
    @JsonProperty("type")
    private String type;

    @JsonProperty("name")
    private String name;

    @JsonProperty("id")
    private String id;

    @JsonProperty("ip")
    private String ip;

    public DeviceInfo() {
    }

    //    @JsonCreator
    public DeviceInfo(@JsonProperty("type") String type,
                      @JsonProperty("name") String name,
                      @JsonProperty("ip") String ip) {
        if (type.contains("windows"))
            this.type = "windows";
        else if (type.contains("linux"))
            this.type = "linux";
        this.name = name;
        this.ip = ip;
        this.id = UUID.randomUUID().toString();
    }

    @JsonCreator
    public DeviceInfo(@JsonProperty("type") String type, @JsonProperty("name") String name,
                      @JsonProperty("ip") String ip, @JsonProperty("id") String id) {
        if (type.contains("windows"))
            this.type = "windows";
        else if (type.contains("linux"))
            this.type = "linux";
        this.name = name;
        this.ip = ip;
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public String getType() {
        return type;
    }

    public String getId() {
        return id;
    }

    public String getIp() {
        return ip;
    }

    public void setIpAddress(String ip) {
        this.ip = ip;
    }

    @Override
    public String toString() {
        return "DeviceInfo{" +
                "deviceType='" + type + '\'' +
                ", name='" + name + '\'' +
                ", id='" + id + '\'' +
                ", ipAddress='" + ip + '\'' +
                '}';
    }

    public DeviceInfo createDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress());
    }

}
