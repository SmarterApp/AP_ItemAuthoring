package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.io.IOException;
import java.util.Date;

import javax.annotation.PostConstruct;
import javax.annotation.Resource;
import javax.ejb.EJB;
import javax.ejb.ScheduleExpression;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.ejb.Timeout;
import javax.ejb.Timer;
import javax.ejb.TimerService;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.orca.utils.SchedulerUtil;

@Startup
@Singleton
public class IMSFTPScheduler {

    private static final Log LOGGER = LogFactory.getLog(IMSFTPScheduler.class);

    private static final String INPROGRESS_FILE = "ims_content_import_monitor.inprogress";

    @Resource
    private TimerService timerService;

    @EJB
    private IMSFTPImporter imsFTPImporter;

    @PostConstruct
    public void initTimer() {
        LOGGER.info("IMSFTPScheduler bean started ...");
        LOGGER.info("Removing previously stale in progress file ...");
        String tempPath = PropertyUtil.getProperty(PropertyUtil.FTP_TEMP_PATH);
        removeInProgressFile(tempPath);
        LOGGER.info("Removed previously stale in progress file ...");
        String expression = PropertyUtil
                .getProperty(PropertyUtil.FTP_IMPORT_EXPRESSION);
        SchedulerUtil schedulerUtil = new SchedulerUtil(expression);
        ScheduleExpression scheduleExpression = new ScheduleExpression();
        scheduleExpression.hour(schedulerUtil.getHour())
                .minute(schedulerUtil.getMinute())
                .second(schedulerUtil.getSecond());
        timerService.createCalendarTimer(scheduleExpression);
        LOGGER.info("IMSFTPScheduler completed creating scheduler with expression "
                + scheduleExpression.getHour()
                + " "
                + scheduleExpression.getMinute()
                + " "
                + scheduleExpression.getSecond());
    }

    @Timeout
    public void timeout(Timer timer) {
        String sourcePath = PropertyUtil
                .getProperty(PropertyUtil.FTP_IMPORT_SOURCE);
        String tempPath = PropertyUtil.getProperty(PropertyUtil.FTP_TEMP_PATH);
        if (isSchedulerRunning(tempPath)) {
            LOGGER.error("Exiting current import task invocation as scheduler is already running "
                    + new Date());
        }
        if (createInProgressFile(tempPath)) {
            LOGGER.info("Invoking IMSFTPImporter ...");
            imsFTPImporter.importFromFTP(sourcePath);
            LOGGER.info("Completed IMSFTPImporter task ...");
            removeInProgressFile(tempPath);
        } else {
            LOGGER.error("Exiting current import task invocation as unable to create in progress file "
                    + new Date());
        }
    }

    private boolean createInProgressFile(String path) {
        try {
            File processorFile = new File(path + File.separator
                    + INPROGRESS_FILE);
            if (!processorFile.exists()) {
                return processorFile.createNewFile();
            }
        } catch (IOException e) {
            LOGGER.error("Unable to create in progress file " + e.getMessage(),
                    e);
            return false;
        } catch (Exception e) {
            LOGGER.error("Unable to create in progress file " + e.getMessage(),
                    e);
            return false;
        }
        return false;
    }

    private boolean isSchedulerRunning(String path) {
        File processorFile = new File(path + File.separator + INPROGRESS_FILE);
        return processorFile.exists();
    }

    private boolean removeInProgressFile(String path) {
        try {
            File processorFile = new File(path + File.separator
                    + INPROGRESS_FILE);
            if (processorFile.exists()) {
                return processorFile.delete();
            }
        } catch (Exception e) {
            LOGGER.error("Unable to remove in progress file " + e.getMessage(),
                    e);
            return false;
        }
        return false;
    }

}
