package com.example.makukujavafx;

public enum ImagePath {
    PHONE("com/example/makukujavafx/phone.png"),
    TABLET("com/example/makukujavafx/tablet.png"),
    WINDOWS("com/example/makukujavafx/windows.png"),
    LINUX("com/example/makukujavafx/linux.png"),
    PAIRING("com/example/makukujavafx/pairing.png"),
    UNPAIRING("com/example/makukujavafx/unpairing.png");

    private String path;

    ImagePath(String path) {
        this.path = path;
    }

    public String getPath() {
        return this.path;
    }

}
