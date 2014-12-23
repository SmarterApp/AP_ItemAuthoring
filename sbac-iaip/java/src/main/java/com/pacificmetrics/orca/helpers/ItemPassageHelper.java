package com.pacificmetrics.orca.helpers;

import java.io.File;
import java.io.IOException;

import org.apache.commons.io.FileUtils;

import com.pacificmetrics.orca.ServerConfiguration;

public class ItemPassageHelper {

    private ItemPassageHelper() {
    }

    static public String readPassageContentFromFile(String path)
            throws IOException {
        String fullPath = ServerConfiguration
                .getProperty(ServerConfiguration.PASSAGES_DIRECTORY) + path;
        File file = new File(fullPath);
        String content = FileUtils.readFileToString(file);
        content = fixImageSource(content);
        content = fixHref(content);
        return content;
    }

    static public String fixHref(String text) {
        return text
                .replaceAll(
                        "href=\"/"
                                + ServerConfiguration
                                        .getProperty(ServerConfiguration.APPLICATION_NAME),
                        "href=\""
                                + ServerConfiguration
                                        .getProperty(ServerConfiguration.HTTP_SERVER_ROOT_URL));
    }

    static public String fixImageSource(String text) {
        return text
                .replaceAll(
                        "src=\"/"
                                + ServerConfiguration
                                        .getProperty(ServerConfiguration.APPLICATION_NAME),
                        "src=\""
                                + ServerConfiguration
                                        .getProperty(ServerConfiguration.HTTP_SERVER_ROOT_URL));
    }

    static public String fixPath(String path) {
        return path
                .replace(
                        "/"
                                + ServerConfiguration
                                        .getProperty(ServerConfiguration.APPLICATION_NAME),
                        ServerConfiguration
                                .getProperty(ServerConfiguration.HTTP_SERVER_ROOT_URL));
    }

}
