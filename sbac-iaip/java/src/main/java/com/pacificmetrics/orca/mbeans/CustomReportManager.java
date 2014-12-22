package com.pacificmetrics.orca.mbeans;

import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Logger;

import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.event.AjaxBehaviorEvent;

import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.common.web.WebUtils;
import com.pacificmetrics.orca.ServerConfiguration;

@ManagedBean(name = "customReport")
@ViewScoped
public class CustomReportManager extends AbstractManager {

    private static final String ITEMS_REPORT = "ItemsReport";
    private static final String PASSAGES_REPORT = "PassagesReport";

    private static final Logger LOGGER = Logger
            .getLogger(CustomReportManager.class.getName());

    private static final long serialVersionUID = 1L;

    private String reportName;

    /**
     * Method returns URL to Jasper server that should be used to invoke items
     * report; URL constructed using server properties: jasper.http.url,
     * jasper.user.name, jasper.password, jasper.reports.directory
     * 
     * @return
     */
    public String getReportUrl() {
        if (StringUtils.isEmpty(reportName)) {
            return "about:blank";
        }
        String jasperHttpUrl = ServerConfiguration
                .getProperty("jasper.http.url");
        String directory = ServerConfiguration
                .getProperty("jasper.reports.directory");
        String itemViewURL = ServerConfiguration.getProperty("item.view.url");
        String passageViewURL = ServerConfiguration
                .getProperty("passage.view.url");
        String result = jasperHttpUrl
                + "/flow.html?standAlone=true&_flowId=viewReportFlow&reportUnit=/Reports"
                + directory
                + "/"
                + reportName
                + "&decorate=no"
                +
                // "&j_username=" + userName + "&j_password=" + password +
                (reportName.equals(ITEMS_REPORT) ? "&ItemViewURL="
                        + WebUtils.encodeURL(itemViewURL) : "")
                + (reportName.equals(PASSAGES_REPORT) ? "&PassageViewURL="
                        + WebUtils.encodeURL(passageViewURL) : "");

        return result;
    }

    public void reportSelected(AjaxBehaviorEvent event) {
        LOGGER.info("Report selected: " + reportName);
    }

    public String getReportName() {
        return reportName;
    }

    public void setReportName(String reportName) {
        this.reportName = reportName;
    }

    public Map<String, String> getReportNamesMap() {
        Map<String, String> result = new TreeMap<String, String>();
        result.put("Items Metadata Report", "ItemsReport");
        result.put("Passages Metadata Report", "PassagesReport");
        return result;
    }

}
