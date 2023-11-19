package classes;

import java.io.*;
import java.util.UUID;

public class DeviceInfo implements Serializable {
    private String device_type;
    private final String name;
    public final String id;
    private String ip_address;

    public DeviceInfo(String device_type, String name, String ip_address) {
        if (device_type.contains("windows"))
            this.device_type = "windows";
        else if (device_type.contains("linux"))
            this.device_type = "linux";
        this.name = name;
        this.ip_address = ip_address;
        this.id = UUID.randomUUID().toString();
    }

    public DeviceInfo(String device_type, String name, String ip_address, String id) {
        if (device_type.contains("windows"))
            this.device_type = "windows";
        else if (device_type.contains("linux"))
            this.device_type = "linux";
        this.name = name;
        this.ip_address = ip_address;
        this.id = id;
    }


    public String getName() {
        return name;
    }


    public String getDevice_type() {
        return device_type;
    }

    public String getId() {
        return id;
    }

    public String getIp_address() {
        return ip_address;
    }

    public void setIp_address(String ip_address) {
        this.ip_address = ip_address;
    }

    @Override
    public String toString() {
        return "DeviceInfo{" +
                "deviceType='" + device_type + '\'' +
                ", name='" + name + '\'' +
                ", id='" + id + '\'' +
                ", ipAddress='" + ip_address + '\'' +
                '}';
    }
}
