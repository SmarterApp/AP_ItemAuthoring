package com.pacificmetrics.common.web;

import javax.faces.FacesException;
import javax.faces.context.ExceptionHandler;
import javax.faces.context.ExceptionHandlerWrapper;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class DefaultExceptionHandler extends ExceptionHandlerWrapper {

    private static final Log LOGGER = LogFactory
            .getLog(DefaultExceptionHandler.class);
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
        LOGGER.info("Exception:	");
    }

}