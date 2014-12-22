package com.pacificmetrics.orca.loader.saaif;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FilenameFilter;
import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.ws.rs.core.MediaType;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.codehaus.jettison.json.JSONObject;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.utils.CertUtil;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.UniformInterfaceException;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.multipart.FormDataBodyPart;
import com.sun.jersey.multipart.FormDataMultiPart;

@Stateless
public class SAAIFFTPImporter {

    private static final Logger LOGGER = Logger
            .getLogger(SAAIFFTPScheduler.class.getName());

    private static final String SUCCESS_CODE = "0";

    @EJB
    ContentMoveServices contentMoveService;

    public void importFromFTP(String source) {
        String logPath = PropertyUtil.getProperty(PropertyUtil.FTP_LOG_PATH)
                + "content-import-monitor.log";
        FileHandler schedulerLogHandler = startLogToFile(logPath);

        LOGGER.info("Started SAAIFFTPImporter on " + new Date());
        List<ItemBank> itemBankList = contentMoveService
                .findItemBanksWithImporters();
        if (CollectionUtils.isNotEmpty(itemBankList)) {
            LOGGER.info("Found item banks with importer " + itemBankList.size());
            for (ItemBank itemBank : itemBankList) {
                if (itemBank.getUser() == null) {
                    continue;
                }
                String userPath = itemBank.getUser().getUserName();
                String zipPath = PropertyUtil
                        .getProperty(PropertyUtil.FTP_IMPORT_UPLOAD);
                String securePath = source + File.separator + userPath
                        + File.separator + zipPath;

                LOGGER.info("Searching pacakge files from importer folder "
                        + securePath);

                List<File> zipFiles = listFilesFromPath(securePath);

                if (CollectionUtils.isNotEmpty(zipFiles)) {
                    LOGGER.info("Found package files for import "
                            + zipFiles.size());
                    for (File zipFile : zipFiles) {
                        LOGGER.info("Archiving package file "
                                + zipFile.getName());
                        archiveImportPackage(itemBank.getId(),
                                zipFile.getAbsolutePath(), zipFile.getName());

                        LOGGER.info("Importing package file "
                                + zipFile.getName());
                        invokeImportService(itemBank.getId(),
                                itemBank.getUser(), zipFile.getName(), zipFile);

                        LOGGER.info("Removing package file "
                                + zipFile.getName());
                        removeImportPackage(zipFile.getAbsolutePath());
                    }
                }
            }
        }

        LOGGER.info("Completed SAAIFFTPImporter execution on " + new Date());

        endLogToFile(schedulerLogHandler);
    }

