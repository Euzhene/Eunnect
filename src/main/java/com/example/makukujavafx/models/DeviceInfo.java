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
    private String deviceType;

    @JsonProperty("name")
    private String name;

    @JsonProperty("id")
    private String id;

    @JsonProperty("ip")
    private String ipAddress;

    public DeviceInfo() {
    }

    @JsonCreator
    public DeviceInfo(@JsonProperty("type") String deviceType,
                      @JsonProperty("name") String name,
                      @JsonProperty("ip") String ipAddress) {
        if (deviceType.contains("windows"))
            this.deviceType = "windows";
        else if (deviceType.contains("linux"))
            this.deviceType = "linux";
        this.name = name;
        this.ipAddress = ipAddress;
        this.id = UUID.randomUUID().toString();
    }

    @JsonCreator
    public DeviceInfo(@JsonProperty("type") String deviceType, @JsonProperty("name") String name,
                      @JsonProperty("ip") String ipAddress, @JsonProperty("id") String id) {
        if (deviceType.contains("windows"))
            this.deviceType = "windows";
        else if (deviceType.contains("linux"))
            this.deviceType = "linux";
        this.name = name;
        this.ipAddress = ipAddress;
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public String getDeviceType() {
        return deviceType;
    }

    public String getId() {
        return id;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    @Override
    public String toString() {
        return "DeviceInfo{" +
                "deviceType='" + deviceType + '\'' +
                ", name='" + name + '\'' +
                ", id='" + id + '\'' +
                ", ipAddress='" + ipAddress + '\'' +
                '}';
    }

    public DeviceInfo createDeviceInfo() throws UnknownHostException {
        String platform = System.getProperty("os.name").toLowerCase();
        String name = System.getProperty("user.name");
        return new DeviceInfo(platform, name, InetAddress.getLocalHost().getHostAddress());
    }

}
