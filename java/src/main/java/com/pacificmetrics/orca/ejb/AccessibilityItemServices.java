package com.pacificmetrics.orca.ejb;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;

@Stateless
@LocalBean
public class AccessibilityItemServices extends AccessibilityServices {

    private static final long serialVersionUID = 1L;

    @Override
    public String getEntityName() {
        return "Item";
    }
    
    @Override
    public String getFieldName() {
        return "i_id";
    }
    
}
