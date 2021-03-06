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
~ License, or (at your step) any later version.
~
~ This program is distributed in the hope that it will be useful,
~ but WITHOUT ANY WARRANTY; without even the implied warranty of
~ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
~ GNU Affero  General Public License for more details.
~
~ You should have received a copy of the GNU Affero General Public  License
~ along with this program. If not, see <http://www.gnu.org/licenses/>.
--%>

<%@ page import="java.io.*"%>
<%@ page import="org.apache.commons.logging.*"%>
<%@ page language="java" isErrorPage="true" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ page import="com.jaspersoft.jasperserver.api.JSException"%>
<%@ page import="org.springframework.security.AccessDeniedException"%>
<%@ page import="org.springframework.webflow.conversation.NoSuchConversationException"%>
<%@ page import="com.jaspersoft.jasperserver.war.action.ReportCanceledException" %>
<%@ page import="com.jaspersoft.jasperserver.api.JSShowOnlyErrorMessage" %>
<%@ page import="com.jaspersoft.jasperserver.api.JSSecurityException" %>
<%@ page import="org.apache.commons.lang.exception.ExceptionUtils" %>
<%@ taglib prefix="t" uri="http://tiles.apache.org/tags-tiles" %>
<%@ taglib prefix="spring" uri="http://www.springframework.org/tags" %>

