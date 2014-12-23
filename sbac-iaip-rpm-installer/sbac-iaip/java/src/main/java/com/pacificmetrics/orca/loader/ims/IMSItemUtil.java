package com.pacificmetrics.orca.loader.ims;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.StringReader;
import java.util.HashMap;
import java.util.Map;

import javax.xml.bind.JAXBElement;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3.synthesis.Audio;
import org.w3.synthesis.Break;
import org.w3.synthesis.Emphasis;
import org.w3.synthesis.Mark;
import org.w3.synthesis.ObjectFactory;
import org.w3.synthesis.Prosody;
import org.w3.synthesis.SayAs;
import org.w3.synthesis.Sub;
import org.w3.synthesis.Voice;

import com.pacificmetrics.ims.apip.cp.DependencyType;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.apip.qti.item.AssessmentItem;
import com.pacificmetrics.ims.apip.qti.item.Div;
import com.pacificmetrics.ims.apip.qti.item.HTMLTextType;
import com.pacificmetrics.ims.qti.stimulus.AssessmentStimulus;
import com.pacificmetrics.ims.qti.stimulus.StimulusBody;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.orca.utils.SAAIFItemUtil;

public class IMSItemUtil {

    private static final Log LOGGER = LogFactory.getLog(IMSItemUtil.class);

    private IMSItemUtil() {

    }

    public static String updatePassageXmlContent(String xmlContent,
            String passageId, String passageDescription) {
        String updateXmlContent = "";
        try {
            AssessmentStimulus stimulus = JAXBUtil.unmershall(xmlContent,
                    AssessmentStimulus.class, ObjectFactory.class);
            stimulus.setIdentifier(passageId);
            stimulus.setTitle(passageDescription);
            updateXmlContent = JAXBUtil.mershall(stimulus,
                    AssessmentStimulus.class, ObjectFactory.class);
        } catch (Exception e) {
            LOGGER.error("Error updating passage xml " + e.getMessage(), e);
        }
        return updateXmlContent;
    }

    public static String updatePassageMetadata(String xmlContent,
            Passage passage, String genre) {
        String updatedXmlContent = "";
        try {
            updatedXmlContent = SAAIFItemUtil.setPassageMetadataAttribute(
                    xmlContent, String.valueOf(passage.getId()), passage
                            .getSubject(),
                    StringUtils.isNotBlank(genre) ? genre : null, passage
                            .getPassagePublicationStatus() != null ? passage
                            .getPassagePublicationStatus().getName() : null,
                    passage.getGradeLevel(), passage.getMinimumGrade(), passage
                            .getMaximumGrade());
        } catch (Exception e) {
            LOGGER.error(
                    "Error updating passage metadata xml " + e.getMessage(), e);
        }
        return updatedXmlContent;
    }

    public static String updateItemXmlContent(String xmlContent, String itemId,
            String itemDescription) {
        String updatedXmlContent = "";
        try {
            AssessmentItem assessmentItem = JAXBUtil.unmershall(xmlContent,
                    AssessmentItem.class, ObjectFactory.class);
            assessmentItem.setIdentifier(itemId);
            assessmentItem.setTitle(itemDescription);
            updatedXmlContent = JAXBUtil.mershall(assessmentItem,
                    AssessmentItem.class, ObjectFactory.class);
        } catch (Exception e) {
            LOGGER.error("Error updating item xml " + e.getMessage(), e);
        }
        return updatedXmlContent;
    }

    public static String updateItemMetadata(String xmlContent, Item item,
            String difficulty) {
        String updateXmlContent = "";
        try {
            updateXmlContent = SAAIFItemUtil.setItemMetadataAttribute(
                    xmlContent, String.valueOf(item.getId()), item
                            .getItemGuid(), item.getSubject(), item.getPoint(),
                    StringUtils.isNotBlank(difficulty) ? difficulty : null,
                    item.getDepthOfKnowdledge(), item
                            .getItemPublicationStatus() != null ? item
                            .getItemPublicationStatus().getName() : null, item
                            .getGradeLevel(), item.getMinimumGrade(), item
                            .getMaximumGrade(), item.getPrimaryStandard(), item
                            .getItemStandardList(), item
                            .getDescription() != null ? item
                            .getDescription() : null);
        } catch (Exception e) {
            LOGGER.error("Error updating item metadata xml " + e.getMessage(),
                    e);
        }
        return updateXmlContent;
    }

    public static String getItemAttachmentDirPath(int ibId, String identifier) {
        // /www/cde_resources/cdesbac/attachments/lib15/Item_174
        String resource = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String prefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return resource
                + File.separator
                + application
                + File.separator
                + PropertyUtil
                        .getProperty(PropertyUtil.RESOURCE_ATTACHMENT_DIR)
                + File.separator + prefix + ibId + File.separator + identifier;
    }

