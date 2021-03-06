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

<%@ include file="../jsp/modules/common/jsEdition.jsp" %>

<meta name = "viewport" content="user-scalable=no, initial-scale=1.0, maximum-scale=1.0, width=device-width">
<meta name="apple-mobile-web-app-capable" content="yes"/>

<%-- JavaScript and CSS resources that are common to all or most pages, doesn't include decorations-related code --%>

<c:choose>
    <c:when test="${param['nui'] == 1}">
        <%@include file="designerMinimalImports.jsp"%>
    </c:when>
    <c:otherwise>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/themes/reset.css" type="text/css" media="screen">

        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="theme.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="pages.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="containers.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="buttons.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="lists.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="controls.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="dataDisplays.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="pageSpecific.css"/>" type="text/css" media="screen,print"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="dialogSpecific.css"/>" type="text/css" media="screen,print"/>

        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="forPrint.css"/>" type="text/css" media="print"/>

        <!--[if IE 7.0]>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="overrides_ie7.css"/>" type="text/css" media="screen"/>
        <![endif]-->

        <!--[if IE 8.0]>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="overrides_ie8.css"/>" type="text/css" media="screen"/>
        <![endif]-->

        <!--[if IE]>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="overrides_ie.css"/>" type="text/css" media="screen"/>
        <![endif]-->
        <link rel="stylesheet" href="${pageContext.request.contextPath}/<spring:theme code="overrides_custom.css"/>" type="text/css" media="screen"/>
        <link rel="stylesheet" href="${pageContext.request.contextPath}/scripts/jquery/theme/redmond/jquery-ui-1.8.20.custom.css" type="text/css" media="screen">
    </c:otherwise>
</c:choose>

<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.prototype${isIPad ? '.touch' : ''}.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/jquery/js/jquery-1.7.1.min.js"></script>
<script type='text/javascript' src="${pageContext.request.contextPath}/scripts/jquery/js/jquery-ui-1.8.20.custom.min.js"></script>
<script type='text/javascript' src="${pageContext.request.contextPath}/scripts/jquery/js/jquery-ui-timepicker-addon.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.underscore.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.underscore.string.js"></script>
<script type="text/javascript">
	jQuery.noConflict();
	/*
	 * JasperServer namespace.
	 */
	var JRS = {
		vars: {
			element_scrolled: false,
			ajax_in_progress: false,
			current_flow: null,
            contextPath: "${pageContext.request.contextPath}"
		},
        i18n : {}
	};

    var jaspersoft = {

        components: {},
        i18n: {}

    };

    var Calendar = {};
    /*
     * Javascript heartbeat performance monitor
     */
    var hb;
    jQuery(function(){
        hb = jQuery('#hb');
        //setInterval('checkHeartBeat()',100);
    });
    var lastime = 0;
    function checkHeartBeat() {
        var time = (new Date).getTime();
        var diff = time - lastime;
        lastime = time;
        hb.html(diff);
    }
</script>

<%--Caleandar Picker--%>
<jsp:include page="/cal/calendar.jsp" flush="true"/>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.nwmatcher.js"></script>

<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.scriptaculous.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.dragdrop.extra.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/ext.utils.touch.controller.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/utils.common.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/utils.animation.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.layout.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.events.bis.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.key.events.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.edition.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.ajax.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/tools.drag.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/tools.truncator.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/actionModel.modelGenerator.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/actionModel.primaryNavigation.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.customTooltip.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.tooltip.js"></script>


<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/components.toolbarButtons.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/components.toolbarButtons.events.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/components.searchBox.js'></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.dialogs.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.pickers.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.webHelp.js"></script>


<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/list.base.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/tree.nanotree.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/tree.events.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/tree.treenode.js'></script>
<script type="text/javascript" src='${pageContext.request.contextPath}/scripts/tree.treesupport.js'></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/tree.utils.js"></script>


<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/core.initialize.js"></script>
<script type="text/javascript" src="${pageContext.request.contextPath}/scripts/components.heartbeat.js"></script>

<c:if test="${isProVersion}">
    <script type="text/javascript" src='${pageContext.request.contextPath}/scripts/dialog.definitions.js'></script>
    <script type="text/javascript" src='${pageContext.request.contextPath}/scripts/create.report.js'></script>
    <script type="text/javascript">
        JRS.CreateReport.messages = {
            advNotSelected: "<spring:message code="ADH_162_NULL_SAVE_REPORT_SOURCE" javaScriptEscape="true"/>"
        }
        JRS.organizationId = '<c:out value="${commonProperties.organizationId}"/>';
        JRS.publicFolderUri = '<c:out value="${commonProperties.publicFolderUri}"/>';

    </script>
</c:if>