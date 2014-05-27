package com.pacificmetrics.common.web;

import javax.faces.context.ExceptionHandler;
import javax.faces.context.ExceptionHandlerFactory;

public class ExceptionHandlerFactoryImpl extends ExceptionHandlerFactory {
	
	private ExceptionHandlerFactory parent;
	
	public ExceptionHandlerFactoryImpl(ExceptionHandlerFactory parent) {
		this.parent = parent;
	}

	@Override
	public ExceptionHandler getExceptionHandler() {
		return new DefaultExceptionHandler(parent.getExceptionHandler());
	}

}
