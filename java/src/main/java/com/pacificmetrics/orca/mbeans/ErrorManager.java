package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;

import javax.faces.bean.ManagedBean;
import javax.faces.bean.SessionScoped;

@ManagedBean(name="error")
@SessionScoped
public class ErrorManager implements Serializable {
    
    private static final long serialVersionUID = 1L;

    private String errorText;
    private String errorDetails;

    public ErrorManager() {
        // TODO Auto-generated constructor stub
    }

    public String getErrorText() {
        return errorText;
    }

    public void setErrorText(String errorText) {
        this.errorText = errorText;
    }

    public String getErrorDetails() {
        return errorDetails;
    }

    public void setErrorDetails(String errorDetails) {
        this.errorDetails = errorDetails;
    }

}
