package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.ims.apip.cp.DependencyType;
import com.pacificmetrics.ims.apip.cp.Manifest;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.apip.qti.item.AssessmentItem;
import com.pacificmetrics.ims.apip.qti.item.RubricBlock;
import com.pacificmetrics.ims.qti.stimulus.AssessmentStimulus;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.loader.ImportErrorConstants;
import com.pacificmetrics.orca.utils.FileUtil;

@Stateless
public class IMSPackageReader {

    private static final Log LOGGER = LogFactory.getLog(IMSPackageReader.class);

    @EJB
    private transient ItemIDCounter itemCounter;

    @EJB
    private transient ContentMoveServices contentMoveServices;

    @EJB
    private transient IMSStimulusReader stimulusReader;

    private static final List<String> MEDIA_EXTS = new ArrayList<String>(
            Arrays.asList("mp3", "m4a", "m4v", "swf", "mp4", "ogg"));
    private static final List<String> GRAPHIC_EXTS = new ArrayList<String>(
            Arrays.asList("gif", "png", "jpg", "jpeg", "svg"));

    private static final Integer UNSUPPORTED_ITEM_FORMAT = 5;

    Map<String, Map<String, String>> extnMediaMap = new HashMap<String, Map<String, String>>();
    Map<String, Map<String, String>> extnGraphicMap = new HashMap<String, Map<String, String>>();

    public void readPackage(final String outputZipFolder, int itemBankId,
            ItemMoveMonitor itemMoveMonitor,
            Map<String, Map<String, String>> errorMap) {

        try {
            String manifestFilePath = outputZipFolder + File.separator
                    + IMSPackageConstants.MANIFST_FILE_NAME;
            Manifest manifest = IMSManifestReader
                    .readManifest(manifestFilePath);
            LOGGER.info("Reading manifest resources.");
            Map<String, ResourceType> resourceMap = IMSManifestReader
                    .readResources(manifest);
            LOGGER.info("Found " + resourceMap != null ? resourceMap.entrySet()
                    .size() : 0 + " manifest resources.");
            LOGGER.info("Reading package stimulus.");
            Map<String, AssessmentStimulus> stimulusMap = stimulusReader
                    .readPackageStimulus(outputZipFolder, resourceMap);
            LOGGER.info("Found " + resourceMap != null ? resourceMap.entrySet()
                    .size() : 0 + " package stimulus.");
            if (manifest != null
                    && manifest.getResources() != null
                    && CollectionUtils.isNotEmpty(manifest.getResources()
                            .getResources())) {
                for (ResourceType resource : manifest.getResources()
                        .getResources()) {
                    String filePath = outputZipFolder + File.separator
                            + IMSItemReader.getHref(resource);
                    LOGGER.info("Reading resource from file " + filePath);
                    File resourceFile = new File(filePath);

                    if (IMSPackageConstants.IMS_APIP_QTI_ITEM_TYPE_V2
                            .equalsIgnoreCase(resource.getType())
                            && !errorMap.keySet().contains(
                                    resourceFile.getName())) {
                        Map<String, String> subErrorMap = isMetadataValid(
                                outputZipFolder, errorMap, resource);
                        if (subErrorMap == null) {
                            LOGGER.info("Saving item from file " + filePath);
                            saveItem(outputZipFolder, itemBankId,
                                    itemMoveMonitor, resource, resourceMap,
                                    stimulusMap, errorMap);
                        } else if (subErrorMap != null) {
                            saveSubErrorMap(subErrorMap, resource,
                                    itemMoveMonitor);
                        }

                    } else if (IMSPackageConstants.IMS_APIP_QTI_ITEM_TYPE_V2
                            .equalsIgnoreCase(resource.getType())
                            && errorMap.keySet().contains(
                                    resourceFile.getName())) {
                        LOGGER.info("Skipping saving item from file "
                                + filePath
                                + " as one or more validation error associated with the item");
                        saveSubErrorMap(errorMap, resourceFile, resource,
                                itemMoveMonitor);
                    }

                }
            }
        } catch (Exception e) {
            LOGGER.error("Error importing package " + e.getMessage(), e);
        }
    }