    private void archiveImportPackage(Integer itemBankId, String sourcePath,
            String fileName) {
        try {
            String archivePath = PropertyUtil
                    .getProperty(PropertyUtil.FTP_IMPORT_ARCHIVE);
            String libPath = PropertyUtil
                    .getProperty(PropertyUtil.FTP_IMPORT_LIB)
                    + itemBankId.toString();
            String uploadPath = PropertyUtil
                    .getProperty(PropertyUtil.FTP_IMPORT_UPLOAD);
            String detinationPath = archivePath + File.separator + libPath
                    + File.separator + uploadPath + File.separator + fileName;

            FileUtil.createDir(archivePath + File.separator + libPath);
            FileUtil.createDir(archivePath + File.separator + libPath
                    + File.separator + uploadPath);

            File sourceFile = new File(sourcePath);
            File destinationFile = new File(detinationPath);

            LOGGER.info("Archiving from the source path "
                    + sourceFile.getAbsolutePath() + " to "
                    + destinationFile.getAbsolutePath());

            FileUtils.copyFile(sourceFile, destinationFile);

            LOGGER.info("Complete archiving from the source path "
                    + sourceFile.getAbsolutePath() + " to "
                    + destinationFile.getAbsolutePath());
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to archive package to destination " + fileName
                            + " " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to archive package to destination " + fileName
                            + " " + e.getMessage(), e);
        }
    }

    private boolean removeImportPackage(String sourcePath) {
        File packageFile = new File(sourcePath);
        LOGGER.info("Removing package from the source path "
                + packageFile.getAbsolutePath());
        return FileUtils.deleteQuietly(packageFile);
    }

    private void invokeImportService(Integer itemBankId, User user,
            String fileName, File uploadedFile) {
        FileHandler fileHandler = null;
        try {
            String logPath = PropertyUtil
                    .getProperty(PropertyUtil.FTP_LOG_PATH);
            String logFilePath = logPath + fileName.replace(".zip", ".log");

            fileHandler = startLogToFile(logFilePath);

            final String serverUrl = PropertyUtil
                    .getProperty(PropertyUtil.HTTP_SERVER_URL);
            String webServiceUrl = serverUrl
                    + "/orca-sbac/service/import/importItmPkg";

            FormDataMultiPart form = new FormDataMultiPart();

            form.bodyPart(new FormDataBodyPart("program",
                    itemBankId != null ? itemBankId.toString() : "0"));
            form.bodyPart(new FormDataBodyPart("user", Integer.toString(user
                    .getId())));
            // Default Import Type
            form.bodyPart(new FormDataBodyPart("moveType", "1"));
            form.bodyPart(new FormDataBodyPart("fileName", fileName));
            // Default SBAIF package
            form.bodyPart(new FormDataBodyPart("itemPkgFormat", "2"));

            FormDataBodyPart formDataBodyPart = new FormDataBodyPart("file",
                    new ByteArrayInputStream(FileUtils
                            .readFileToByteArray(uploadedFile)),
                    MediaType.APPLICATION_OCTET_STREAM_TYPE);
            form.bodyPart(formDataBodyPart);

            LOGGER.info("Calling Restful server at url : " + webServiceUrl);

            LOGGER.info("With parameters program : " + itemBankId != null ? itemBankId
                    .toString() : "0" + " user : "
                    + Integer.toString(user.getId())
                    + " moveType : 1  fileName : " + fileName
                    + " itemPkgFormat : 2");

            WebResource resource = Client.create(
                    CertUtil.getAllTrustingClientConfig()).resource(
                    webServiceUrl);
            String response = resource.type(MediaType.MULTIPART_FORM_DATA)
                    .post(String.class, form);

            JSONObject jsonResponse = new JSONObject(response);
            String responseCode = jsonResponse.getString("importStatusCode");

            LOGGER.info("Response received from service " + response);

            if (!SUCCESS_CODE.equals(responseCode)) {
                LOGGER.info("Package import failed with error "
                        + jsonResponse.getString("importStatusMsg"));
            } else {
                LOGGER.info("Completed package import for file " + fileName);
            }
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.SEVERE,
                    "package import failed with error " + e.getMessage(), e);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.SEVERE,
                    "package import failed with error " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "package import failed with error " + e.getMessage(), e);
        }
        endLogToFile(fileHandler);
    }

    private List<File> listFilesFromPath(String path) {
        File zipDir = new File(path);
        if (zipDir.exists() && zipDir.isDirectory()) {
            return Arrays.asList(zipDir.listFiles(new ZipFileNameFilter()));
        }
        return Collections.<File> emptyList();
    }

    private FileHandler startLogToFile(String logFilePath) {
        try {
            FileUtil.createFile(logFilePath);
            FileHandler fileHandler = new FileHandler(logFilePath, true);
            LOGGER.addHandler(fileHandler);
            SimpleFormatter formatter = new SimpleFormatter();
            fileHandler.setFormatter(formatter);
            return fileHandler;
        } catch (SecurityException e) {
            LOGGER.log(Level.SEVERE,
                    "Security Error in logging to file : " + e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.SEVERE,
                    "IO Error in logging to file : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in logging to file : " + e.getMessage(), e);
        }
        return null;
    }

    private void endLogToFile(FileHandler fileHandler) {
        try {
            LOGGER.removeHandler(fileHandler);

        } catch (SecurityException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Security Error in ending logging to file : "
                            + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in ending logging to file : " + e.getMessage(), e);
        }
    }

    class ZipFileNameFilter implements FilenameFilter {

        @Override
        public boolean accept(File dir, String name) {
            if (name == null) {
                return false;
            }
            return name.toLowerCase().endsWith(".zip");
        }
    }

}