    public static String getPassageAttachmentDirPath(int itemBankId,
            String identifier) {
        String resource = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String prefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return resource
                + File.separator
                + application
                + File.separator
                + PropertyUtil
                        .getProperty(PropertyUtil.RESOURCE_ATTACHMENT_DIR)
                + File.separator + prefix + itemBankId + File.separator
                + identifier;
    }

    static public String getItemImageDirPath(int itemBankId, String identifier) {
        // /www/cde_resources/cdesbac/images/lib15/Item_174
        String resource = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String prefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return resource + File.separator + application + File.separator
                + PropertyUtil.getProperty(PropertyUtil.RESOURCE_IMAGE_DIR)
                + File.separator + prefix + itemBankId + File.separator
                + identifier;
    }

    public static String savePassageImage(String sourcePath, String fileName,
            int itemBankId, int passageId) {
        try {
            String imagePath = getPassageImageDirPath(itemBankId, passageId);
            File resourceFile = new File(imagePath, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save passage image asset from path "
                    + sourcePath + " file " + fileName, e);
            return null;
        }
    }

    public static String savePassageAttachment(String sourcePath,
            String fileName, int itemBankId, String identifier) {
        String attachmentDirPath = getPassageAttachmentDirPath(itemBankId,
                identifier);
        File sourceFile = new File(sourcePath);
        if (sourceFile.exists()) {
            try {
                File destinationFile = new File(attachmentDirPath
                        + File.separator + sourceFile.getName());
                FileUtils.copyFile(sourceFile, destinationFile);
                LOGGER.info("File copied to path "
                        + destinationFile.getCanonicalPath());
                return destinationFile.getAbsolutePath();
            } catch (IOException e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            } catch (Exception e) {
                LOGGER.error("Error in saving item asset from path "
                        + sourceFile.getAbsolutePath() + " " + e.getMessage(),
                        e);
            }
        }
        return null;
    }

    public static String savePassageMedia(String sourcePath, String fileName,
            int itemBankId, int passageId) {
        try {
            String mediaPath = getPassageMediaDirPath(itemBankId, passageId);
            File resourceFile = new File(mediaPath, fileName);
            if (!resourceFile.exists()) {
                FileUtil.copyFile(sourcePath, resourceFile.getAbsolutePath());
            }
            return resourceFile.getAbsolutePath();
        } catch (Exception e) {
            LOGGER.error("Unable to save passage media asset from path "
                    + sourcePath + " file " + fileName, e);
            return null;
        }
    }

