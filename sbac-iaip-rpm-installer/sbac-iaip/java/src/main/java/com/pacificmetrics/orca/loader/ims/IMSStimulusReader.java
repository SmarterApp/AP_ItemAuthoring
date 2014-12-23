package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.w3.synthesis.ObjectFactory;

import com.pacificmetrics.ims.apip.cp.DependencyType;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.qti.stimulus.AssessmentStimulus;
import com.pacificmetrics.ims.qti.stimulus.StimulusBody;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.ContentExternalAttribute;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.loader.ImportErrorConstants;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;

@Stateless
public class IMSStimulusReader {

    private static final Log LOGGER = LogFactory
            .getLog(IMSStimulusReader.class);

    private static final List<String> EXTNMEDIA = new ArrayList<String>(
            Arrays.asList("mp3", "m4a", "m4v", "swf", "mp4", "ogg"));
    private static final List<String> EXTNGRAPHIC = new ArrayList<String>(
            Arrays.asList("gif", "png", "jpg", "jpeg", "svg"));

    @EJB
    ContentMoveServices contentMoveServices;

    public AssessmentStimulus readStimulus(String filePath) {
        AssessmentStimulus stimulus = null;
        LOGGER.info("Parsing manifest file from path " + filePath);
        try {
            File stimulusFile = new File(filePath);
            String stimulusContent = FileUtil
                    .readXMLFileWithoutDeclaration(stimulusFile);
            stimulus = JAXBUtil.unmershall(stimulusContent,
                    AssessmentStimulus.class, ObjectFactory.class);

        } catch (Exception e) {
            LOGGER.error("Unable to unmershall manifest file from path "
                    + filePath, e);
        }
        return stimulus;
    }

    public Map<String, AssessmentStimulus> readPackageStimulus(
            String outputZipFolder, Map<String, ResourceType> resourceMap) {
        Map<String, AssessmentStimulus> stimulusMap = new HashMap<String, AssessmentStimulus>();
        if (resourceMap != null
                && CollectionUtils.isNotEmpty(resourceMap.keySet())) {
            for (ResourceType resource : resourceMap.values()) {
                if (IMSPackageConstants.IMS_APIP_STIMULUS_TYPE
                        .equalsIgnoreCase(resource.getType())) {
                    String filePath = outputZipFolder + File.separator
                            + IMSItemReader.getHref(resource);
                    AssessmentStimulus assessmentStimulus = readStimulus(filePath);
                    if (assessmentStimulus != null) {
                        stimulusMap.put(assessmentStimulus.getIdentifier(),
                                assessmentStimulus);
                    }
                }
            }
        }
        return stimulusMap;
    }

    private String readMetadata(String outputZipFolder, ResourceType resource,
            Map<String, ResourceType> resourceMap) {
        String metadata = null;
        if (IMSItemUtil.isAPIPMetadataExists(outputZipFolder, resource)
                || IMSItemUtil.isSBACMetadataExists(outputZipFolder, resource)) {
            metadata = IMSManifestReader.readMetadataContent(outputZipFolder,
                    resource, resourceMap);
        }
        return metadata;
    }

