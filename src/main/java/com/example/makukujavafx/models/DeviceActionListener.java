package com.example.makukujavafx.models;

import com.fasterxml.jackson.databind.node.ObjectNode;

import java.util.EventListener;

public interface DeviceActionListener<T> extends EventListener {
    public void onAction(T value);


}
