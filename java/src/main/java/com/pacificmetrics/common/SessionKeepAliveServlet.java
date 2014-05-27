package com.pacificmetrics.common;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * SessionKeepAliveServlet allows pages to poll to keep the client session alive while viewing a page. This is useful
 * to avoid ViewExpiredException, and the corresponding session expiration, when user clicks an action on a JSF page
 * in browser after their session (would have otherwise) expired.
 * 
 * @author dbloom
 */
public class SessionKeepAliveServlet extends HttpServlet
{ 
	private static final long serialVersionUID = 1L;

	@Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException
    {
        // keep session alive
        request.getSession(false);

        // send response okay, but no content
        response.setStatus(HttpServletResponse.SC_NO_CONTENT);
    }
}