    public void saveStimulus(String outputZipFolder, int itemBankId, Item item,
            int stimulusSequence, ItemMoveMonitor itemMoveMonitor,
            ResourceType resource, Map<String, ResourceType> resourceMap,
            Map<String, AssessmentStimulus> stimulusMap) {
        try {
            Map<String, String> attachmentMap = new HashMap<String, String>();
            Map<String, String> assetMap = new HashMap<String, String>();
            String filePath = outputZipFolder + File.separator
                    + IMSItemReader.getHref(resource);
            File stimulusFile = new File(filePath);
            AssessmentStimulus stimulus = readStimulus(filePath);

            if (stimulus != null) {
                String stimulusContent = FileUtil
                        .readXMLFileWithoutDeclaration(stimulusFile);
                String metadataContent = readMetadata(outputZipFolder,
                        resource, resourceMap);
                String identifier = stimulus.getIdentifier();
                checkDependentResources(outputZipFolder, resource, assetMap,
                        attachmentMap);
                LOGGER.info("Searching for previously importing stimulus for program ID "
                        + itemMoveMonitor.getItemBank()
                        + " with external identifier " + identifier);
                IMSMetadata imsMetadata = IMSItemReader.getItemMetadata(
                        outputZipFolder, resource, resourceMap);
                Passage existingPassage = isPassageExisting(itemMoveMonitor,
                        identifier, stimulus.getTitle());
                if (existingPassage == null) {
                    Passage passage = contentMoveServices.insertPassage(
                            itemMoveMonitor.getItemBank().getId(),
                            stimulus.getTitle(),
                            getPassageURL(itemMoveMonitor),
                            imsMetadata.getGenre(),
                            imsMetadata.getPublicationStatus());
                    if (passage != null) {

                        persistExternalAttribute(passage, identifier,
                                itemMoveMonitor, stimulusContent,
                                metadataContent);

                        persistMetadata(passage, imsMetadata);

                        persistPassageBody(itemMoveMonitor, passage, stimulus,
                                identifier);

                        persistPassageAssets(passage, itemMoveMonitor,
                                assetMap, attachmentMap, identifier);

                        if (item != null) {

                            contentMoveServices.manageItemCharacterization(7,
                                    String.valueOf(passage.getId()),
                                    item.getId());
                        }

                        saveSuccessPassageDetailStatus(passage,
                                passage.getName(), itemMoveMonitor, identifier);

                    }
                } else if (existingPassage != null
                        && (isDescriptionSame(stimulus, existingPassage) || isIdentifierSame(
                                stimulus, existingPassage))) {
                    if (item != null) {

                        contentMoveServices.manageItemCharacterization(7,
                                String.valueOf(existingPassage.getId()),
                                item.getId());
                    }
                } else {
                    LOGGER.info("Found previously importing passage for program ID "
                            + itemMoveMonitor.getItemBank()
                            + " with identifier " + identifier);

                    saveErrorDetailStatus(
                            ImportErrorConstants.PASSAGE_NAME_UNIQUE,
                            itemMoveMonitor, identifier);

                }
            }
        } catch (Exception e) {
            LOGGER.error("Error saving Stimulus " + e.getMessage(), e);
        }
    }

    private boolean isIdentifierSame(AssessmentStimulus stimulus,
            Passage existingPassage) {
        if (stimulus != null
                && existingPassage != null
                && CollectionUtils.isNotEmpty(existingPassage
                        .getContentExternalAttribute())) {
            for (ContentExternalAttribute contentExternalAttribute : existingPassage
                    .getContentExternalAttribute()) {
                return StringUtils.equalsIgnoreCase(
                        contentExternalAttribute.getExternalID(),
                        stimulus.getIdentifier());
            }
        }
        return false;
    }

    private boolean isDescriptionSame(AssessmentStimulus stimulus,
            Passage existingPassage) {
        return stimulus != null
                && existingPassage != null
                && StringUtils.equalsIgnoreCase(stimulus.getTitle(),
                        existingPassage.getName()) ? true : false;
    }

    private void persistItemPassageSet(Item item, Passage passage,
            int stimulusSequeunce) {
        try {
            LOGGER.info("Associating item " + item.getId() + " with passage "
                    + passage.getId());
            int stimulusSequeunceLocal = stimulusSequeunce;
            contentMoveServices.insertPassageItemSet(item, passage,
                    ++stimulusSequeunceLocal);
            LOGGER.info("Associated item " + item.getId() + " with passage "
                    + passage.getId());
        } catch (Exception e) {
            LOGGER.error(
                    "Error in associating item " + item.getId()
                            + " with passage " + passage.getId() + " "
                            + e.getMessage(), e);
        }
    }

    private void checkDependentResources(String outputZipFolder,
            ResourceType resource, Map<String, String> assetsMap,
            Map<String, String> attachmentMap) {
        if (resource != null
                && CollectionUtils.isNotEmpty(resource.getDependencies())) {
            for (DependencyType dependency : resource.getDependencies()) {
                if (dependency.getIdentifierref() != null
                        && dependency.getIdentifierref() instanceof ResourceType
                        && IMSPackageConstants.IMS_CONTENT_TYPE
                                .equalsIgnoreCase(((ResourceType) dependency
                                        .getIdentifierref()).getType())) {
                    ResourceType dependentResource = (ResourceType) dependency
                            .getIdentifierref();
                    String filePath = outputZipFolder + File.separator
                            + IMSItemReader.getHref(dependentResource);
                    String extension = FilenameUtils.getExtension(filePath);
                    String fileName = FilenameUtils.getName(filePath);
                    if (StringUtils.isNotEmpty(extension)
                            && (EXTNMEDIA.contains(extension) || EXTNGRAPHIC
                                    .contains(extension))) {
                        assetsMap.put(fileName, filePath);
                    } else if (StringUtils.isNotEmpty(extension)) {
                        attachmentMap.put(fileName, filePath);
                    }
                }
            }
        }
    }