    private Map<String, String> isMetadataValid(String outputZipFolder,
            Map<String, Map<String, String>> errorMap, ResourceType resource) {
        Map<String, String> subErrorMap = null;
        if (resource != null
                && CollectionUtils.isNotEmpty(resource.getDependencies())) {
            for (DependencyType dependency : resource.getDependencies()) {
                if (dependency.getIdentifierref() != null
                        && dependency.getIdentifierref() instanceof ResourceType) {
                    ResourceType dependentResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (IMSPackageConstants.IMS_METADATA_TYPE
                            .equalsIgnoreCase(dependentResource.getType())
                            && errorMap.containsKey(FilenameUtils
                                    .getName(IMSItemReader
                                            .getHref(dependentResource)))) {
                        subErrorMap = errorMap.get(FilenameUtils
                                .getName(IMSItemReader
                                        .getHref(dependentResource)));
                    }
                }
            }
        }
        return subErrorMap;
    }

    private void saveSubErrorMap(Map<String, String> subErrorMap,
            ResourceType resource, ItemMoveMonitor itemMoveMonitor) {
        try {
            if (subErrorMap != null) {
                List<ItemDetailStatus> itemDetailStatusList = new ArrayList<ItemDetailStatus>();
                for (String value : subErrorMap.keySet()) {
                    ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                    String errorId = value.split("#")[1];
                    DetailStatusType detailStatusType = contentMoveServices
                            .findDetailStatusTypeId(Integer.valueOf(errorId));
                    itemDetailStatus.setStatusDetail(subErrorMap.get(value));
                    itemDetailStatus.setDetailStatusType(detailStatusType);
                    itemDetailStatusList.add(itemDetailStatus);
                }

                saveErrorsDetailStatus(null, resource.getIdentifier(),
                        itemMoveMonitor, null, itemDetailStatusList);
            }

        } catch (Exception e) {
            LOGGER.error(
                    "Error saving validation error for item " + e.getMessage(),
                    e);
        }
    }

    private void saveSubErrorMap(Map<String, Map<String, String>> errorMap,
            File resourceFile, ResourceType resource,
            ItemMoveMonitor itemMoveMonitor) {
        try {
            Map<String, String> subErrorMap = errorMap.get(resourceFile
                    .getName());
            errorMap.remove(resourceFile.getName());

            if (subErrorMap != null) {
                List<ItemDetailStatus> itemDetailStatusList = new ArrayList<ItemDetailStatus>();
                for (String value : subErrorMap.keySet()) {
                    ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                    String errorId = value.split("#")[1];
                    DetailStatusType detailStatusType = contentMoveServices
                            .findDetailStatusTypeId(Integer.valueOf(errorId));
                    itemDetailStatus.setStatusDetail(subErrorMap.get(value));
                    itemDetailStatus.setDetailStatusType(detailStatusType);
                    itemDetailStatusList.add(itemDetailStatus);
                }

                saveErrorsDetailStatus(null, resource.getIdentifier(),
                        itemMoveMonitor, null, itemDetailStatusList);
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error saving validation error for item " + e.getMessage(),
                    e);
        }
    }

