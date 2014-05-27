package com.pacificmetrics.common;

public class ApplicationException extends Exception {

    private static final long serialVersionUID = 1L;

    protected Status status;
    protected Object data;
    
    public Object getData() {
        return data;
    }

    public Status getStatus() {
        return status;
    }
    
    protected ApplicationException() {
        
    }
    
    public ApplicationException(Status status) {
        this(status, null);
    }

    public ApplicationException(Status status, Object data) {
        this.status = status;
        this.data = data;
    }

}
