package com.pacificmetrics.common;

import java.io.Serializable;

import javax.validation.ConstraintViolation;
import javax.validation.ConstraintViolationException;
import javax.validation.ValidationException;

public class ServiceException extends ApplicationException implements Serializable {

	private static final long serialVersionUID = 1L;
	
	public ServiceException(Status status) {
		super(status, null);
	}

	public ServiceException(Status status, Object data) {
	    super(status, data);
	}
	
    public ServiceException(ValidationException e) {
        status = Status.VALIDATION_FAILED;
        data = e.getMessage();
        if (e instanceof ConstraintViolationException) {
            initialize((ConstraintViolationException)e);
        }
    }
    
    private void initialize(ConstraintViolationException e) {
        data = new StringBuffer();
        for (ConstraintViolation<?> cv: e.getConstraintViolations()) {
            ((StringBuffer)data).append(cv.getMessage() + "; ");
        }
        
    }

}
