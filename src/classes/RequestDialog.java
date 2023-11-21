package classes;
import javax.swing.*;
import java.awt.*;

public class RequestDialog extends JDialog {
    public RequestDialog(JFrame parent, String deviceInfo) {
        super(parent, "Запрос на сопряжение", true);

        setSize(400, 200);
        setLayout(new BorderLayout());

        JLabel titleLabel = new JLabel("Запрос на сопряжение");
        titleLabel.setHorizontalAlignment(JLabel.CENTER);
        add(titleLabel, BorderLayout.NORTH);

        JTextArea deviceInfoTextArea = new JTextArea(deviceInfo);
        deviceInfoTextArea.setEditable(false);
        JScrollPane scrollPane = new JScrollPane(deviceInfoTextArea);
        add(scrollPane, BorderLayout.CENTER);

        JPanel buttonPanel = new JPanel();
        JButton rejectButton = new JButton("Отклонить");
        JButton allowButton = new JButton("Разрешить");
        buttonPanel.add(rejectButton);
        buttonPanel.add(allowButton);
        add(buttonPanel, BorderLayout.SOUTH);

        rejectButton.addActionListener(e -> {
            rejectPair();
        });

        allowButton.addActionListener(e -> {
            allowPair();
        });

        setLocationRelativeTo(parent);
        setResizable(false);
    }
    private boolean isPairAllowed = false;
    public boolean isPairAllowed() {
        return isPairAllowed;
    }

    private void allowPair() {
        isPairAllowed = true;
        dispose();
    }

    private void rejectPair() {
        isPairAllowed = false;
        dispose();
    }
}
