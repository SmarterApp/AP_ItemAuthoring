package com.pacificmetrics.orca.mbeans;

import java.net.URLDecoder;
import java.net.URLEncoder;

import javax.annotation.PostConstruct;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;

import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.orca.utils.PropertyUtil;

@ManagedBean(name = "ttsManager")
@ViewScoped
public class TTSManager extends AbstractManager {

    private String text = "";

    @PostConstruct
    private void load() {
        text = getParameter("text");
        if (StringUtils.isNotBlank(text)) {
            text = URLDecoder.decode(text);
        } else {
            text = "";
        }
    }

    public String getServerURL() {
        return PropertyUtil.getProperty(PropertyUtil.HTTP_SERVER_URL)
                + "/orca-sbac";
    }

    @SuppressWarnings("deprecation")
    public String getEncodedText() {
        if (StringUtils.isNotBlank(text)) {
            return URLEncoder.encode(text);
        }
        return "";
    }

    public String getText() {
        return text;
    }
}
