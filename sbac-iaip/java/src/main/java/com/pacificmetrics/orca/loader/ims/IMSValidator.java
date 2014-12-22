package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.io.IOException;
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
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import com.pacificmetrics.ims.apip.cp.Manifest;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.loader.ItemImportException;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.saaif.metadata.Metadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata;
import com.pacificmetrics.saaif.metadata.MetadataFieldConstants;
import com.pacificmetrics.saaif.metadata.SAAIFMetadataParser;

@Stateless
public class IMSValidator {

    private static final Log LOGGER = LogFactory.getLog(IMSValidator.class);

    private static final String XSD_BASE_DIR = "/xsd/ims/apip/";

    @EJB
    private transient ContentMoveServices contentMoveServices;

    public Map<String, Map<String, String>> validate(String outputZipFolder) {
        return validationPackageStructure(outputZipFolder);
    }

    private Map<String, Map<String, String>> validationPackageStructure(
            String outputZipFolder) {
        boolean validated = false;
        Map<String, String> detailStatusTypeMap = fetchDetailStatusTypeMap();
        Map<String, Map<String, String>> errorMap = new HashMap<String, Map<String, String>>();

        LOGGER.info("Validating package content from path " + outputZipFolder);

        // validating manifest file
        validated = validateManifest(outputZipFolder, detailStatusTypeMap,
                errorMap);

        if (validated) {
            boolean allResourcesValidated = validateResources(outputZipFolder,
                    detailStatusTypeMap, errorMap);
            if (allResourcesValidated) {
                LOGGER.info("Validated package content from path "
                        + outputZipFolder + " all resources are in place.");
            }
        }

        return errorMap;
    }

    private boolean validateResources(String outputZipFolder,
            Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean allResourceValidated = true;
        String manifestFilePath = outputZipFolder + File.separator
                + IMSPackageConstants.MANIFST_FILE_NAME;
        Manifest manifest = IMSManifestReader.readManifest(manifestFilePath);

        if (manifest != null
                && manifest.getResources() != null
                && CollectionUtils.isNotEmpty(manifest.getResources()
                        .getResources())) {
            for (ResourceType resource : manifest.getResources().getResources()) {
                boolean validated = validateResource(outputZipFolder, resource,
                        detailStatusTypeMap, errorMap);
                if (!validated) {
                    allResourceValidated = false;
                }
            }
        }

        return allResourceValidated;
    }