    private void saveItem(String outputZipFolder, int itemBankId,
            ItemMoveMonitor itemMoveMonitor, ResourceType resource,
            Map<String, ResourceType> resourceMap,
            Map<String, AssessmentStimulus> stimulusMap,
            Map<String, Map<String, String>> errorMap) {
        try {
            Map<String, String> assetMap = new HashMap<String, String>();
            Map<String, String> attachmentMap = new HashMap<String, String>();
            String filePath = outputZipFolder + File.separator
                    + IMSItemReader.getHref(resource);
            File itemFile = new File(filePath);
            AssessmentItem assessmentItem = IMSItemReader.readItem(filePath);

            if (assessmentItem != null) {
                String itemContent = FileUtil
                        .readXMLFileWithoutDeclaration(itemFile);
                String metadataContent = IMSItemReader.getMetadata(
                        outputZipFolder, resource, resourceMap);
                String identifier = assessmentItem.getIdentifier();
                LOGGER.info("Searching for previously importing item for program ID "
                        + itemMoveMonitor.getItemBank()
                        + " with external identifier " + identifier);
                Item existingItem = contentMoveServices.checkItem(
                        itemMoveMonitor.getItemBank(), identifier);
                if (existingItem == null) {
                    LOGGER.info("Importing item for program ID "
                            + itemMoveMonitor.getItemBank()
                            + " with external identifier " + identifier);
                    if (CollectionUtils.isNotEmpty(resource.getDependencies())) {
                        saveItemDependencies(outputZipFolder, itemBankId,
                                assessmentItem.getIdentifier(), resource,
                                resourceMap, assetMap, attachmentMap);
                    }
                    IMSMetadata itemMetadata = IMSItemReader.getItemMetadata(
                            outputZipFolder, resource, resourceMap);
                    String externalId = itemMoveMonitor.getItemBank()
                            .getExternalId().substring(0, 3)
                            + Calendar.getInstance().get(Calendar.YEAR)
                            + "-WCNONE-"
                            + String.format("%04d", itemCounter.nextItemID());
                    String itemDescription = StringUtils
                            .isNotBlank(itemMetadata.getDescription()) ? itemMetadata
                            .getDescription() : assessmentItem.getTitle();
                    LOGGER.info("Saving new Item with name " + externalId);
                    Item item = contentMoveServices.insertItem(externalId,
                            UNSUPPORTED_ITEM_FORMAT,
                            itemMoveMonitor.getItemBank(),
                            itemMoveMonitor.getUser(), itemDescription,
                            itemMetadata.getDifficulty(),
                            itemMetadata.getLanguage(),
                            itemMetadata.getPublicationStatus(),
                            metadataContent, itemMetadata.getPrimaryStandard(),
                            itemMetadata.getSecondaryStandards(), 0, null, 0);

                    LOGGER.info("Saving Item attachments for item "
                            + externalId);
                    // Insert the item attachments
                    Iterator it = attachmentMap.entrySet().iterator();
                    while (it.hasNext()) {
                        Map.Entry pairs = (Map.Entry) it.next();
                        if ("attachment".equalsIgnoreCase(pairs.getKey()
                                .toString().split("#")[1])) {
                            contentMoveServices
                                    .contentAttachment(pairs.getKey()
                                            .toString().split("#")[0], pairs
                                            .getValue().toString(), pairs
                                            .getKey().toString().split("#")[1],
                                            item, null, null);
                        }
                        it.remove(); // avoids a ConcurrentModificationException
                    }

                    LOGGER.info("Saving Item assets for item " + externalId);
                    // Insert the content assets
                    Iterator it2 = assetMap.entrySet().iterator();
                    while (it2.hasNext()) {
                        Map.Entry pairs = (Map.Entry) it2.next();
                        contentMoveServices.insertItemAssetAttribute(
                                "" /* Classification */, pairs.getKey()
                                        .toString(), item,
                                "" /* mediaDescription */, pairs.getValue()
                                        .toString(), itemMoveMonitor.getUser());
                        it2.remove(); // avoids a
                                      // ConcurrentModificationException
                    }

                    LOGGER.info("Saving Item metadata for item " + externalId);
                    persistItemMetadata(item, itemMetadata);

                    LOGGER.info("Saving Item external metadta for item "
                            + externalId);
                    contentMoveServices.insertExternalContentMetadata(
                            itemContent /* itemContent */,
                            resource.getType() /* contentType */, item, null,
                            null);
                    contentMoveServices
                            .insertExternalContentMetadata(
                                    metadataContent /* itemContent */,
                                    IMSPackageConstants.IMS_METADATA_TYPE /* contentType */,
                                    item, null, null);
                    LOGGER.info("Saving Item external attribute for item "
                            + externalId);
                    // Insert into Content External Attribute
                    contentMoveServices.insertContentExternalAttribute(
                            identifier, itemMetadata.getInteractionType(),
                            item, null);

                    if (isStimulusExists(resource)) {
                        List<ResourceType> stimulusResources = getStimulusResources(resource);
                        if (CollectionUtils.isNotEmpty(stimulusResources)) {
                            int stimulusSequence = 0;
                            for (ResourceType stimulusResource : stimulusResources) {
                                if (!errorMap
                                        .keySet()
                                        .contains(
                                                IMSItemReader
                                                        .getHref(stimulusResource))) {

                                    stimulusReader.saveStimulus(
                                            outputZipFolder, itemBankId, item,
                                            stimulusSequence, itemMoveMonitor,
                                            stimulusResource, resourceMap,
                                            stimulusMap);

                                }
                            }
                        }
                    }
                    LOGGER.info("Saving Item detail status for item "
                            + externalId);
                    saveSuccessItemDetailStatus(item, externalId,
                            itemMoveMonitor, identifier);

                    attachmentMap = new HashMap<String, String>();
                    assetMap = new HashMap<String, String>();
                    LOGGER.info("Successfully Imported item with Item ID "
                            + externalId + " into program with ID "
                            + itemBankId);

                } else {
                    LOGGER.info("Found previously importing item for program ID "
                            + itemMoveMonitor.getItemBank()
                            + " with identifier " + identifier);
                    /*
                     * 5 = Item Check ERROR for the Program
                     */
                    saveErrorDetailStatus(
                            ImportErrorConstants.ITEM_ALREADY_EXISTS,
                            itemMoveMonitor, identifier);
                }
            }
        } catch (Exception e) {
            LOGGER.error("Error Saving Item " + e.getMessage(), e);
        }
    }

