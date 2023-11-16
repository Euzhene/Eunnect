import classes.DeviceInfo;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.*;
import java.net.*;

public class ServerApp extends JFrame {
    private JPanel mainPanel;
    private JButton togglePowerBtn;
    private JTextField textField1;
    private boolean isWorking = false;
    private boolean isServerRunning = false;
    private static DeviceInfo deviceInfo;
    private boolean isFirstLaunch = false;


    public static void main(String[] args) {
        if (deviceInfo == null) {
            System.out.println("device is null");
//            deviceInfo = createDevice();
        } else {
            System.out.println(deviceInfo);
        }

        SwingUtilities.invokeLater(() -> {
            ServerApp serverApp = new ServerApp();
            serverApp.setContentPane(serverApp.mainPanel);
            serverApp.setDefaultCloseOperation(EXIT_ON_CLOSE);
            serverApp.setResizable(false);
            serverApp.pack();
            serverApp.setVisible(true);
        });
    }

//    private static DeviceInfo createDevice() {
//        String platform = System.getProperty("os.name");
//        String name = System.getProperty("user.name");
////        return new DeviceInfo(platform, name, ipAddress);
//    }

    /*private ServerApp() {
        final ServerSocket[] serverSocket = {null};
        final Thread[] serverThread = {null};
        final Socket[] client = {null};
        final BufferedReader[] bufferedReader = {null};
        togglePowerBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (!isWorking) {
                    togglePowerBtn.setText("Turn Off");
                    isWorking = true;
                    isServerRunning = true;
                    try {
                        System.out.println("Server is running on " + InetAddress.getLocalHost().getHostAddress());
                        serverSocket[0] = new ServerSocket(10242);

                        serverThread[0] = new Thread(new Runnable() {
                            @Override
                            public void run() {
                                MAIN:
                                while (!Thread.currentThread().isInterrupted() && isServerRunning) {
                                    try {
                                        client[0] = serverSocket[0].accept();
                                        if (client[0].isConnected()) {
//                                            System.out.println("Client is connected " + client[0].getInetAddress().);
                                        }
                                        bufferedReader[0] = new BufferedReader(new InputStreamReader(client[0].getInputStream()));

                                        while (true) {
                                            String msgFromClient = bufferedReader[0].readLine();
//                                            System.out.println("Client: " + msgFromClient);
                                            textField1.setText("");
                                            textField1.setText(msgFromClient);

                                        }
                                    } catch (IOException ex) {
                                        if (!isServerRunning) {
                                            break;
                                        }
                                        throw new RuntimeException(ex);
                                    } finally {
                                        try {
                                            if (client[0] != null && !client[0].isClosed()) {
                                                client[0].close();
                                            }
                                            if (bufferedReader[0] != null) {
                                                bufferedReader[0].close();
                                            }
                                        } catch (IOException ex) {
                                            throw new RuntimeException(ex);
                                        }
                                    }
                                }
                            }
                        });

                        serverThread[0].start();
                    } catch (IOException ex) {
                        throw new RuntimeException(ex);
                    }
                } else {
                    isWorking = false;
                    togglePowerBtn.setText("Turn On");
                    try {
                        if (serverSocket[0] != null) {
                            isServerRunning = false;
//                            if (serverThread[0] != null && serverThread[0].isAlive()) {
//                                serverThread[0].interrupt();
//                                try {
//                                    serverThread[0].join();
//                                } catch (InterruptedException ex) {
//                                    throw new RuntimeException(ex);
//                                }
//                            }
                            if (client[0] != null && !client[0].isClosed()) {
                                System.out.println("Client is closed");
                                client[0].close();
                            }
                            if (bufferedReader[0] != null) {
                                System.out.println("Buffer is closed");
                                bufferedReader[0].close();
                            }
                            serverSocket[0].close();
                            if (serverSocket[0].isClosed()) {
                                System.out.println("Server is closed");
                            }
                        }
                    } catch (IOException ex) {
                        ex.printStackTrace();
                    }

                }
            }
        });
    }*/
    private ServerApp() {
        final ServerSocket[] serverSocket = {null};
        final Thread[] serverThread = {null};
        final Socket[] client = {null};
        final BufferedReader[] bufferedReader = {null};
        final MulticastSocket[] multicastSocket = {null};

        togglePowerBtn.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (!isWorking) {
                    togglePowerBtn.setText("Turn Off");
                    isWorking = true;
                    isServerRunning = true;
                    try {
                        // Создаем сокет для мультикастинга
                        multicastSocket[0] = new MulticastSocket();
                        InetAddress groupAddress = InetAddress.getByName("229.30.13.47");
                        multicastSocket[0].joinGroup(groupAddress);

                        System.out.println("Server is running on " + InetAddress.getLocalHost().getHostAddress());
                        serverSocket[0] = new ServerSocket(10242);

                        serverThread[0] = new Thread(new Runnable() {
                            @Override
                            public void run() {
                                MAIN:
                                while (!Thread.currentThread().isInterrupted() && isServerRunning) {
                                    try {
                                        // Отправляем данные в мультикаст-группу
                                        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                                        ObjectOutputStream objectOutputStream = new ObjectOutputStream(byteArrayOutputStream);
                                        objectOutputStream.writeObject(deviceInfo);

                                        byte[] data = byteArrayOutputStream.toByteArray();
                                        DatagramPacket packet = new DatagramPacket(data, data.length, groupAddress, 9876);
                                        multicastSocket[0].send(packet);

                                        // Принимаем данные от клиента
                                        client[0] = serverSocket[0].accept();
                                        if (client[0].isConnected()) {
                                            bufferedReader[0] = new BufferedReader(new InputStreamReader(client[0].getInputStream()));

                                            while (true) {
                                                String msgFromClient = bufferedReader[0].readLine();
                                                textField1.setText(msgFromClient);
                                                if (msgFromClient.equalsIgnoreCase("exit"))
                                                    break MAIN;
                                            }
                                        }
                                    } catch (IOException ex) {
                                        if (!isServerRunning) {
                                            break;
                                        }
                                        throw new RuntimeException(ex);
                                    } finally {
                                        try {
                                            if (client[0] != null && !client[0].isClosed()) {
                                                client[0].close();
                                            }
                                            if (bufferedReader[0] != null) {
                                                bufferedReader[0].close();
                                            }
                                        } catch (IOException ex) {
                                            throw new RuntimeException(ex);
                                        }
                                    }
                                }
                            }
                        });

                        serverThread[0].start();
                    } catch (IOException ex) {
                        throw new RuntimeException(ex);
                    }
                } else {
                    isWorking = false;
                    togglePowerBtn.setText("Turn On");
                    try {
                        if (serverSocket[0] != null) {
                            isServerRunning = false;
                            multicastSocket[0].leaveGroup(InetAddress.getByName("229.30.13.47"));
                            multicastSocket[0].close();

                            if (client[0] != null && !client[0].isClosed()) {
                                System.out.println("Client is closed");
                                client[0].close();
                            }
                            if (bufferedReader[0] != null) {
                                System.out.println("Buffer is closed");
                                bufferedReader[0].close();
                            }
                            serverSocket[0].close();
                            if (serverSocket[0].isClosed()) {
                                System.out.println("Server is closed");
                            }
                        }
                    } catch (IOException ex) {
                        ex.printStackTrace();
                    }

                }
            }
        });
    }
}
