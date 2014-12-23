package com.pacificmetrics.common.web;

import javax.faces.component.UIComponent;
import javax.faces.component.html.HtmlOutputLabel;
import javax.faces.event.AbortProcessingException;
import javax.faces.event.SystemEvent;
import javax.faces.event.SystemEventListener;

public class LabelProvider implements SystemEventListener {

    public boolean isListenerForSource(Object source) {
        return true;
    }

    public void processEvent(SystemEvent event) throws AbortProcessingException {
        HtmlOutputLabel outputLabel = (HtmlOutputLabel) event.getSource();
        UIComponent target = outputLabel.findComponent(outputLabel.getFor());

        if(target != null) {
            String label = (String)outputLabel.getValue();
            if (label != null) {
                label = label.trim().replaceFirst("^\\*", "").replaceFirst("\\:$", "");
                target.getAttributes().put("label", label);
                target.getAttributes().put("label.id", outputLabel.getId());
            }
        }
    }
}
