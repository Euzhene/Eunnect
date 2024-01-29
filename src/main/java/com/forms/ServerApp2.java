package com.forms;

import com.classes.JsonHandler;
import com.classes.ServerHandler;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;

import javax.imageio.ImageIO;
import javax.swing.*;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;
import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.IOException;
import java.net.URL;

public class ServerApp2 extends JFrame {
    private JPanel panel1;
    private JLabel currentConnectedDeviceLabel;
    private JList<Pair> pairedDevicesList;
    private JLabel fileStatusLabel;
    private JPanel topPanel;
    public JProgressBar progressBar1;
    private ServerHandler serverHandler;
    public static ServerApp2 serverApp;
    private DefaultListModel<Pair> listModel = new DefaultListModel();
    private ArrayNode jsonArray;

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            serverApp = new ServerApp2();
            serverApp.setContentPane(serverApp.panel1);
            serverApp.setDefaultCloseOperation(EXIT_ON_CLOSE);
            serverApp.setResizable(false);
            serverApp.pack();
            serverApp.setVisible(true);
        });
    }

    public ServerApp2() {
        pairedDevicesList.setModel(listModel);
        pairedDevicesList.setCellRenderer(new PairListCellRenderer(pairedDevicesList, listModel));
        pairedDevicesList.setFixedCellWidth(50);
        progressBar1.setStringPainted(true);

        serverHandler = new ServerHandler();
        serverHandler.initialization();

        jsonArray = JsonHandler.loadJsonFromFile();
        readJSON(jsonArray);

        startServerAsync();

        pairedDevicesList.addListSelectionListener(new ListSelectionListener() {
            @Override
            public void valueChanged(ListSelectionEvent e) {
                if (!e.getValueIsAdjusting()) {
                    int selectedIndex = pairedDevicesList.getSelectedIndex();
                    if (selectedIndex != -1) {
                        Pair selectedPair = listModel.getElementAt(selectedIndex);

                        System.out.println("Removed: " + selectedPair.deviceName);

                        jsonArray.remove(selectedIndex);
                        JsonHandler.saveJsonToFile(jsonArray);
                        readJSON(jsonArray);
                    }
                }
            }
        });
    }

    private void startServerAsync() {
        SwingWorker<Void, Void> worker = new SwingWorker<Void, Void>() {
            @Override
            protected Void doInBackground() {
                try {
                    serverHandler.startServer();
                } catch (IOException ex) {
                    throw new RuntimeException(ex);
                }
                return null;
            }
        };
        worker.execute();
    }

    public void setCurrentConnectedDeviceLabel(String name) {
        currentConnectedDeviceLabel.setText(name);
    }

    public void setFileStatusLabel(String file_status) {
        fileStatusLabel.setText(file_status);
    }

    public void setProgressBar(int percent) {
        SwingUtilities.invokeLater(() -> {
            progressBar1.setValue(percent);
            progressBar1.setString(String.valueOf(percent) + "%");
        });
    }

    public void setTopPanel(Color color) {
        topPanel.setBackground(color);
    }

    public void readJSON(ArrayNode jsonArray) {
        this.jsonArray = jsonArray;
        listModel.clear();

        for (JsonNode jsonNode : jsonArray) {
            String device_name = jsonNode.get("name").asText();
            listModel.addElement(new Pair(device_name, ServerApp2.class.getResource("/logo.png"), ServerApp2.class.getResource("/unpair.png")));
            System.out.println(device_name);
        }
    }

    private static class Pair {
        String deviceName;
        URL iconName; // Изменил тип на URL
        URL unpairIcon; // Изменил тип на URL

        Pair(String deviceName, URL iconName, URL unpairIcon) {
            this.deviceName = deviceName;
            this.iconName = iconName;
            this.unpairIcon = unpairIcon;
        }
    }

    private static class PairListCellRenderer implements ListCellRenderer<Pair> {
        private final JPanel panel;
        private final JLabel label;
        private final JLabel iconLabel;
        private final JLabel iconUnpairLabel;
        private final JList<Pair> pairedDevicesList;
        private final DefaultListModel<Pair> listModel;

        public PairListCellRenderer(JList<Pair> pairedDevicesList, DefaultListModel<Pair> listModel) {
            this.pairedDevicesList = pairedDevicesList;
            this.listModel = listModel;

            // Создаем компоненты интерфейса
            panel = new JPanel(new BorderLayout());
            label = new JLabel();
            iconLabel = new JLabel();
            iconUnpairLabel = new JLabel();

            // Добавляем компоненты на панель
            panel.add(label, BorderLayout.CENTER);
            panel.add(iconUnpairLabel, BorderLayout.EAST);
            panel.add(iconLabel, BorderLayout.WEST);

            // Настраиваем внешний вид компонентов
            panel.setBackground(new Color(0x363636));
            label.setForeground(Color.WHITE);
            label.setFont(new Font("Arial", Font.BOLD, 18));

            // Задаем размер для изображения
            iconLabel.setPreferredSize(new Dimension(35, 40));
            iconUnpairLabel.setPreferredSize(new Dimension(30, 30));

            // Добавляем обработчик событий мыши для правого клика
            pairedDevicesList.addMouseListener(new MouseAdapter() {
                @Override
                public void mouseClicked(MouseEvent e) {
                    if (SwingUtilities.isRightMouseButton(e) && !e.isConsumed()) {
                        int index = pairedDevicesList.locationToIndex(e.getPoint());
                        pairedDevicesList.setSelectedIndex(index);
                        e.consume();
                    }
                }
            });
        }

        @Override
        public Component getListCellRendererComponent(JList<? extends Pair> list, Pair value, int index, boolean isSelected, boolean cellHasFocus) {
            // Устанавливаем текст для метки
            label.setText(value.deviceName);

            // Создаем и устанавливаем иконку для основного изображения
            ImageIcon icon = createImageIcon(value.iconName);
            if (icon != null) {
                iconLabel.setIcon(icon);
            } else {
                iconLabel.setIcon(null);
            }

            // Создаем и устанавливаем иконку для второго изображения
            icon = createImageIcon(value.unpairIcon);
            if (icon != null) {
                iconUnpairLabel.setIcon(icon);
            } else {
                iconUnpairLabel.setIcon(null);
            }

            return panel;
        }

        private ImageIcon createImageIcon(URL url) {
            try {
                // Проверяем, что URL не равен null
                if (url != null) {
                    // Читаем изображение из URL
                    Image image = ImageIO.read(url);
                    // Создаем и возвращаем иконку из изображения
                    return new ImageIcon(image);
                } else {
                    System.err.println("URL is null.");
                    return null;
                }
            } catch (IOException e) {
                e.printStackTrace();
                return null;
            }
        }
    }

    /*private static class Pair {
        String deviceName;
        String iconName;
        String unpairIcon;

        Pair(String deviceName, String iconName, String unpairIcon) {
            this.deviceName = deviceName;
            this.iconName = iconName;
            this.unpairIcon = unpairIcon;
        }
    }

    private static class PairListCellRenderer implements ListCellRenderer<Pair> {
        private final JPanel panel;
        private final JLabel label;
        private final JLabel iconLabel;
        private final JLabel iconUnpairLabel;
        private final JList<Pair> pairedDevicesList;
        private final DefaultListModel<Pair> listModel;

        public PairListCellRenderer(JList<Pair> pairedDevicesList, DefaultListModel<Pair> listModel) {
            this.pairedDevicesList = pairedDevicesList;
            this.listModel = listModel;

            panel = new JPanel(new BorderLayout());
            label = new JLabel();
            iconLabel = new JLabel();
            iconUnpairLabel = new JLabel();

            panel.add(label, BorderLayout.CENTER);
            panel.add(iconUnpairLabel, BorderLayout.EAST);
            panel.add(iconLabel, BorderLayout.WEST);

            panel.setBackground(new Color(0x363636));
            label.setForeground(Color.WHITE);
            label.setFont(new Font("Arial", Font.BOLD, 18));

            iconLabel.setPreferredSize(new Dimension(35, 40));
            iconUnpairLabel.setPreferredSize(new Dimension(30, 30));

            pairedDevicesList.addMouseListener(new MouseAdapter() {
                @Override
                public void mouseClicked(MouseEvent e) {
                    if (SwingUtilities.isRightMouseButton(e) && !e.isConsumed()) {
                        int index = pairedDevicesList.locationToIndex(e.getPoint());
                        pairedDevicesList.setSelectedIndex(index);
                        e.consume();
                    }
                }
            });
        }

        @Override
        public Component getListCellRendererComponent(JList<? extends Pair> list, Pair value, int index, boolean isSelected, boolean cellHasFocus) {
            label.setText(value.deviceName);

            ImageIcon icon = createImageIcon(value.iconName);
            if (icon != null) {
                iconLabel.setIcon(icon);
            } else {
                iconLabel.setIcon(null);
            }

            icon = createImageIcon(value.unpairIcon);
            if (icon != null) {
                iconUnpairLabel.setIcon(icon);
            } else {
                iconUnpairLabel.setIcon(null);
            }

            return panel;
        }

        private ImageIcon createImageIcon(String path) {
            try {
                URL imgUrl = getClass().getResource(path);
                if (imgUrl != null) {
                    Image image = ImageIO.read(imgUrl);
                    return new ImageIcon(image);
                } else {
                    System.err.println("Couldn't find file: " + path);
                    return null;
                }
            } catch (IOException e) {
                e.printStackTrace();
                return null;
            }
        }
    }*/
}