    private boolean validateResource(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        if (IMSPackageConstants.IMS_APIP_QTI_ITEM_TYPE_V2
                .equalsIgnoreCase(resource.getType())) {
            validated = validateItem(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        } else if (IMSPackageConstants.IMS_APIP_SECTION_TYPE
                .equalsIgnoreCase(resource.getType())) {
            validated = validateSection(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        } else if (IMSPackageConstants.IMS_APIP_STIMULUS_TYPE
                .equalsIgnoreCase(resource.getType())) {
            validated = validateStimulus(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        } else if (IMSPackageConstants.IMS_CONTENT_TYPE
                .equalsIgnoreCase(resource.getType())) {
            validated = validateContent(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        } else if (IMSPackageConstants.IMS_METADATA_TYPE.equals(resource
                .getType())
                && IMSItemUtil.isAPIPMetadataExists(outputZipFolder, resource)) {
            validated = validateItemMetadata(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        } else if (IMSPackageConstants.IMS_METADATA_TYPE
                .equalsIgnoreCase(resource.getType())
                && IMSItemUtil.isSBACMetadataExists(outputZipFolder, resource)) {
            validated = validateSBACItemMetadata(outputZipFolder, resource,
                    detailStatusTypeMap, errorMap);
        }
        return validated;
    }

    private boolean validateItem(String outputZipFolder, ResourceType resource,
            Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String itemFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File itemFile = new File(itemFilePath);
        if (!itemFile.exists()) {
            LOGGER.info("Item file " + itemFile.getName()
                    + " not found in package.");
            subErrorMap
                    .put(itemFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            itemFile.getName() + " not found in package.");

        } else if (!validateXMLWithXSD(itemFilePath,
                IMSPackageConstants.IMS_ITEM_TYPE)) {
            LOGGER.info("Item file " + itemFile.getName()
                    + " validation failed against the schema.");
            subErrorMap
                    .put(itemFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_XML),
                            itemFile.getName() + " validation failed.");
        } else {
            LOGGER.info(itemFile.getName()
                    + " found in package, and successfully validated against the schema.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(itemFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean validateStimulus(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String stimulusFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File stimulusFile = new File(stimulusFilePath);
        if (!stimulusFile.exists()) {
            LOGGER.info(stimulusFile.getName() + " not found in package.");
            subErrorMap
                    .put(stimulusFile.getName()
                            + "#"
                            + errorMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            stimulusFile.getName() + " not found in package.");
        } else if (!validateXMLWithXSD(stimulusFilePath,
                IMSPackageConstants.IMS_STIMULUS_TYPE)) {
            LOGGER.info("Stimulus file " + stimulusFile.getName()
                    + " stimulus validation failed against the schema.");
            subErrorMap
                    .put(stimulusFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_XML),
                            stimulusFile.getName() + " validation failed.");
        } else {
            LOGGER.info("Stimulus file " + stimulusFile.getName()
                    + " found in package.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(stimulusFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean validateSection(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String sectionFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File sectionFile = new File(sectionFilePath);
        if (!sectionFile.exists()) {
            LOGGER.info("Section file " + sectionFile.getName()
                    + " not found in package.");
            subErrorMap
                    .put(sectionFile.getName()
                            + "#"
                            + errorMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            sectionFile.getName() + " not found in package.");
        } else if (!validateXMLWithXSD(sectionFilePath,
                IMSPackageConstants.IMS_SECTION_TYPE)) {
            LOGGER.info("Section file " + sectionFile.getName()
                    + " validation failed against the schema.");
            subErrorMap
                    .put(sectionFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_XML),
                            sectionFile.getName() + " validation failed.");
        } else {
            LOGGER.info("Section file " + sectionFile.getName()
                    + " found in package.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(sectionFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean validateContent(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String contentFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File contentFile = new File(contentFilePath);
        if (!contentFile.exists()) {
            LOGGER.info("Resource " + contentFile.getName()
                    + " not found in package.");
            subErrorMap
                    .put(contentFile.getName()
                            + "#"
                            + errorMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            contentFile.getName() + " not found in package.");
        } else {
            LOGGER.info("Resource " + contentFile.getName()
                    + " found in package.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(contentFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean validateSBACItemMetadata(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String itemMetadataFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File itemMetadataFile = new File(itemMetadataFilePath);
        Metadata sbacMetadata = null;
        List<String> missingRequiredFields = new ArrayList<String>();
        if (!itemMetadataFile.exists()) {
            LOGGER.info("Item metadata " + itemMetadataFile.getName()
                    + " not found in package.");
            subErrorMap
                    .put(itemMetadataFile.getName()
                            + "#"
                            + errorMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            itemMetadataFile.getName()
                                    + " not found in package.");
        } else if ((sbacMetadata = SAAIFMetadataParser.parseMetdata(FileUtil
                .readXMLFileWithoutDeclaration(itemMetadataFile))) == null) {
            LOGGER.info("Item metadata file " + itemMetadataFile.getName()
                    + " validation failed against the schema.");
            subErrorMap
                    .put(itemMetadataFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_XML),
                            itemMetadataFile.getName() + " validation failed.");
        } else if (sbacMetadata != null
                && sbacMetadata.getSmarterAppMetadata() != null
                && !isMetadataFieldPresent(
                        sbacMetadata.getSmarterAppMetadata(),
                        missingRequiredFields)) {
            LOGGER.info("Item metadata file " + itemMetadataFile.getName()
                    + " validation failed against the schema.");
            subErrorMap
                    .put(itemMetadataFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_METADATA),
                            itemMetadataFile.getName()
                                    + " missing metadata element(s) "
                                    + (CollectionUtils
                                            .isNotEmpty(missingRequiredFields) ? missingRequiredFields
                                            : ""));
        } else {
            LOGGER.info("Item Metadata " + itemMetadataFile.getName()
                    + " found in package.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(itemMetadataFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean isMetadataFieldPresent(
            SmarterAppMetadata smarterAppMetadata,
            List<String> missingRequiredFields) {
        boolean validated = true;
        if (smarterAppMetadata.getIdentifier() <= 0) {
            missingRequiredFields.add(MetadataFieldConstants.IDENTIFIER);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getInteractionType())) {
            missingRequiredFields.add(MetadataFieldConstants.INTERACTIONTYPE);
            validated = false;
        }
        if (smarterAppMetadata.getVersion() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.VERSION);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getSubject())) {
            missingRequiredFields.add(MetadataFieldConstants.SUBJECT);
            validated = false;
        }
        if (CollectionUtils.isEmpty(smarterAppMetadata.getLanguage())) {
            missingRequiredFields.add(MetadataFieldConstants.LANGUAGE);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getSecurityStatus())) {
            missingRequiredFields.add(MetadataFieldConstants.SECURITYSTATUS);
            validated = false;
        }
        if (smarterAppMetadata.getMinimumGrade() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.MINIMUMGRADE);
            validated = false;
        }
        if (smarterAppMetadata.getMaximumGrade() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.MAXIMUMGRADE);
            validated = false;
        }
        if (smarterAppMetadata.getIntendedGrade() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.INTENDEDGRADE);
            validated = false;
        }
        if (smarterAppMetadata.getMaximumNumberOfPoints() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.MAXNOOFPOINTS);
            validated = false;
        }
        if (CollectionUtils.isEmpty(smarterAppMetadata.getScorePoints())) {
            missingRequiredFields.add(MetadataFieldConstants.SCOREPOINTS);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getItemSpecFormat())) {
            missingRequiredFields.add(MetadataFieldConstants.ITEMSPECFORMAT);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getStimulusFormat())) {
            missingRequiredFields.add(MetadataFieldConstants.STIMULUSFORMAT);
            validated = false;
        }
        if (smarterAppMetadata.getDepthOfKnowledge() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.DEPTHOFKNOWLEDGE);
            validated = false;
        }
        if (StringUtils.isBlank(smarterAppMetadata.getEducationalDifficulty())) {
            missingRequiredFields
                    .add(MetadataFieldConstants.EDUCATIONALDIFFICULTY);
            validated = false;
        }
        return validated;
    }

    private boolean validateItemMetadata(String outputZipFolder,
            ResourceType resource, Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = true;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        String itemMetadataFilePath = outputZipFolder + File.separator
                + getHref(resource);
        File itemMetadataFile = new File(itemMetadataFilePath);
        if (!itemMetadataFile.exists()) {
            LOGGER.info("Item metadata " + itemMetadataFile.getName()
                    + " not found in package.");
            subErrorMap
                    .put(itemMetadataFile.getName()
                            + "#"
                            + errorMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            itemMetadataFile.getName()
                                    + " not found in package.");
        } else if (!validateXMLWithXSD(itemMetadataFilePath,
                IMSPackageConstants.IMS_ITEM_METADATA_TYPE)) {
            LOGGER.info("Item metadata file " + itemMetadataFile.getName()
                    + " validation failed against the schema.");
            subErrorMap
                    .put(itemMetadataFile.getName()
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_INVALID_XML),
                            itemMetadataFile.getName() + " validation failed.");
        } else {
            LOGGER.info("Item Metadata " + itemMetadataFile.getName()
                    + " found in package.");
        }
        if (!subErrorMap.isEmpty()) {
            validated = false;
            errorMap.put(itemMetadataFile.getName(), subErrorMap);
        }
        return validated;
    }

    private boolean validateManifest(String outputZipFolder,
            Map<String, String> detailStatusTypeMap,
            Map<String, Map<String, String>> errorMap) {
        boolean validated = false;
        Map<String, String> subErrorMap = new HashMap<String, String>();
        File manifestFile = new File(outputZipFolder + File.separator
                + IMSPackageConstants.MANIFST_FILE_NAME);
        if (manifestFile.exists()) {
            LOGGER.info(IMSPackageConstants.MANIFST_FILE_NAME
                    + " found at path " + manifestFile.getAbsolutePath());
            validated = validateXMLWithXSD(manifestFile.getAbsolutePath(),
                    IMSPackageConstants.IMS_MANIFEST_TYPE);
            if (!validated) {
                LOGGER.info("Manifest file "
                        + IMSPackageConstants.MANIFST_FILE_NAME
                        + " validation against the schema failed.");
                subErrorMap
                        .put(IMSPackageConstants.MANIFST_FILE_NAME
                                + "#"
                                + detailStatusTypeMap
                                        .get(IMSPackageConstants.ERROR_INVALID_XML),
                                IMSPackageConstants.MANIFST_FILE_NAME
                                        + " validation failed.");
                errorMap.put(IMSPackageConstants.MANIFST_FILE_NAME, subErrorMap);
            }
            LOGGER.info("Manifest file "
                    + IMSPackageConstants.MANIFST_FILE_NAME
                    + " validated against the schema sucessfully.");
        } else {
            LOGGER.info("Manifest file "
                    + IMSPackageConstants.MANIFST_FILE_NAME
                    + " not found at path " + outputZipFolder);
            subErrorMap
                    .put(IMSPackageConstants.MANIFST_FILE_NAME
                            + "#"
                            + detailStatusTypeMap
                                    .get(IMSPackageConstants.ERROR_MISSING_RESOURCES),
                            IMSPackageConstants.MANIFST_FILE_NAME
                                    + " not found in package.");
            errorMap.put(IMSPackageConstants.MANIFST_FILE_NAME, subErrorMap);
        }
        return validated;
    }

    private boolean validateXMLWithXSD(String sourceFilePath, int type) {
        try {
            LOGGER.info("Validating " + sourceFilePath + " against the schema.");
            URL xsdURL = null;
            if (IMSPackageConstants.IMS_MANIFEST_TYPE == type) {
                xsdURL = IMSValidator.class.getClassLoader().getResource(
                        XSD_BASE_DIR + IMSPackageConstants.MANIFEST_XSD);
            } else if (IMSPackageConstants.IMS_ITEM_TYPE == type) {
                xsdURL = IMSValidator.class.getClassLoader().getResource(
                        XSD_BASE_DIR + IMSPackageConstants.ITEM_XSD);
            } else if (IMSPackageConstants.IMS_SECTION_TYPE == type) {
                xsdURL = IMSValidator.class.getClassLoader().getResource(
                        XSD_BASE_DIR + IMSPackageConstants.SECTION_XSD);
            } else if (IMSPackageConstants.IMS_STIMULUS_TYPE == type) {
                xsdURL = IMSValidator.class.getClassLoader().getResource(
                        XSD_BASE_DIR + IMSPackageConstants.STIMULUS_XSD);
            } else if (IMSPackageConstants.IMS_ITEM_METADATA_TYPE == type) {
                xsdURL = IMSValidator.class.getClassLoader().getResource(
                        XSD_BASE_DIR + IMSPackageConstants.METADATA_XSD);
            } else {
                throw new ItemImportException(
                        "Unsupport schema validation type " + type);
            }
            SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);

            Schema schema = schemaFactory.newSchema(new File(xsdURL.toURI()));

            // Processor to check XML is valid against schema
            Validator validator = schema.newValidator();

            File xmlFile = new File(sourceFilePath);

            // Validates the specified input
            validator.validate(new StreamSource(xmlFile));

            return true;
        } catch (SAXException e) {
            LOGGER.error("Schema validation failed for file " + sourceFilePath
                    + " for type " + type + " cause " + e.getMessage(), e);
        } catch (URISyntaxException e) {
            LOGGER.error("Unable to load schema for type " + type, e);
        } catch (IOException e) {
            LOGGER.error("Unable to read schema file for type " + type, e);
        } catch (Exception e) {
            LOGGER.error("Validation failed for file " + sourceFilePath
                    + " type " + type, e);
        }
        return false;
    }

    private Map<String, String> fetchDetailStatusTypeMap() {
        Map<String, String> detailStatusTypeMap = new HashMap<String, String>();
        try {
            List<DetailStatusType> detailStatusTypeList = contentMoveServices
                    .findAllItemDetailStatusTypes();
            if (CollectionUtils.isNotEmpty(detailStatusTypeList)) {
                LOGGER.info("Detail Status Types found "
                        + detailStatusTypeList.size());
                for (DetailStatusType detailStatusType : detailStatusTypeList) {
                    detailStatusTypeMap.put(detailStatusType.getValue(),
                            String.valueOf(detailStatusType.getId()));
                }
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error fetching content move detail status types "
                            + e.getMessage(), e);
        }
        return detailStatusTypeMap;
    }

    private String getHref(ResourceType resource) {
        if (resource != null && StringUtils.isNotEmpty(resource.getHref())) {
            return resource.getHref();
        } else if (CollectionUtils.isNotEmpty(resource.getFiles())) {
            return resource.getFiles().get(0).getHref();
        }
        return null;
    }

    public void setContentMoveServices(ContentMoveServices contentMoveServices) {
        this.contentMoveServices = contentMoveServices;
    }
}
