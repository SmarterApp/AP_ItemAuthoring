package com.pacificmetrics.orca.loader.saaif;

import java.io.File;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.passage1.PassageType;
import com.pacificmetrics.saaif.passage1.PassagereleaseType;

public class SAAIFPassageReader {

    private static final Log LOGGER = LogFactory
            .getLog(SAAIFPassageReader.class);

    private SAAIFPassageReader() {
    }

    public static PassageType readPassage(String filePath) {
        try {
            String itemContent = FileUtil
                    .readXMLFileWithoutDeclaration(new File(filePath));
            PassagereleaseType itemRelease = JAXBUtil
                    .<PassagereleaseType> unmershall(itemContent,
                            PassagereleaseType.class);
            if (itemRelease != null) {
                return itemRelease.getPassage();
            }
            return null;
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to read the passage from the file " + filePath, e);
            return null;
        }
    }

    public static PassageType readePassageFromString(String passageContent) {
        try {
            PassagereleaseType itemRelease = JAXBUtil
                    .<PassagereleaseType> unmershall(passageContent,
                            PassagereleaseType.class);
            if (itemRelease != null) {
                return itemRelease.getPassage();
            }
            return null;
        } catch (Exception e) {
            LOGGER.error("Unable to read the passage from the content "
                    + passageContent, e);
            return null;
        }
    }

    public static String savePassageHtml(String fileName, String htmlContent,
            int itemBankId) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File passagesDir = new File(instanceDir, "passages");
            FileUtil.createDir(passagesDir);

            File libDir = new File(passagesDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File htmlFile = new File(libDir, fileName);
            if (!htmlFile.exists()) {
                StringBuilder contentBuffer = new StringBuilder();
                contentBuffer.append("<!DOCTYPE HTML>");
                contentBuffer.append("<html>");
                contentBuffer.append("<body>");
                contentBuffer.append(htmlContent);
                contentBuffer.append("</body>");
                contentBuffer.append("</html>");
                FileUtil.writeToFile(contentBuffer.toString(),
                        htmlFile.getAbsolutePath(), false);
            }
            return htmlFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to write to the passage html to file "
                    + fileName, e);
            return null;
        }
    }

    public static String savePassageAsset(String sourcePath, String fileName,
            int itemBankId, String passageName) {
        try {
            File baseDir = new File("/www/cde_resources");
            File instanceDir = new File(baseDir, "cdesbac");
            File passagesDir = new File(instanceDir, "passages");
            FileUtil.createDir(passagesDir);

            File libDir = new File(passagesDir, "lib" + itemBankId);
            FileUtil.createDir(libDir);

            File passageDir = new File(libDir, passageName);
            FileUtil.createDir(passageDir);

            File resourceFile = new File(passageDir, fileName);
            if (!resourceFile.exists()) {

                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save the passage asset " + fileName, e);
            return null;
        }
    }
}
