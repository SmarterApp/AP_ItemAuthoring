package com.pacificmetrics.common.web;

import javax.faces.component.UIComponent;
import javax.faces.component.UIInput;
import javax.faces.event.AbortProcessingException;
import javax.faces.event.SystemEvent;
import javax.faces.event.SystemEventListener;

/**
 * @author optimus prime
 */
public class PostValidationListener implements SystemEventListener {

    public boolean isListenerForSource(Object source) {
        return true;
    }

    public void processEvent(SystemEvent event) throws AbortProcessingException {
        UIInput source = (UIInput) event.getSource();
        
        String labelId = (String)source.getAttributes().get("label.id");
        if (labelId != null) {
            UIComponent labelComponent = source.findComponent(labelId);
            if (labelComponent != null) {
                if(!source.isValid()) {
                    WebUtils.addStyle(labelComponent, "ui-input-invalid");
                } else {
                    WebUtils.removeStyle(labelComponent, "ui-input-invalid");
                }
            }
        }
    }
    
    
    
}