<t:insertTemplate template="/WEB-INF/jsp/templates/page.jsp">
    <t:putAttribute name="pageTitle"><spring:message code="jsp.JSErrorPage.title"/></t:putAttribute>
    <t:putAttribute name="bodyID" value="serverError"/>
    <t:putAttribute name="bodyClass" value="oneColumn flow"/>
    <t:putAttribute name="bodyContent">
		<t:insertTemplate template="/WEB-INF/jsp/templates/container.jsp">
			<t:putAttribute name="containerClass" value="column decorated primary"/>
		    <t:putAttribute name="containerTitle"><spring:message code="jsp.JSErrorPage.error"/></t:putAttribute>
		    <t:putAttribute name="bodyID" value="errorPageContent"/>
		    <t:putAttribute name="bodyContent">
                <%
                    response.setHeader("JasperServerError", "true");
                    Log log = LogFactory.getLog(this.getClass());
                    Throwable ex;

                    if (exception == null) {
                        ex = request.getAttribute("flowExecutionException") != null ? (Exception) request.getAttribute("flowExecutionException") : (Exception) request.getAttribute("exception"); //from controllers or swf action
                    } else {
                        ex = exception;
                    }

                    if (ex != null
                            && !(ex instanceof JSException || ex instanceof AccessDeniedException || ex instanceof NoSuchConversationException)
                            && ex.getCause() != null) {

                        /* Get rid of ActionExecutionException */
                        ex = ex.getCause();

                        /* Look for JSSecurityException up to the root cause */
                        int index = ExceptionUtils.indexOfThrowable(ex, JSSecurityException.class);
                        if (index > -1) {
                            ex = (JSSecurityException) ExceptionUtils.getThrowableList(ex).get(index);
                        }
                    }

                    if (ex != null && ex instanceof ReportCanceledException) {
                        response.setHeader("SuppressError", "true");
                    }
                %>

				<% 	// JSExceptions have a formatted and localized message which can potentially have args in it
					if (exception instanceof JSException) { %>
				     <c:set var="jsExceptionMessage" scope="request"><spring:message code="${exception.message}" arguments="${exception.args}"/></c:set>
				<%		log.error("JSException: " + request.getAttribute("jsExceptionMessage"));
					} %>
					
				<div id="stepDisplay">
                    <c:if test="${not empty flowExecutionKey}">
                        <input type="hidden" name="_flowExecutionKey" value="${flowExecutionKey}"/>
                    </c:if>
                    <c:if test="${not empty param.parentFlow}">
                        <input type="hidden" name="_flowId" value="${param.parentFlow}"/>
                    </c:if>
                    <c:if test="${empty param.parentFlow}">
                        <input type="hidden" name="_flowId" value="${flowId}"/>
                    </c:if>

                    <%  if(!(ex instanceof NoSuchConversationException)) { %>   <!-- BUG 10599 -->
                      <c:if test="${not (conditionallyDisableBackButton and flowExecutionContext.activeSession.root and empty flowScope.prevForm)}">
                        <%--<input type="submit" id="errorBack" name="_eventId_backFromErrorPage" class="fnormal" value="<spring:message code='button.back'/>"/>--%>
                      </c:if>
                    <%  }  %>

                        <c:set var="showOnlyErrorMessage" value="${false}"/>
                    <%  if ((ex instanceof JSShowOnlyErrorMessage)
                            || (ex != null && ex.getCause() != null &&  (ex.getCause() instanceof JSShowOnlyErrorMessage))) { %>
                        <c:set var="showOnlyErrorMessage" value="${true}"/>
                    <%  }  %>

                        <c:set var="securityException" value="${false}"/>
                    <%  if ((ex instanceof JSSecurityException)
                            || (ex != null && ex.getCause() != null &&  (ex.getCause() instanceof JSShowOnlyErrorMessage))) { %>
                            <c:set var="securityException" value="${true}"/>
                    <%  } %>

                    <c:choose>
                        <c:when test="${securityException}">
                            <%
                                pageContext.setAttribute("exceptionMessage", ex.getMessage());
                                pageContext.setAttribute("exceptionArgs", ((JSException) ex).getArgs());
                            %>
                            <p id="clarification" class="message">
                            	<spring:message code="${exceptionMessage}" arguments="${exceptionArgs}"/>
                            </p>
                        </c:when>
                        <c:when test="${showOnlyErrorMessage}">
                            <%
                                pageContext.setAttribute("exceptionMessage", ex.getMessage());
                                pageContext.setAttribute("exceptionArgs", ((JSException) ex).getArgs());
                            %>
                            <%--<h2 id="interjection" class="textAccent02"><%= interjections[pickOne] %></h2>--%>
                            <p id="clarification" class="message">
                            	<spring:message code="${exceptionMessage}" arguments="${exceptionArgs}"/>
                            </p>
                        </c:when>
                        <c:otherwise>
                            <fieldset class="row instructions">
                                <h3 id="clarification"><spring:message code="jsp.JSErrorPage.sorry"/></h3>
                            </fieldset>

                            <fieldset class="row inputs oneColumn">
                                <t:insertTemplate template="/WEB-INF/jsp/templates/container.jsp">
                                    <t:putAttribute name="containerClass" value="column noHeader primary"/>

                                    <t:putAttribute name="bodyContent">
                                        <%-- stackTrace --%>
                                        <%
                                        	if(session.getAttribute("stacktrace") != null){
                                        		pageContext.setAttribute("exceptionStackTrace", session.getAttribute("stacktrace"));
                                       	%>	                                            
	                                            <c:if test="${isIPad}"><div class="swipeScroll" style="height:480px;overflow:hidden;border-top:solid 1px #ccc;padding-top:12px;"></c:if>                                           
		                                            <div id="completeStackTrace" style="padding-bottom:350px;">
		                                                <h3><spring:message code="message.validation.input"/></h3>
		                                            </div>
	                                            <c:if test="${isIPad}"></div></c:if>
                                        <%
                                        	} else {
	                                            Throwable e = ex;
	                                            log.error("stack trace of exception that redirected to errorPage.jsp", e);
	                                            while (e != null) {
	                                                pageContext.setAttribute("exceptionMessage", e.toString());
	                                                StringWriter stackTraceWriter = new StringWriter();
	                                                e.printStackTrace(new PrintWriter(stackTraceWriter));
	                                                pageContext.setAttribute("exceptionStackTrace", stackTraceWriter.getBuffer());
                                        %>
	                                            <div id="errorMessages">
	                                                <h3><spring:message code="jsp.JSErrorPage.errorMsg"/></h3>
	                                                <p class="large"><c:out value="${exceptionMessage}"/></p>
	                                            </div>
	                                            
	                                            <c:if test="${isIPad}"><div class="swipeScroll" style="height:480px;overflow:hidden;border-top:solid 1px #ccc;padding-top:12px;"></c:if>                                           
		                                            <div id="completeStackTrace" style="padding-bottom:350px;">
		                                                <h3><spring:message code="jsp.JSErrorPage.errorTrace"/></h3>
		                                                <p style="white-space:normal;"><c:out value="${exceptionStackTrace}"/></p>
		                                            </div>
	                                            <c:if test="${isIPad}"></div></c:if>
                                        <%
	                                            Throwable prev = e;
	                                            e = e.getCause();
	                                            if (e == prev)
	                                                break;
	                                            }
                                        	}
                                        %>
                                    </t:putAttribute>
                                </t:insertTemplate>
                            </fieldset><!--/.row.inputs-->
                        </c:otherwise>
                    </c:choose>
				</div><!--/#stepDisplay-->
			</t:putAttribute>
		</t:insertTemplate>
    </t:putAttribute>
</t:insertTemplate>

		