    static public String getPassageImageDirPath(int itemBankId, int passageId) {
        // /www/cde_resources/cdesbac/images/lib15/Item_174
        String resource = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String passage = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_DIR);
        String passagePrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX);
        String prefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return resource + File.separator + application + File.separator
                + passage + File.separator + prefix + itemBankId
                + File.separator
                + PropertyUtil.getProperty(PropertyUtil.RESOURCE_IMAGE_DIR)
                + File.separator + passagePrefix + passageId;
    }

    static public String getPassageMediaDirPath(int itemBankId, int passageId) {
        // /www/cde_resources/cdesbac/passages/lib15/media/p3/
        String resource = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String passage = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_DIR);
        String passagePrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX);
        String prefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return resource + File.separator + application + File.separator
                + passage + File.separator + prefix + itemBankId
                + File.separator
                + PropertyUtil.getProperty(PropertyUtil.RESOURCE_MEDIA_DIR)
                + File.separator + passagePrefix + passageId;
    }

    public static String getPassageSourceURL(int itemBankId, int passageId) {
        String webDir = PropertyUtil.getProperty(PropertyUtil.WEB_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String passageDir = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_DIR);
        String passagePrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX);
        String libPrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return webDir + File.separator + application + File.separator
                + passageDir + File.separator + libPrefix + itemBankId
                + File.separator + passagePrefix + passageId + ".html";
    }

    public static String getPassagePath(int itemBankId, int passageId) {
        String webDir = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String passageDir = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_DIR);
        String passagePrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX);
        String libPrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return webDir + File.separator + application + File.separator
                + passageDir + File.separator + libPrefix + itemBankId
                + File.separator + passagePrefix + passageId + ".html";
    }
    
    public static String getPassageSourcePath(int itemBankId, int passageId) {
        String webDir = PropertyUtil.getProperty(PropertyUtil.RESOURCE_DIR);
        String application = PropertyUtil
                .getProperty(PropertyUtil.INSTANCE_NAME);
        String passageDir = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_PASSAGE_DIR);        
        String libPrefix = PropertyUtil
                .getProperty(PropertyUtil.RESOURCE_LIB_PREFIX);
        return webDir + File.separator + application + File.separator
                + passageDir + File.separator + libPrefix + itemBankId;                
    }

    public static String getPassgaeBody(StimulusBody stimulusBody) {
        String passageBody = "";
        try {
            passageBody = JAXBUtil.mershall(stimulusBody, StimulusBody.class,
                    ObjectFactory.class, Sub.class, Voice.class, Audio.class,
                    Emphasis.class, SayAs.class, Break.class, Mark.class,
                    Prosody.class);
            if (StringUtils.isNotBlank(passageBody)) {
                StringReader stringReader = new StringReader(passageBody);
                BufferedReader bufferedReader = new BufferedReader(stringReader);
                StringBuilder stringBuffer = new StringBuilder();
                String line = null;
                while ((line = bufferedReader.readLine()) != null) {
                    if (line != null
                            && (!line.contains("<stimulusBody")
                                    && !line.contains("</stimulusBody") && !line
                                        .contains("<?xml"))) {
                        stringBuffer.append(line);
                    }
                }
                passageBody = stringBuffer.toString();
            }
        } catch (Exception e) {
            LOGGER.error("Unable to get passage body: " + e.getMessage(), e);
        }
        return passageBody;
    }

    public static Map<String, String> readFilesFromPath(String filePath) {
        Map<String, String> filesMap = new HashMap<String, String>();
        File dir = new File(filePath);
        if (dir.exists()) {
            for (String fileName : dir.list()) {
                filesMap.put(fileName, filePath + File.separator + fileName);
            }
        }
        return filesMap;
    }

    public static Map<String, Object> createIdRefMap(Object divObject) {
        Map<String, Object> idRefMap = new HashMap<String, Object>();
        try {
            Div div = (Div) divObject;
            for (Object object : div.getContent()) {
                if (object instanceof JAXBElement) {
                    HTMLTextType htt = (HTMLTextType) ((JAXBElement) object)
                            .getValue();
                    idRefMap.put(htt.getId(), htt);
                }
            }
        } catch (Exception e) {
            LOGGER.error("Unable to get Id ref map: " + e.getMessage(), e);
        }
        return idRefMap;
    }

    public static Map<String, Object> createIdRefMapForStimulus(Object divObject) {
        Map<String, Object> idRefMap = new HashMap<String, Object>();
        try {
            com.pacificmetrics.ims.qti.stimulus.Div div = (com.pacificmetrics.ims.qti.stimulus.Div) divObject;
            for (Object object : div.getContent()) {
                if (object instanceof JAXBElement) {
                	com.pacificmetrics.ims.qti.stimulus.HTMLTextType htt = (com.pacificmetrics.ims.qti.stimulus.HTMLTextType) ((JAXBElement) object)
                            .getValue();
                    idRefMap.put(htt.getId(), htt);
                }
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to create IdRefMapForStimulus: " + e.getMessage(),
                    e);
        }
        return idRefMap;
    }

    public static boolean isSBACMetadataExists(String outputZipFolder,
            ResourceType resource) {
        boolean metadataExists = false;
        try {
            if (resource != null
                    && CollectionUtils.isNotEmpty(resource.getDependencies())) {
                for (DependencyType dependency : resource.getDependencies()) {
                    ResourceType dependentResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (dependentResource != null
                            && StringUtils.equals(dependentResource.getType(),
                                    IMSPackageConstants.IMS_METADATA_TYPE)
                            && StringUtils.isNotBlank(outputZipFolder
                                    + File.separator
                                    + IMSItemReader.getHref(dependentResource))) {
                        File resourceFile = new File(outputZipFolder
                                + File.separator
                                + IMSItemReader.getHref(dependentResource));
                        String xmlContent = FileUtil
                                .readXMLFileWithoutDeclaration(resourceFile);
                        metadataExists = StringUtils.startsWith(xmlContent,
                                "<metadata>")
                                && StringUtils.contains(xmlContent,
                                        "<smarterAppMetadata");
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to determind metadata exists " + e.getMessage(), e);
        }
        return metadataExists;
    }

    public static boolean isAPIPMetadataExists(String outputZipFolder,
            ResourceType resource) {
        boolean metadataExists = false;
        try {
            if (resource != null
                    && CollectionUtils.isNotEmpty(resource.getDependencies())) {
                for (DependencyType dependency : resource.getDependencies()) {
                    ResourceType dependentResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (dependentResource != null
                            && StringUtils.equals(dependentResource.getType(),
                                    IMSPackageConstants.IMS_METADATA_TYPE)
                            && StringUtils.isNotBlank(outputZipFolder
                                    + File.separator
                                    + IMSItemReader.getHref(dependentResource))) {
                        File resourceFile = new File(outputZipFolder
                                + File.separator
                                + IMSItemReader.getHref(dependentResource));
                        String xmlContent = FileUtil
                                .readXMLFileWithoutDeclaration(resourceFile);
                        metadataExists = StringUtils.startsWith(xmlContent,
                                "<metadata>")
                                && !StringUtils.contains(xmlContent,
                                        "<smarterAppMetadata");
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Unable to determind metadata exists " + e.getMessage(), e);
        }
        return metadataExists;
    }

}
