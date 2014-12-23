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

<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.backbone.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/mustache.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.servererrorsbackbonetrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.utils.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.templateengine.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.utils.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.notificationviewtrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.systemnotificationview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.ajaxuploader.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.state.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.statecontrollertrait.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/export.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.layout.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.stateview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/import.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/import.formmodel.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/import.extendedformview.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/import.app.js"></script>

<%--Templates--%>
<jsp:include page="importTemplates.jsp" />
<jsp:include page="componentsTemplates.jsp" />

<%--i18n--%>
<script type="text/javascript">

    (function (Import) {

        Import.i18n = {
            "unexpected.error": '<spring:message code="jsexception.unable.to.complete.request"/>',
            "error.timeout" : '<spring:message code="error.timeout"/>',
            "error.invalid.response" : '<spring:message code="error.invalid.response"/>'
        };

        _.extend(jaspersoft.i18n, Import.i18n);

    })(
            JRS.Import
    );
</script>

<%--Initialization of import app--%>

<script type="text/javascript">
    JRS.Import.App.initialize({container: "${containerID}",type : "${typeID}", namespace:JRS.Import});
</script>