    private void saveSuccessPassageDetailStatus(Passage passage,
            String identifier, ItemMoveMonitor itemMoveMonitor,
            String externalId) {

        List<ItemDetailStatus> itemDetailStatusList = new ArrayList<ItemDetailStatus>();

        ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
        DetailStatusType detailStatusType = contentMoveServices
                .findDetailStatusTypeId(ImportErrorConstants.IMPORT_SUCCESS);
        itemDetailStatus
                .setStatusDetail("Passage has been imported successfully.");
        itemDetailStatus.setDetailStatusType(detailStatusType);
        itemDetailStatusList.add(itemDetailStatus);

        contentMoveServices.insertPassageMoveDetails(identifier,
                itemMoveMonitor, passage, itemDetailStatusList, externalId);
    }

    private void saveErrorDetailStatus(int errorType,
            ItemMoveMonitor itemMoveMonitor, String identifier) {
        try {
            List<ItemDetailStatus> itemDetailStatusList = new ArrayList<ItemDetailStatus>();
            ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
            DetailStatusType detailStatusType = contentMoveServices
                    .findDetailStatusTypeId(errorType);
            itemDetailStatus.setStatusDetail(detailStatusType.getValue()
                    + itemMoveMonitor.getItemBank().getExternalId());
            itemDetailStatus.setDetailStatusType(detailStatusType);

            itemDetailStatusList.add(itemDetailStatus);
            saveErrorsDetailStatus(null, null, itemMoveMonitor, identifier,
                    itemDetailStatusList);
        } catch (Exception e) {
            LOGGER.error(
                    "Error saving Saving error Detail status " + e.getMessage(),
                    e);
        }
    }

    private void saveErrorsDetailStatus(Item item, String identifier,
            ItemMoveMonitor itemMoveMonitor, String externalId,
            List<ItemDetailStatus> itemDetailStatusList) {
        contentMoveServices.insertItemMoveDetails(identifier, itemMoveMonitor,
                item, itemDetailStatusList, externalId);
    }

    private String getPassageURL(ItemMoveMonitor itemMoveMonitor) {
        String passageFilePath = null;
        try {
            int nextPassageId = contentMoveServices.getMaxPassageId();
            passageFilePath = IMSItemUtil.getPassageSourceURL(itemMoveMonitor
                    .getItemBank().getId(), nextPassageId);
        } catch (Exception e) {
            LOGGER.error("Error determining Passage path " + e.getMessage(), e);
        }
        return passageFilePath;
    }

    private void persistPassageBody(ItemMoveMonitor itemMoveMonitor,
            Passage passage, AssessmentStimulus stimulus, String identifier) {
        try {
            LOGGER.info("Saving passage body for passage " + identifier);
            String passageFilePath = IMSItemUtil.getPassagePath(itemMoveMonitor
                    .getItemBank().getId(), passage.getId());
            File passageBodyFile = new File(passageFilePath);
            StimulusBody stimulusBody = stimulus.getStimulusBody();
            String passageContent = IMSItemUtil.getPassgaeBody(stimulusBody);
            StringBuilder passageBodyBuffer = new StringBuilder();
            passageBodyBuffer
                    .append("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">"
                            + "<html>"
                            + "  <head>"
                            + "      <link href=\"/cdesbac/style/uir.css\" rel=\"stylesheet\" type=\"text/css\" />"
                            + "  </head>"
                            + "    <body>"
                            + "      <script language=\"JavaScript\" src=\"/cdesbac/js/footnotes.js\"></script>");
            passageBodyBuffer.append(passageContent);
            passageBodyBuffer.append("</body>" + "</html> ");
            FileUtils.writeStringToFile(passageBodyFile,
                    passageBodyBuffer.toString());
            LOGGER.info("Saved passage body for passage " + identifier);
        } catch (Exception e) {
            LOGGER.error("Error saving passage body for passage " + identifier
                    + " " + e.getMessage(), e);
        }
    }

    private void persistExternalAttribute(Passage passage, String identifier,
            ItemMoveMonitor itemMoveMonitor, String passageContent,
            String metadataContent) {

        LOGGER.info("Saving passage external content metadata for passage "
                + identifier);

        contentMoveServices
                .insertExternalContentMetadata(passageContent,
                        IMSPackageConstants.IMS_APIP_STIMULUS_TYPE, null,
                        passage, null);
        contentMoveServices.insertExternalContentMetadata(metadataContent,
                IMSPackageConstants.IMS_METADATA_TYPE, null, passage, null);

        LOGGER.info("Saved passage external content metadatafor passage "
                + identifier);

        LOGGER.info("Saving passage content external attribute for passage "
                + identifier);

        contentMoveServices.insertContentExternalAttribute(identifier,
                IMSPackageConstants.STIMULUS_FORMAT, null, passage);

        LOGGER.info("Saved passage content external attribute for passage "
                + identifier);
    }

