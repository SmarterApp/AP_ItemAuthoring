package com.pacificmetrics.orca.mbeans;

import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.io.Serializable;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.Map;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;
import javax.faces.event.PhaseEvent;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;

import com.pacificmetrics.common.Report;
import com.pacificmetrics.common.web.ManagerException;
import com.pacificmetrics.common.web.WebUtils;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ReportServices;

@ManagedBean(name = "report")
@ViewScoped
public class ReportManager extends AbstractManager implements Serializable {

    private static final Logger LOGGER = Logger.getLogger(ReportManager.class
            .getName());
    private static final long serialVersionUID = 1L;
    private String reportName;
    private String saveAsFormat;

    private String content;

    @EJB
    private transient ReportServices reportServices;

    @PostConstruct
    public void load() throws ManagerException {
        reportName = getParameter("name", "");
        saveAsFormat = getParameter("output",
                ServerConfiguration.getProperty("jasper.default.output"));
        content = new String(generateReport(Report.FORMAT_HTML));
    }

    private String getReportParametersAsString() {
        String result = "";
        for (Map.Entry<String, String> entry : parametersMap.entrySet()) {
            if (entry.getKey().startsWith("p_")) {
                result += "&" + entry.getKey().substring(2) + "="
                        + entry.getValue();
            }
        }
        return result;
    }

    /**
     * parameters that have to be passed to the report are derived from page
     * parameters that have prefix p_
     * 
     * @param report
     */
    private void addParameters(Report report) {
        for (Map.Entry<String, String> entry : parametersMap.entrySet()) {
            if (entry.getKey().startsWith("p_")) {
                report.addParameter(entry.getKey().substring(2),
                        entry.getValue());
            }
        }
    }

    public void generate2(PhaseEvent event) throws ManagerException {
        LOGGER.info("Generating report");
        String url = ServerConfiguration.getProperty("jasper.url");

        String requestURL = url + reportName + "&output=" + saveAsFormat
                + getReportParametersAsString();

        String fileName = reportName.substring(reportName.lastIndexOf('/') + 1)
                + "." + saveAsFormat;

        try {
            URLConnection con = new URL(requestURL).openConnection();

            byte[] bytes = IOUtils.toByteArray(con.getInputStream());

            FileUtils
                    .writeByteArrayToFile(new File("/temp/" + fileName), bytes);

            FacesContext fc = FacesContext.getCurrentInstance();
            ExternalContext ec = fc.getExternalContext();

            ec.responseReset(); // Some JSF component library or some Filter
                                // might have set some headers in the buffer
                                // beforehand. We want to get rid of them, else
                                // it may collide.
            ec.setResponseContentType(ec.getMimeType(fileName)); // Check
                                                                 // http://www.w3schools.com/media/media_mimeref.asp
                                                                 // for all
                                                                 // types. Use
                                                                 // if necessary
                                                                 // ExternalContext#getMimeType()
                                                                 // for
                                                                 // auto-detection
                                                                 // based on
                                                                 // filename.
            ec.setResponseContentLength(bytes.length); // Set it with the file
                                                       // size. This header is
                                                       // optional. It will work
                                                       // if it's omitted, but
                                                       // the download progress
                                                       // will be unknown.
            ec.setResponseHeader("Content-Disposition",
                    "attachment; filename=\"" + fileName + "\""); // The Save As
                                                                  // popup magic
                                                                  // is done
                                                                  // here. You
                                                                  // can give it
                                                                  // any file
                                                                  // name you
                                                                  // want, this
                                                                  // only won't
                                                                  // work in
                                                                  // MSIE, it
                                                                  // will use
                                                                  // current
                                                                  // request URL
                                                                  // as file
                                                                  // name
                                                                  // instead.

            OutputStream os = ec.getResponseOutputStream();
            os.write(bytes);
            // Now you can write the InputStream of the file to the above
            // OutputStream the usual way.
            // ...

            fc.responseComplete();

        } catch (MalformedURLException e) {
            throw new ManagerException(e);
        } catch (IOException e) {
            throw new ManagerException(e);
        }
    }

    private byte[] generateReport(String format) throws ManagerException {
        LOGGER.info("About to generate report " + reportName);
        Report report = new Report();
        report.setFormat(format);
        report.setUrl(reportName);

        addParameters(report);

        try {
            return reportServices.getReportAsByteArray(report);
        } catch (Exception e) {
            throw new ManagerException(e);
        }

    }

    public void doSave() throws ManagerException {
        LOGGER.info("Saving as " + saveAsFormat + "...");
        try {
            byte[] bytes = generateReport(saveAsFormat);

            String fileName = reportName
                    .substring(reportName.lastIndexOf('/') + 1)
                    + "."
                    + saveAsFormat;

            WebUtils.sendFileToDownload(fileName, bytes);

        } catch (IOException e) {
            throw new ManagerException(e);
        }
    }

    public String getContent() throws ManagerException {
        if (content == null) {
            content = new String(generateReport(Report.FORMAT_HTML));
        }
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getSaveAsFormat() {
        return saveAsFormat;
    }

    public void setSaveAsFormat(String saveAsFormat) {
        this.saveAsFormat = saveAsFormat;
    }

}
