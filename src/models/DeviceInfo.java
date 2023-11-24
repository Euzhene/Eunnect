package models;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.io.Serializable;
import java.util.UUID;

public class DeviceInfo implements Serializable {
    @JsonProperty("device_type")
    private String deviceType;

    @JsonProperty("name")
    private String name;

    @JsonProperty("id")
    private String id;

    @JsonProperty("ip_address")
    private String ipAddress;

    public DeviceInfo() {
    }

    @JsonCreator
    public DeviceInfo(@JsonProperty("device_type") String deviceType,
                      @JsonProperty("name") String name,
                      @JsonProperty("ip_address") String ipAddress) {
        if (deviceType.contains("windows"))
            this.deviceType = "windows";
        else if (deviceType.contains("linux"))
            this.deviceType = "linux";
        this.name = name;
        this.ipAddress = ipAddress;
        this.id = UUID.randomUUID().toString();
    }

    @JsonCreator
    public DeviceInfo(@JsonProperty("device_type") String deviceType, @JsonProperty("name") String name,
                      @JsonProperty("ip_address") String ipAddress, @JsonProperty("id") String id) {
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
}