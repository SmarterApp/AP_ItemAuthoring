<%@ taglib uri="/spring" prefix="spring"%>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core_rt" %>

<%--Common IC constants--%>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.base.js"></script>
<%@ page import="com.jaspersoft.jasperserver.war.cascade.handlers.InputControlHandler"%>
<script type="text/javascript" language="JavaScript">
    ControlsBase.NULL_SUBSTITUTION_VALUE = "<%= InputControlHandler.NULL_SUBSTITUTION_VALUE %>";
    ControlsBase.NULL_SUBSTITUTION_LABEL = "<%= InputControlHandler.NULL_SUBSTITUTION_LABEL %>";
    ControlsBase.NOTHING_SUBSTITUTION_VALUE = "<%= InputControlHandler.NOTHING_SUBSTITUTION_VALUE %>";
</script>

<%--Template engine--%>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/mustache.js"></script>
<%--Default Templates--%>
<c:if test="${controlsDisplayForm == null or empty controlsDisplayForm}">
    <jsp:include page="InputControlTemplates.jsp" />
</c:if>

<%--URI parser--%>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/jquery/js/jquery.urldecoder.js"></script>

<%--Common IC functionality--%>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.logging.js"></script>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.core.js"></script>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.datatransfer.js"></script>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.basecontrol.js"></script>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.components.js"></script>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.viewmodel.js"></script>
<c:if test="${isPro}">
    <script type="text/javascript" language="JavaScript">
            ControlsBase.DEFAULT_OPTION_TEXT = '<spring:message code="report.options.dialog.default.name" javaScriptEscape="true"/>';
            ControlsBase.CONTROL_DEFAULT_OPTION_TEXT = '<spring:message code="report.options.select.empty.label" javaScriptEscape="true"/>';
            ControlsBase.CONTROL_OPTIONS_TEXT = '<spring:message code="report.options.select.label" javaScriptEscape="true"/>';
    </script>
    <script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.options.js"></script>
</c:if>
<script type="text/javascript" language="JavaScript" src="${pageContext.request.contextPath}/scripts/controls.controller.js"></script>