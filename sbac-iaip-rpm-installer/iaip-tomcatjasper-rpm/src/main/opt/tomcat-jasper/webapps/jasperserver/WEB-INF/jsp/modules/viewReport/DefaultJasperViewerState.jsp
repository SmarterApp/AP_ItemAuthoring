<%--
  ~ Copyright (C) 2005 - 2011 Jaspersoft Corporation. All rights reserved.
  ~ http://www.jaspersoft.com.
  ~
  ~ Unless you have purchased  a commercial license agreement from Jaspersoft,
  ~ the following license terms  apply:
  ~
  ~ This program is free software: you can redistribute it and/or  modify
  ~ it under the terms of the GNU Affero General Public License  as
  ~ published by the Free Software Foundation, either version 3 of  the
  ~ License, or (at your option) any later version.
  ~
  ~ This program is distributed in the hope that it will be useful,
  ~ but WITHOUT ANY WARRANTY; without even the implied warranty of
  ~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  ~ GNU Affero  General Public License for more details.
  ~
  ~ You should have received a copy of the GNU Affero General Public  License
  ~ along with this program. If not, see <http://www.gnu.org/licenses/>.
  --%>

<%--
 This code formers proper script and passes it for evaluation on client side.
 It fixes all pagination issues, exporters issues in all browsers including IE.
--%>

<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core_rt" %>

<%@ page import="net.sf.jasperreports.engine.export.*" %>
<%@ page import="net.sf.jasperreports.engine.*" %>
<%@ page import="com.jaspersoft.jasperserver.war.action.ExporterConfigurationBean" %>
<%@ page import="com.jaspersoft.jasperserver.api.metadata.jasperreports.domain.ReportUnit" %>
<%@ page import="org.springframework.context.MessageSource" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Map" %>
<%@ page import="com.jaspersoft.jasperserver.war.action.GenericActionModelBuilder" %>
<%@ page import="org.springframework.web.util.JavaScriptUtils" %>

<%-- TODO how about moving export menu items into actionModel-viewReport.xml? generatedOptions can be used there --%>
<%
  StringBuilder script = new StringBuilder();
  script.append("Report.jasperPrintName = '" + request.getAttribute("jasperPrintName") + "';");
  script.append("Report.pageIndex = " + request.getAttribute("pageIndex") + " + 0;");
  Integer lastPageIndex = (Integer) request.getAttribute("lastPageIndex");
  script.append("Report.lastPageIndex = " + (lastPageIndex == null ? "null" : (lastPageIndex + " + 0")) + ";");
  Integer lastPartialPageIndex = (Integer) request.getAttribute("lastPartialPageIndex");
  script.append("Report.lastPartialPageIndex = " + (lastPartialPageIndex == null ? "null" : (lastPartialPageIndex + " + 0")) + ";");
  Long pageTimestamp = (Long) request.getAttribute("pageTimestamp");
  script.append("Report.pageTimestamp = " + (pageTimestamp == null ? "null" : (pageTimestamp + " + 0")) + ";");
  String snapshotSaveStatus = (String) request.getAttribute("snapshotSaveStatus");
  script.append("Report.snapshotSaveStatus = '" + snapshotSaveStatus + "';");
  script.append("Report.flowExecutionKeyOutput = \"" + request.getAttribute("flowExecutionKey") + "\";");
  Boolean isEmptyReport = (Boolean) request.getAttribute("emptyReport");
  script.append("Report.emptyReport = " + isEmptyReport + ";");
  script.append("Report.hasInputControls = " + request.getAttribute("hasInputControls") + ";");
  
  MessageSource messageSource = (MessageSource) request.getAttribute("messageSource");
  
  Date dataSnapshotDate = (Date) request.getAttribute("dataTimestamp");
  if (dataSnapshotDate != null) {
  	script.append("Report.dataTimestampMessage = '" 
  		+ JavaScriptUtils.javaScriptEscape(messageSource.getMessage("jasper.report.view.data.snapshot.message", 
  			new Object[]{dataSnapshotDate}, request.getLocale()))
  		+ "';");
  }

  script.append("Report.exportersList = [];");
  if (!isEmptyReport) {
     Map configuredExporters = (Map) request.getAttribute("configuredExporters");
     for (Object configuredExporterEntry: configuredExporters.entrySet()) {
        Map.Entry configuredExporter = (Map.Entry) configuredExporterEntry;
        ExporterConfigurationBean exporter = (ExporterConfigurationBean) configuredExporter.getValue();
        String exporterKey = (String) configuredExporter.getKey();
        ReportUnit reportUnit = (ReportUnit) request.getAttribute("reportUnitObject");
        String exportFilename = null;
        if (exporter.getCurrentExporter() != null && reportUnit != null) {
            exportFilename = exporter.getCurrentExporter().getDownloadFilename(
            request, reportUnit.getName());
        }

        pageContext.setAttribute("exportFilename", exportFilename);

        String descriptionKey = (String) pageContext.getAttribute("exporterDescriptionKey");
        String descriptionMessage = messageSource.getMessage(exporter.getDescriptionKey(), null, request.getLocale());
        script.append("Report.exportersList.push('{\"type\": \"simpleAction\",\"text\":");
        script.append("\"" + descriptionMessage + "\"");
        script.append(",\"action\": \"Report.exportReport\",");
        script.append("\"actionArgs\": [\"" +  exporterKey + "\"");

        %>
        <c:if test="${not empty exportFilename}">
            <c:set var="exportFilenameUrl"><c:url value="flow.html/flowFile/${exportFilename}"/></c:set>
            <%
                script.append(", \""+ pageContext.getAttribute("exportFilenameUrl") + "\"");
            %>
        </c:if>
        <%
        script.append("]}');");
     }
  }

  pageContext.setAttribute("evalScript", script.toString());
%>

<textarea class="hidden" style="display:none" name="_evalScript">${evalScript}</textarea>

<%--
Insert script for export menu elements:

<script type="text/javascript" id="toolbarText">
    '{"toolbar_export":[' + Report.exportersList.join(",") + ']}'
</script>
--%>
<textarea class="hidden" style="display:none" name="_evalScript">
<%=
    "var scriptTag = Builder.node(\"script\", {type: \"text/javascript\", id: \"toolbarText\"});\r\n" +
    "scriptTag.text = '\\\'{\"toolbar_export\":[\\\' + Report.exportersList.join(\",\") + \\\'], "+
            GenericActionModelBuilder.getEmbeddableActionModelDocument("viewReport") +
            "}\\\'';\r\n" +
    "$('reportContainer').insert(scriptTag);"
%>
</textarea>
