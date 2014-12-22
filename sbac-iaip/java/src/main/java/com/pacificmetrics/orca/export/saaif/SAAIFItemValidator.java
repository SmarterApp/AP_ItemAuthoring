package com.pacificmetrics.orca.export.saaif;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.xml.XMLConstants;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.loader.saaif.SAAIFItemReader;
import com.pacificmetrics.orca.loader.saaif.SAAIFManifestReader;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageReader;
import com.pacificmetrics.saaif.item1.AssessmentitemType;
import com.pacificmetrics.saaif.manifest.Manifest;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource.Dependency;

@Stateless
public class SAAIFItemValidator {

    private static final Log LOGGER = LogFactory
            .getLog(SAAIFItemValidator.class);

    @EJB
    private ContentMoveServices contentMoveServices;

    public boolean validataXMLWithXSD(String sourceFilePath, int type) {

        boolean validated = false;
        // Parse xsd a provides a schema object
        try {

            URL dirUrl = null;
            if (type == 1) { // For "Manifest" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/SAAIF-IMS-Manifest.xsd");
            } else if (type == 2) { // For "Item" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/assessmentitem_v1p0.xsd");
            } else if (type == 3) { // For "Wordlist" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/wordlist_v1p0.xsd");
            } else if (type == 4) { // For "Item Metadata" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/SAAIF-Item-Metadata.xsd");
            } else if (type == 5) { // For "Stimulus" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/passageitem_v1p0.xsd");
            } else if (type == 6) { // For "Tutorial" validation
                dirUrl = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/tutorial_v1p0.xsd");
            }
            SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);

            Schema schema = schemaFactory.newSchema(new File(dirUrl.toURI()));

            // Processor to check XML is valid against schema
            Validator validator = schema.newValidator();

            File xmlFile = new File(sourceFilePath);
            // Validates the specified input
            validator.validate(new StreamSource(xmlFile));

            validated = true;

        } catch (SAXException e) {
            validated = false;
            LOGGER.fatal("Error : " + e.getMessage(), e);
        } catch (IOException e) {
            validated = false;
            LOGGER.fatal("Error : " + e.getMessage(), e);
        } catch (URISyntaxException e) {
            validated = false;
            LOGGER.fatal("Error : " + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.fatal("Error : " + e.getMessage(), e);
            validated = false;
        }

        return validated;
    }