    private boolean isStimulusExists(ResourceType resource) {
        boolean associatedStimulus = false;
        if (CollectionUtils.isNotEmpty(resource.getDependencies())) {
            for (DependencyType dependency : resource.getDependencies()) {
                if (dependency.getIdentifierref() != null
                        && (dependency.getIdentifierref() instanceof ResourceType && IMSPackageConstants.IMS_APIP_STIMULUS_TYPE
                                .equalsIgnoreCase(((ResourceType) dependency
                                        .getIdentifierref()).getType()))) {
                    associatedStimulus = true;
                }
            }
        }
        return associatedStimulus;
    }

    private List<ResourceType> getStimulusResources(ResourceType resource) {
        List<ResourceType> stimulusResources = new ArrayList<ResourceType>();
        if (CollectionUtils.isNotEmpty(resource.getDependencies())) {
            for (DependencyType dependency : resource.getDependencies()) {
                if (dependency.getIdentifierref() != null
                        && (dependency.getIdentifierref() instanceof ResourceType && IMSPackageConstants.IMS_APIP_STIMULUS_TYPE
                                .equalsIgnoreCase(((ResourceType) dependency
                                        .getIdentifierref()).getType()))) {
                    ResourceType stimulusResource = (ResourceType) dependency
                            .getIdentifierref();
                    stimulusResources.add(stimulusResource);
                }
            }
        }
        return stimulusResources;
    }

    private boolean isPassageRubricExist(AssessmentItem assessmentItem) {
        if (assessmentItem != null
                && assessmentItem.getItemBody() != null
                && CollectionUtils
                        .isNotEmpty(assessmentItem
                                .getItemBody()
                                .getRubricBlocksAndPositionObjectStagesAndCustomInteractions())) {
            for (Object block : assessmentItem
                    .getItemBody()
                    .getRubricBlocksAndPositionObjectStagesAndCustomInteractions()) {
                if (block instanceof RubricBlock
                        && CollectionUtils.isNotEmpty(((RubricBlock) block)
                                .getClazzs())
                        && ((RubricBlock) block).getClazzs()
                                .contains("passage")) {
                    return true;
                }
            }
        }
        return false;
    }

    private void savePassageRubric(AssessmentItem item) {
        if (item != null
                && item.getItemBody() != null
                && CollectionUtils
                        .isNotEmpty(item
                                .getItemBody()
                                .getRubricBlocksAndPositionObjectStagesAndCustomInteractions())) {
            for (Object block : item
                    .getItemBody()
                    .getRubricBlocksAndPositionObjectStagesAndCustomInteractions()) {
                if (block instanceof RubricBlock
                        && CollectionUtils.isNotEmpty(((RubricBlock) block)
                                .getClazzs())
                        && ((RubricBlock) block).getClazzs()
                                .contains("passage")) {
                    // do nothing
                }
            }
        }
    }

