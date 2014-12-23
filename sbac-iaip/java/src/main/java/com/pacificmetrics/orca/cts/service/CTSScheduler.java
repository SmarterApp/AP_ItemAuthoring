package com.pacificmetrics.orca.cts.service;

import java.util.concurrent.TimeUnit;

import javax.annotation.PostConstruct;
import javax.annotation.PreDestroy;
import javax.annotation.Resource;
import javax.ejb.AccessTimeout;
import javax.ejb.EJB;
import javax.ejb.ScheduleExpression;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.ejb.Timeout;
import javax.ejb.TimerService;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.orca.utils.SchedulerUtil;

@Startup
@Singleton
public class CTSScheduler {

    private static final Log LOGGER = LogFactory.getLog(CTSScheduler.class);

    @Resource
    private TimerService timerService;

    @EJB
    private CTSCacheService ctsService;

    @PostConstruct
    public void init() {
        if ("true".equalsIgnoreCase(PropertyUtil
                .getProperty(PropertyUtil.CTS_CACHE_ENABLE))) {
            createScheduler();
            loadCache();
        }
    }

    private void createScheduler() {
        LOGGER.info("CTSScheduler bean started ...");
        String expression = PropertyUtil
                .getProperty(PropertyUtil.CTS_EXPRESSION);
        SchedulerUtil schedulerUtil = new SchedulerUtil(expression);
        ScheduleExpression scheduleExpression = new ScheduleExpression();
        scheduleExpression.hour(schedulerUtil.getHour())
                .minute(schedulerUtil.getMinute())
                .second(schedulerUtil.getSecond());
        timerService.createCalendarTimer(scheduleExpression);
        LOGGER.info("CTSScheduler completed creating scheduler with expression "
                + scheduleExpression.getHour()
                + " "
                + scheduleExpression.getMinute()
                + " "
                + scheduleExpression.getSecond());
    }

    private void loadCache() {
        LOGGER.info("Intializing CTS Cache scheduler...");
        ctsService.initCache();
        LOGGER.info("Complete initializing CTS Cache scheduler ...");
    }

    @Timeout
    @AccessTimeout(value = 1, unit = TimeUnit.HOURS)
    private void reloadCache() {
        LOGGER.info("Reloading CTS Cache ...");
        ctsService.refreshCache();
        LOGGER.info("Complete reloading CTS Cache ...");
    }

    @PreDestroy
    public void destroy() {
        LOGGER.info("Destroying CTS Cache ...");
        ctsService.destroyCache();
        LOGGER.info("Complete destroying CTS Cache ...");
    }
}