    public Map<String, Map<String, String>> validationPackageStructure(
            String outputZipFolder, ItemMoveMonitor importMoveMonitor) {

        boolean existStatusflag = true;
        boolean validationStatusflag = true;
        Map<String, Resource> resourceMap = new HashMap<String, Resource>();
        Map<String, String> errorFromDBMap = new HashMap<String, String>();
        Map<String, Map<String, String>> errorMap = new HashMap<String, Map<String, String>>();
        Map<String, String> subErrorMap = new HashMap<String, String>();
        int xsdType = 0;
        try {
            List<DetailStatusType> dstList = contentMoveServices
                    .findAllItemDetailStatusTypes();
            for (DetailStatusType detailStatusType : dstList) {
                errorFromDBMap.put(detailStatusType.getValue(),
                        String.valueOf(detailStatusType.getId()));
            }

            File manifestFile = new File(outputZipFolder + "/"
                    + SAAIFPackageConstants.MANIFST_FILE_NAME);
            if (manifestFile.exists()) {
                xsdType = 1;
                validationStatusflag = validataXMLWithXSD(outputZipFolder + "/"
                        + SAAIFPackageConstants.MANIFST_FILE_NAME, xsdType);

                if (!validationStatusflag) {
                    subErrorMap
                            .put(SAAIFPackageConstants.MANIFST_FILE_NAME
                                    + "#"
                                    + errorFromDBMap
                                            .get(SAAIFPackageConstants.ERROR_VALIDATION),
                                    SAAIFPackageConstants.MANIFST_FILE_NAME
                                            + " -> "
                                            + SAAIFPackageConstants.ERROR_VALIDATION
                                            + " ( " + outputZipFolder + " ) ");
                    errorMap.put(SAAIFPackageConstants.MANIFST_FILE_NAME,
                            subErrorMap);
                } else {
                    LOGGER.info(SAAIFPackageConstants.MANIFST_FILE_NAME
                            + " has been validated. (Succesful)");
                }
                InputStream manifestStream = new FileInputStream(manifestFile);
                Manifest manifest = SAAIFManifestReader
                        .readManifest(manifestStream);
                resourceMap = SAAIFManifestReader.readResources(manifest);
                if (manifest != null
                        && manifest.getResources() != null
                        && CollectionUtils.isNotEmpty(manifest.getResources()
                                .getResource())) {

                    List<String> dependancyList = new ArrayList<String>();

                    for (Resource resource : manifest.getResources()
                            .getResource()) {
                        if (CollectionUtils
                                .isNotEmpty(resource.getDependency())) {
                            for (Dependency itemDependency : resource
                                    .getDependency()) {
                                Resource dependentResource = resourceMap
                                        .get(itemDependency.getIdentifierref());
                                dependancyList.add(dependentResource.getFile()
                                        .getHref().split("/")[2]);
                            }
                        }
                    }

                    String imdExternalId = "";

                    for (Resource resource : manifest.getResources()
                            .getResource()) {
                        String itemDirName = resource.getFile().getHref()
                                .split("/")[1];
                        String fileName = resource.getFile().getHref()
                                .split("/")[2];
                        String sourceFilePath = outputZipFolder + "/"
                                + resource.getFile().getHref();
                        File resourcefile = new File(sourceFilePath);

                        if (SAAIFPackageConstants.ITEM_TYPE.equals(resource
                                .getType())) {
                            if (resourcefile.exists()) {
                                AssessmentitemType item = SAAIFItemReader
                                        .readItem(sourceFilePath);

                                if (!dependancyList.contains(fileName)) {
                                    if (subErrorMap.isEmpty()) {
                                        subErrorMap = new HashMap<String, String>();
                                    } else {
                                        errorMap.put(imdExternalId, subErrorMap);
                                        subErrorMap = new HashMap<String, String>();
                                    }

                                    imdExternalId = String
                                            .valueOf(item != null ? item
                                                    .getId() : itemDirName);
                                }

                                if (item != null
                                        && SAAIFPackageConstants.WORDLIST_FORMAT
                                                .equals(item.getType())) {
                                    xsdType = 3;
                                } else {
                                    xsdType = 2;
                                }
                                validationStatusflag = validataXMLWithXSD(
                                        sourceFilePath, xsdType);
                                if (validationStatusflag) {
                                    LOGGER.info(fileName
                                            + " is validated.--(Successful)");
                                } else {
                                    subErrorMap
                                            .put(fileName
                                                    + "#"
                                                    + errorFromDBMap
                                                            .get(SAAIFPackageConstants.ERROR_VALIDATION),
                                                    fileName
                                                            + " -> "
                                                            + SAAIFPackageConstants.ERROR_VALIDATION
                                                            + " ( "
                                                            + sourceFilePath
                                                                    .replace(
                                                                            outputZipFolder,
                                                                            "")
                                                            + " ) ");
                                }
                            } else {

                                if (!dependancyList.contains(fileName)) {
                                    imdExternalId = String.valueOf(itemDirName);
                                }

                                existStatusflag = false;
                                subErrorMap
                                        .put(fileName
                                                + "#"
                                                + errorFromDBMap
                                                        .get(SAAIFPackageConstants.ERROR_MISSING),
                                                fileName
                                                        + " -> not found into "
                                                        + sourceFilePath
                                                                .replace(
                                                                        outputZipFolder,
                                                                        ""));
                            }
                        } else if (SAAIFPackageConstants.STIMULUS_TYPE
                                .equals(resource.getType())) {
                            if (resourcefile.exists()) {
                                xsdType = 5;

                                if (validataXMLWithXSD(sourceFilePath, xsdType)) {
                                    LOGGER.info(fileName
                                            + " is validated.--(Successful)");
                                } else {

                                    subErrorMap
                                            .put(fileName
                                                    + "#"
                                                    + errorFromDBMap
                                                            .get(SAAIFPackageConstants.ERROR_VALIDATION),
                                                    fileName
                                                            + " -> "
                                                            + SAAIFPackageConstants.ERROR_VALIDATION
                                                            + " ( "
                                                            + sourceFilePath
                                                                    .replace(
                                                                            outputZipFolder,
                                                                            "")
                                                            + " ) ");
                                }
                            } else {
                                existStatusflag = false;
                                subErrorMap
                                        .put(fileName
                                                + "#"
                                                + errorFromDBMap
                                                        .get(SAAIFPackageConstants.ERROR_MISSING),
                                                fileName
                                                        + " -> not found into "
                                                        + sourceFilePath
                                                                .replace(
                                                                        outputZipFolder,
                                                                        "")
                                                        + " ) ");
                            }
                        } else if (SAAIFPackageConstants.METADATA_TYPE
                                .equals(resource.getType())) {
                            if (resourcefile.exists()) {
                                xsdType = 4;
                            } else {
                                existStatusflag = false;
                                subErrorMap
                                        .put(fileName
                                                + "#"
                                                + errorFromDBMap
                                                        .get(SAAIFPackageConstants.ERROR_MISSING),
                                                fileName
                                                        + " -> not found into "
                                                        + sourceFilePath
                                                                .replace(
                                                                        outputZipFolder,
                                                                        "")
                                                        + " ) ");
                            }
                        } else if (SAAIFPackageConstants.CONTENT_TYPE
                                .equals(resource.getType())) {
                            if (resourcefile.exists()) {
                                LOGGER.info(fileName + " found.--(Successful)");
                            } else {
                                existStatusflag = false;
                                subErrorMap
                                        .put(fileName
                                                + "#"
                                                + errorFromDBMap
                                                        .get(SAAIFPackageConstants.ERROR_MISSING),
                                                fileName
                                                        + " -> not found into "
                                                        + sourceFilePath
                                                                .replace(
                                                                        outputZipFolder,
                                                                        "")
                                                        + " ) ");
                            }
                        }
                    }

                    if (!subErrorMap.isEmpty()) {
                        errorMap.put(imdExternalId, subErrorMap);
                    }

                    if (existStatusflag && validationStatusflag) {
                        LOGGER.info("All resources are at in place.--(Successful)");
                    }
                }

            } else {
                subErrorMap
                        .put(SAAIFPackageConstants.MANIFST_FILE_NAME
                                + "#"
                                + errorFromDBMap
                                        .get(SAAIFPackageConstants.ERROR_MISSING),
                                SAAIFPackageConstants.MANIFST_FILE_NAME
                                        + " -> not found into "
                                        + outputZipFolder);
                errorMap.put(SAAIFPackageConstants.MANIFST_FILE_NAME,
                        subErrorMap);
            }
        } catch (Exception e) {
            LOGGER.fatal("Validation failed." + e.getMessage(), e);
        }
        return errorMap;
    }
}
