module com.example.makukujavafx {
    requires javafx.controls;
    requires javafx.fxml;
    opens com.example.makukujavafx.models to com.fasterxml.jackson.databind;

    requires org.controlsfx.controls;
    requires org.kordamp.bootstrapfx.core;
    requires java.prefs;
    requires com.fasterxml.jackson.databind;
    requires java.desktop;
    requires javax.jmdns;

    opens com.example.makukujavafx to javafx.fxml;
    exports com.example.makukujavafx;
    exports com.example.makukujavafx.models;
}
