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

Usage:

	<t:insertTemplate template="/WEB-INF/jsp/templates/exportControls.jsp">
	     //some selectore to controls container
	    <t:putAttribute name="containerID" value=""/>
	     //detalization of displayed functionality, could be 'short' or 'extended'
	     // 'short' provide functions for resource export only
	     // 'extended'  adds user/roles and events export function
	    <t:putAttribute name="detalization" value=""/>
	</t:insertTemplate>
	
--%>

<%@ taglib uri="http://tiles.apache.org/tags-tiles" prefix="t" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core_rt" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<t:useAttribute id="containerID" name="containerID" classname="java.lang.String" ignore="true"/>
<t:useAttribute id="typeID" name="typeID" classname="java.lang.String" ignore="true"/>

<%--Jasper's components templates--%>
<jsp:include page="componentsTemplates.jsp"/>

<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/controls.logging.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/json2.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.backbone.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/mustache.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.templateengine.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.utils.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.servererrorsbackbonetrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.ajaxdownloader.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.notificationviewtrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.systemnotificationview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.state.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.js"></script>

<%--i18n--%>
<script type="text/javascript">

    (function (Export) {

        Export.i18n = {
            "file.name.empty": '<spring:message code="export.file.name.empty"/>',
            "file.name.too.long": '<spring:message code="export.file.name.too.long"/>',
            "file.name.not.valid": '<spring:message code="export.file.name.not.valid"/>',
            "export.select.users":'<spring:message code="export.select.users"/>',
            "export.select.roles":'<spring:message code="export.select.roles"/>',
            "error.invalid.response" : '<spring:message code="error.invalid.response"/>',
            "error.invalid.request" : '<spring:message code="error.invalid.request"/>',
            "error.timeout" : '<spring:message code="error.timeout"/>',
            "export.session.expired" : '<spring:message code="export.session.expired"/>',
            "export.server.not.avaliable" : '<spring:message code="export.server.not.avaliable"/>'
        };
        //TODO: move from JRS to jaspersoft namespace
        _.extend(jaspersoft.i18n, Export.i18n);

    })(
            JRS.Export
    );
</script>

<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.servererrortrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.stateview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.statecontrollertrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.statecontroller.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.authoritymodel.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.authoritypickerview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.formmodel.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.extendedformview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.shortformview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.dialog.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.layout.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.app.js"></script>

<%--Export's Templates--%>
<jsp:include page="exportTemplates.jsp" />

<%--Initialization--%>
<script type="text/javascript">
    JRS.Export.App.initialize({container: "${containerID}",type : "${typeID}", modal: !"${containerID}"});
</script>
