package classes;

public class SocketMessage {
    private String call;
    private String data;
    private String error;
    private String device_id;

    public SocketMessage(String call, String data, String error, String device_id) {
        this.call = call;
        this.data = data;
        this.error = error;
        this.device_id = device_id;
    }

    public String getCall() {
        return call;
    }

    public String getData() {
        return data;
    }

    public String getError() {
        return error;
    }

    public String getDevice_id() {
        return device_id;
    }

    @Override
    public String toString() {
        return "SocketMessage{" +
                "call='" + call + '\'' +
                ", data='" + data + '\'' +
                ", error='" + error + '\'' +
                ", device_id='" + device_id + '\'' +
                '}';
    }
}