    private void persistItemMetadata(Item item, IMSMetadata imsMetadata) {
        // GRADE/LEVEL
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGrade())) {
            contentMoveServices.manageItemCharacterization(2,
                    imsMetadata.getGrade(), item.getId());
        }
        // CONTENT AREA
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getSubject())) {
            contentMoveServices.manageItemCharacterization(1,
                    imsMetadata.getSubject(), item.getId());
        }
        // POINTS
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getPoints())) {
            contentMoveServices.manageItemCharacterization(3,
                    imsMetadata.getPoints(), item.getId());
        }
        // GRADE SPAN START
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGradeStart())) {
            contentMoveServices.manageItemCharacterization(4,
                    imsMetadata.getGradeStart(), item.getId());
        }
        // GRADE SPAN END
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getGradeEnd())) {
            contentMoveServices.manageItemCharacterization(5,
                    imsMetadata.getGradeEnd(), item.getId());
        }
        // DOK
        if (imsMetadata != null
                && StringUtils.isNotBlank(imsMetadata.getDepthOfKnowledge())) {
            contentMoveServices.manageItemCharacterization(6,
                    imsMetadata.getDepthOfKnowledge(), item.getId());
        }
        LOGGER.info("Complete saving Item metadata for item "
                + item.getExternalId());
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

    private void saveSuccessItemDetailStatus(Item item, String identifier,
            ItemMoveMonitor itemMoveMonitor, String externalId) {

        List<ItemDetailStatus> itemDetailStatusList = new ArrayList<ItemDetailStatus>();

        ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
        DetailStatusType detailStatusType = contentMoveServices
                .findDetailStatusTypeId(ImportErrorConstants.IMPORT_SUCCESS);
        itemDetailStatus
                .setStatusDetail("Item has been imported successfully.");
        itemDetailStatus.setDetailStatusType(detailStatusType);
        itemDetailStatusList.add(itemDetailStatus);

        contentMoveServices.insertItemMoveDetails(identifier, itemMoveMonitor,
                item, itemDetailStatusList, externalId);
    }

    private void saveItemDependencies(String outputZipFolder, int itemBankId,
            String identifier, ResourceType resource,
            Map<String, ResourceType> resourceMap,
            Map<String, String> assetMap, Map<String, String> attachmentMap) {
        LOGGER.info("Saving resource dependencies for item with ID "
                + identifier);
        if (CollectionUtils.isNotEmpty(resource.getDependencies())) {
            LOGGER.info("Saving " + resource.getDependencies().size()
                    + " resource dependencies for item with ID " + identifier);
            for (DependencyType dependency : resource.getDependencies()) {
                String resourceKey = dependency.getIdentifierref() instanceof ResourceType ? ((ResourceType) dependency
                        .getIdentifierref()).getIdentifier() : null;
                ResourceType dependencyResource = resourceMap.get(resourceKey);

                if (dependencyResource != null
                        && IMSPackageConstants.IMS_CONTENT_TYPE
                                .equals(dependencyResource.getType())
                        && StringUtils.isNotEmpty(IMSItemReader
                                .getHref(dependencyResource))) {

                    String filePath = outputZipFolder + File.separator
                            + IMSItemReader.getHref(dependencyResource);
                    File sourceFile = new File(filePath);
                    if (MEDIA_EXTS.contains(FileUtil
                            .getFileExtension(sourceFile.getName()))
                            || GRAPHIC_EXTS.contains(FileUtil
                                    .getFileExtension(sourceFile.getName()))) {
                        String destinationFileName = IMSItemReader
                                .saveItemAssets(sourceFile, itemBankId,
                                        identifier);
                        if (StringUtils.isNotEmpty(destinationFileName)) {
                            assetMap.put(sourceFile.getName(),
                                    destinationFileName);
                        }
                    } else {
                        String destinationPath = IMSItemReader
                                .saveItemAttachment(sourceFile, itemBankId,
                                        identifier);
                        if (StringUtils.isNotEmpty(destinationPath)) {
                            attachmentMap.put(sourceFile.getName()
                                    + "#attachment", destinationPath);
                        }

                    }
                }
            }
        }
    }

}
