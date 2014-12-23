package com.pacificmetrics.orca.utils;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class SchedulerUtil {

	private static final Log LOGGER = LogFactory.getLog(SchedulerUtil.class);

	private String hour;

	private String minute;

	private String second;
	
	public SchedulerUtil(String expression) {
		LOGGER.debug("Parsing scheduler expression " + expression);
		String [] expressionParts  = expression.split(" ");
		if(expressionParts.length >=3) {
			hour = expressionParts[0];
			minute = expressionParts[1];
			second = expressionParts[2];
		}
		LOGGER.debug("Unable to parse expression " + expression);
	}
	
	public String getExpression() {
		return hour + " " + minute + " " + second;
	}

	public String getHour() {
		return hour;
	}

	public void setHour(String hour) {
		this.hour = hour;
	}

	public String getMinute() {
		return minute;
	}

	public void setMinute(String minute) {
		this.minute = minute;
	}

	public String getSecond() {
		return second;
	}

	public void setSecond(String second) {
		this.second = second;
	}

}
