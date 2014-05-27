package com.pacificmetrics.common.web;

import java.util.logging.Logger;

import javax.faces.FacesException;
import javax.faces.context.ExceptionHandler;
import javax.faces.context.ExceptionHandlerWrapper;

public class DefaultExceptionHandler extends ExceptionHandlerWrapper {
	
	private final Logger logger = Logger.getLogger(DefaultExceptionHandler.class.getName());

    private ExceptionHandler wrapped;

    public DefaultExceptionHandler(ExceptionHandler wrapped) {
        this.wrapped = wrapped;
    }

    @Override
    public ExceptionHandler getWrapped() {  
        return this.wrapped;
    }

    @Override
    public void handle() throws FacesException {
    	System.out.println("Exception:");
    }

}