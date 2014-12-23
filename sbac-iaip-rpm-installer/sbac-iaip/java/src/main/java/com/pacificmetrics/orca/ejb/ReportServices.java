package com.pacificmetrics.orca.ejb;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.Local;
import javax.ejb.Stateful;
import javax.ws.rs.core.MediaType;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.DocumentHelper;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.XMLWriter;

import com.pacificmetrics.common.Report;
import com.pacificmetrics.common.ReportException;
import com.pacificmetrics.orca.ServerConfiguration;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.api.client.config.ClientConfig;
import com.sun.jersey.api.client.filter.HTTPBasicAuthFilter;
import com.sun.jersey.client.apache.ApacheHttpClient;
import com.sun.jersey.client.apache.config.ApacheHttpClientConfig;
import com.sun.jersey.client.apache.config.DefaultApacheHttpClientConfig;

@Stateful
@Local
public class ReportServices {

    private static final Logger LOGGER = Logger.getLogger(ReportServices.class
            .getName());

    private ClientConfig clientConfig;
    private String userName;
    private String password;
    private String reportsDirectory;

    private Map<String, String> resourceCache;
    private String restEndpointUrl;

    public ReportServices() {
    }

    @PostConstruct
    public void init() {
        restEndpointUrl = ServerConfiguration.getProperty("jasper.url");
        userName = ServerConfiguration.getProperty("jasper.user.name");
        password = ServerConfiguration.getProperty("jasper.password");
        reportsDirectory = ServerConfiguration
                .getProperty("jasper.reports.directory");
        clientConfig = new DefaultApacheHttpClientConfig();
        clientConfig.getProperties().put(
                ClientConfig.PROPERTY_FOLLOW_REDIRECTS, true);
        clientConfig.getProperties().put(
                ApacheHttpClientConfig.PROPERTY_HANDLE_COOKIES, true);
        resourceCache = new HashMap<String, String>();
    }

    public byte[] getReportAsByteArray(Report report) throws IOException,
            DocumentException {
        LOGGER.info("getReportAsByteArray for " + report);

        // "automagically" manages cookies
        ApacheHttpClient client = ApacheHttpClient.create(clientConfig);
        client.addFilter(new HTTPBasicAuthFilter(userName, password));

        String reportUrl = report.getUrl().replaceFirst("(?i)/reports",
                "/reports" + reportsDirectory);

        String describeResourcePath = "/resource" + reportUrl;
        String generateReportPath = "/report" + reportUrl
                + "?RUN_OUTPUT_FORMAT=" + report.getFormat();

        WebResource resource = null;
        String resourceResponse = null;

        if (resourceCache.containsKey(describeResourcePath)) {
            resourceResponse = resourceCache.get(describeResourcePath);
        } else {
            resource = client.resource(restEndpointUrl);
            resource.accept(MediaType.APPLICATION_XML);
            resourceResponse = resource.path(describeResourcePath).get(
                    String.class);
            resourceCache.put(describeResourcePath, resourceResponse);
        }
        Document resourceXML = parseResource(resourceResponse);

        LOGGER.info("Generating report...");
        resourceXML = addParametersToResource(resourceXML, report);
        resource = client.resource(restEndpointUrl + generateReportPath);
        resource.accept(MediaType.TEXT_XML);
        String reportResponse = resource.put(String.class,
                serializetoXML(resourceXML));

        LOGGER.info("Obtaining response...");
        try {
            String urlReport = parseReport(reportResponse);
            resource = client.resource(urlReport);
        } catch (ReportException e) {
            LOGGER.log(Level.SEVERE, "Report Exception: " + e.getMessage(), e);
            return new byte[0];
        }

        byte[] bytes = resource.get(byte[].class);
        LOGGER.info("Report received. Size="
                + (bytes != null ? bytes.length : 0));

        return bytes;
    }

    private Document parseResource(String resourceAsText)
            throws DocumentException {
        Document document;
        document = DocumentHelper.parseText(resourceAsText);
        return document;
    }

    private String parseReport(String reportResponse) throws DocumentException,
            ReportException {
        LOGGER.info("reportResponse:\n" + reportResponse);
        String urlReport = null;
        Document document = DocumentHelper.parseText(reportResponse);
        Node node = document.selectSingleNode("/report/uuid");
        String uuid = node.getText();
        node = document.selectSingleNode("/report/totalPages");
        Integer totalPages = Integer.parseInt(node.getText());
        if (totalPages == 0) {
            throw new ReportException("EMPTY_REPORT");
        }
        urlReport = this.restEndpointUrl + "/report/" + uuid + "?file=report";
        return urlReport;
    }

    private Document addParametersToResource(Document resource, Report reporte) {
        Element root = resource.getRootElement();
        Map<String, String> params = reporte.getParams();
        for (Map.Entry<String, String> entry : params.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            if (key != null && value != null) {
                root.addElement("parameter").addAttribute("name", key)
                        .addText(value);
            }
        }
        return resource;
    }

    private String serializetoXML(Document resource) throws IOException {
        OutputFormat outformat = OutputFormat.createCompactFormat();
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        outformat.setEncoding("ISO-8859-1");
        XMLWriter writer = new XMLWriter(out, outformat);
        writer.write(resource);
        writer.flush();
        return out.toString();
    }

}
