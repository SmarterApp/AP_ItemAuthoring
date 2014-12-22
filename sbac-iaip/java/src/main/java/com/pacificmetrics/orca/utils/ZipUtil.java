package com.pacificmetrics.orca.utils;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.zip.ZipEntry;
import java.util.zip.ZipException;
import java.util.zip.ZipInputStream;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

public class ZipUtil {

    private static final Log LOGGER = LogFactory.getLog(ZipUtil.class);

    private ZipUtil() {
    }

    public static void unzipPackage(InputStream inputStream,
            String outputZipFolder) {
        ZipInputStream zipInputStream = null;
        try {
            zipInputStream = new ZipInputStream(inputStream);
            byte[] buffer = new byte[1024];
            ZipEntry zipEntry = null;

            // create output directory is not exists
            FileUtil.createDir(outputZipFolder);

            while ((zipEntry = zipInputStream.getNextEntry()) != null) {
                File newFile = new File(outputZipFolder + File.separator
                        + zipEntry.getName());
                if (zipEntry.isDirectory()) {
                    LOGGER.debug("Extracting directory: " + zipEntry.getName());
                    newFile.mkdir();
                } else {
                    LOGGER.debug("Extracting file: " + zipEntry.getName());
                    FileUtil.createFile(newFile);
                    FileOutputStream fos = new FileOutputStream(newFile);

                    int len;
                    while ((len = zipInputStream.read(buffer)) > 0) {
                        fos.write(buffer, 0, len);
                    }
                    fos.close();
                }
                zipInputStream.closeEntry();
            }
            zipInputStream.close();

            LOGGER.debug("Complete Zip extract at path " + outputZipFolder);

        } catch (ZipException e) {
            LOGGER.error("Unable to read zip package " + e);
        } catch (IOException e) {
            LOGGER.error("Unable to read zip package " + e);
        } finally {
            if (zipInputStream != null) {
                try {
                    zipInputStream.close();
                } catch (IOException e) {
                    LOGGER.error("Unable to close zip package stream " + e);
                }
            }
        }
    }
}
