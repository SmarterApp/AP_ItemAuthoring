package com.pacificmetrics.orca.utils;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;

public class HTMLUtil {

    private HTMLUtil() {
    }

    public static String getTextOfElement(String html, String elementid) {
        Document doc = Jsoup.parse(html);
        Element parentElement = doc.getElementById(elementid);
        return parentElement != null ? parentElement.text() : "";
    }

    public static String getWordOfElement(String html, String elementid,
            int wordno) {
        String text = getTextOfElement(html, elementid);
        return removePuncuation(StringUtils.isNotBlank(text) ? text.split(" ")[wordno - 1]
                : "");
    }

    public static String getCharacterSequenceOfElement(String html,
            String elementid, int startChar, int endChar) {
        String text = getTextOfElement(html, elementid);
        return StringUtils.isNotBlank(text) ? text.substring(startChar - 1,
                endChar - 1) : "";
    }

    public static String removePuncuation(String text) {
        if (StringUtils.isNotBlank(text) && text.matches("^.*\\p{P}$")) {
            return text.replaceAll("(?!\")\\p{P}$", "").replaceAll("\\.*$", "");
        }
        return text;
    }

    public static String sanitizeHtml(String html) {
        Document doc = Jsoup.parse(html);
        Elements links = doc.select("a[href]");
        Elements media = doc.select("[src]");
        Elements imports = doc.select("link[href]");

        if (CollectionUtils.isNotEmpty(media)) {
            for (Element src : media) {
                if ("img".equals(src.tagName())
                        && StringUtils.isNotBlank(src.attr("abs:src"))
                        && src.attr("abs:src").lastIndexOf("/") != -1) {
                    String url = src.attr("abs:src");
                    String file = url.substring(url.lastIndexOf("/") + 1);
                    src.attr("src", file);
                }
            }
        }

        if (CollectionUtils.isNotEmpty(links)) {
            for (Element link : links) {
                if (StringUtils.isNotBlank(link.attr("abs:href"))) {
                    link.attr("href", "");
                }
            }
        }

        return doc
                .body()
                .html()
                .replaceAll("<\\s*(img)+((\"[^\"]*\"|[^>/])*)(?<!/)\\s*>",
                        "<$1$2></$1>");
    }

}
