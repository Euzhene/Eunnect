module com.example.makukujavafx {
    requires javafx.controls;
    requires javafx.fxml;

    requires org.controlsfx.controls;
    requires org.kordamp.bootstrapfx.core;

    opens com.example.makukujavafx to javafx.fxml;
    exports com.example.makukujavafx;
}
