package com.pacificmetrics.orca.tts;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class SoundUtil {

    private static final Log LOGGER = LogFactory.getLog(TTSUtil.class);

    private SoundUtil() {
    }

    public static void wavToMP3(String waveFileName, String mp3FileName)
            throws Exception {

        Runtime runtime = Runtime.getRuntime();

        Process proc = runtime.exec("lame -V1  --silent " + waveFileName + " "
                + mp3FileName);

        InputStream stderr = proc.getErrorStream();
        printOutput(stderr);

        InputStream stdin = proc.getInputStream();
        printOutput(stdin);

        int exitCode = proc.waitFor();

        LOGGER.info("Lame Exit Code " + exitCode);
    }

    private static void printOutput(InputStream stdout) throws IOException {
        InputStreamReader oisr = new InputStreamReader(stdout);
        BufferedReader obr = new BufferedReader(oisr);
        String oline = null;
        LOGGER.info("Lame <OUTPUT>");
        while ((oline = obr.readLine()) != null) {
            LOGGER.info(oline);
        }
        LOGGER.info("</OUTPUT>");
    }
}
