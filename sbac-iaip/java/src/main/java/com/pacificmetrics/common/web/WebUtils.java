package com.pacificmetrics.common.web;

import java.io.IOException;
import java.io.OutputStream;
import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;

import javax.faces.component.UIComponent;
import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;

public class WebUtils {

    private WebUtils() {
    }

    public static void redirect(String url) {
        try {
            FacesContext.getCurrentInstance().getExternalContext()
                    .redirect(url);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    public static void addStyle(UIComponent component, String styleToAdd) {
        String styles = (String) component.getAttributes().get("styleClass");
        if (styles != null && styles.contains(styleToAdd)) {
            return;
        }
        styles = (styles != null ? styles + " " : "") + styleToAdd;
        component.getAttributes().put("styleClass", styles);
    }

    public static void removeStyle(UIComponent component, String styleToRemove) {
        String styles = (String) component.getAttributes().get("styleClass");
        if (styles == null || !styles.contains(styleToRemove)) {
            return;
        }
        styles = styles.replaceAll(styleToRemove, "");
        component.getAttributes().put("styleClass", styles);
    }

    public static void sendFileToDownload(String fileName, byte[] bytes)
            throws IOException {
        FacesContext fc = FacesContext.getCurrentInstance();
        ExternalContext ec = fc.getExternalContext();

        ec.responseReset(); // Some JSF component library or some Filter might
                            // have set some headers in the buffer beforehand.
                            // We want to get rid of them, else it may collide.
        ec.setResponseContentType(ec.getMimeType(fileName)); // Check
                                                             // http://www.w3schools.com/media/media_mimeref.asp
                                                             // for all types.
                                                             // Use if necessary
                                                             // ExternalContext#getMimeType()
                                                             // for
                                                             // auto-detection
                                                             // based on
                                                             // filename.
        ec.setResponseContentLength(bytes.length); // Set it with the file size.
                                                   // This header is optional.
                                                   // It will work if it's
                                                   // omitted, but the download
                                                   // progress will be unknown.
        ec.setResponseHeader("Content-Disposition", "attachment; filename=\""
                + fileName + "\""); // The Save As popup magic is done here. You
                                    // can give it any file name you want, this
                                    // only won't work in MSIE, it will use
                                    // current request URL as file name instead.

        OutputStream os = ec.getResponseOutputStream();
        os.write(bytes);
        // Now you can write the InputStream of the file to the above
        // OutputStream the usual way.
        // ...

        fc.responseComplete();
    }

    public static String encodeURL(String url) {
        try {
            return URLEncoder.encode(url, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

}
