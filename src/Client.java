import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.InetAddress;
import java.net.MulticastSocket;

import com.google.gson.Gson;

import classes.DeviceInfo;


public class Client {

    public static void main(String[] args) {
        try {
/*            MulticastSocket multicastSocket = new MulticastSocket(10242);
            InetAddress groupAddress = InetAddress.getByName("224.0.0.1");
            multicastSocket.joinGroup(groupAddress);*/
            DatagramSocket datagramSocket = new DatagramSocket(10242);
            datagramSocket.setBroadcast(true);

            byte[] buffer = new byte[1024];

            while (true) {
                DatagramPacket packet = new DatagramPacket(buffer, buffer.length);
//                multicastSocket.receive(packet);
                datagramSocket.receive(packet);

/*                System.out.println("GET: " );
                DeviceInfo deviceInfo = receiveDeviceInfo(packet.getData());
                if (deviceInfo != null) {
                    System.out.println("Received DeviceInfo: " + deviceInfo);
                }*/
                String json = new String(packet.getData(), packet.getOffset(), packet.getLength());
                Gson gson = new Gson();
                DeviceInfo receivedDeviceInfo = gson.fromJson(json, DeviceInfo.class);

                // Обработка полученного объекта
                System.out.println("Received DeviceInfo: " + receivedDeviceInfo);
//                System.out.println("Received DeviceInfo: " + json);
            }

        } catch (IOException /*| ClassNotFoundException*/ e) {
            e.printStackTrace();
        }
    }

    private static DeviceInfo receiveDeviceInfo(byte[] data) throws IOException, ClassNotFoundException {
        ByteArrayInputStream bais = new ByteArrayInputStream(data);
        ObjectInputStream ois = new ObjectInputStream(bais);
        return (DeviceInfo) ois.readObject();
    }
}