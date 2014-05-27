package com.pacificmetrics.orca.ejb;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;

@Stateless
@LocalBean
public class AccessibilityPassageServices extends AccessibilityServices {

    private static final long serialVersionUID = 1L;

    @Override
    public String getEntityName() {
        return "Passage";
    }
    
    @Override
    public String getFieldName() {
        return "p_id";
    }
    
}