    private void persistPassageAssets(Passage passage,
            ItemMoveMonitor itemMoveMonitor, Map<String, String> assetMap,
            Map<String, String> attachmentMap, String identifier) {

        LOGGER.info("Saving passage attachments for passage " + identifier);
        Iterator it5 = attachmentMap.entrySet().iterator();
        while (it5.hasNext()) {
            Map.Entry pairsAttach = (Map.Entry) it5.next();
            String fileName = FilenameUtils.getName(pairsAttach.getValue()
                    .toString());
            String attachmentFilePath = IMSItemUtil.savePassageAttachment(
                    pairsAttach.getValue().toString(), fileName,
                    itemMoveMonitor.getItemBank().getId(), identifier);
            contentMoveServices.contentAttachment(pairsAttach.getKey()
                    .toString(), attachmentFilePath, "attachment", null,
                    passage, null);
            // avoids aConcurrentModificationException
            it5.remove();
        }

        SimpleDateFormat format = new SimpleDateFormat("yyyyMMdd_HHmmss");
        String currDateTime = format.format(new Date());

        LOGGER.info("Saving passage assets for passage " + identifier);
        Iterator it6 = assetMap.entrySet().iterator();
        while (it6.hasNext()) {
            Map.Entry pairsAsset = (Map.Entry) it6.next();
            String mediaName = FilenameUtils.getBaseName(pairsAsset.getKey()
                    .toString());

            String mediaExtn = FilenameUtils.getExtension(pairsAsset.getKey()
                    .toString());

            String serverFileName = mediaName + "_" + currDateTime + "."
                    + mediaExtn;
            String description = "";
            if (EXTNMEDIA.contains(mediaExtn)) {
                IMSItemUtil.savePassageMedia(pairsAsset.getValue().toString(),
                        serverFileName, itemMoveMonitor.getItemBank().getId(),
                        passage.getId());
                description = "audiofile";
            } else if (EXTNGRAPHIC.contains(mediaExtn)) {
                IMSItemUtil.savePassageImage(pairsAsset.getValue().toString(),
                        serverFileName, itemMoveMonitor.getItemBank().getId(),
                        passage.getId());
            }
            contentMoveServices.insertPassageMedia(pairsAsset.getKey()
                    .toString(), /* clientFilename */
                    description,/* description */
                    passage, serverFileName /* serverFilename */,
                    itemMoveMonitor.getUser());
            // avoids a ConcurrentModificationException
            it6.remove();
        }

    }

    private void persistMetadata(Passage passage, IMSMetadata imsMetadata) {

        // GRADE LEVEL
        if (passage != null && imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGrade())) {

            contentMoveServices.managePassageCharacterization(2,
                    imsMetadata.getGrade(), passage.getId());
        }
        // CONTENT AREA
        if (passage != null && imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getSubject())) {
            contentMoveServices.managePassageCharacterization(1,
                    imsMetadata.getSubject(), passage.getId());
        }

        // GRADE SPAN START

        if (passage != null && imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGradeStart())) {
            contentMoveServices.managePassageCharacterization(3,
                    imsMetadata.getGradeStart(), passage.getId());
        }

        // GRADE SPAN END

        if (passage != null && imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGradeEnd())) {
            contentMoveServices.managePassageCharacterization(4,
                    imsMetadata.getGradeEnd(), passage.getId());
        }
    }

    private Passage isPassageExisting(ItemMoveMonitor itemMoveMonitor,
            String identifier, String description) {
        Passage existingPassage = null;
        try {
            existingPassage = contentMoveServices.checkPassageByIdentifier(
                    itemMoveMonitor.getItemBank(), identifier);
            if (existingPassage == null) {
                existingPassage = contentMoveServices
                        .checkPassageByDescription(
                                itemMoveMonitor.getItemBank(), description);
            }
        } catch (Exception e) {
            LOGGER.error("Unable to find passage with identifier " + identifier
                    + " in the Item Bank "
                    + itemMoveMonitor.getItemBank().getId(), e);
        }
        return existingPassage;

    }
}
