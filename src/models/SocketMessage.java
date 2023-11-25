package models;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public class SocketMessage {
    @JsonProperty("call")
    private String call;
    @JsonProperty("data")
    private String data;
    @JsonProperty("status")
    private int status;
    /*    @JsonProperty("error")
        private String error;*/
    @JsonProperty("device_id")
    private String device_id;

    public SocketMessage() {
    }

    @JsonCreator
    public SocketMessage(@JsonProperty("call") String call,
                         @JsonProperty("data") String data,
                         @JsonProperty("status") int status,
//                         @JsonProperty("error") String error,
                         @JsonProperty("device_id") String deviceId) {
        this.call = call;
        this.data = data;
        this.status = status;
//        this.error = error;
        this.device_id = deviceId;
    }

    public String getCall() {
        return call;
    }

    public String getData() {
        return data;
    }

    public int getStatus() {
        return status;
    }
/*    public String getError() {
        return error;
    }*/

    public String getDevice_id() {
        return device_id;
    }

    @Override
    public String toString() {
        return "SocketMessage{" +
                "call='" + call + '\'' +
                ", data='" + data + '\'' +
                ", status='" + status + '\'' +
                ", device_id='" + device_id + '\'' +
                '}';
    }
}