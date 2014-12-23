package com.pacificmetrics.orca.export.ims;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.ContentAttachment;
import com.pacificmetrics.orca.entities.ContentExternalAttribute;
import com.pacificmetrics.orca.entities.Difficulty;
import com.pacificmetrics.orca.entities.ExternalContentMetadata;
import com.pacificmetrics.orca.entities.Genre;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAssetAttribute;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.ims.IMSPackageConstants;

@Stateless
public class IMSItemWriter {

    private static final Log LOGGER = LogFactory.getLog(IMSItemWriter.class);

    @EJB
    private ContentMoveServices contentMoveService;

    public IMSItem getItem(Item item) {
        IMSItem imsItem = new IMSItem();

        imsItem.setIdentifier(Long.toString(item.getId()));
        imsItem.setTitle(item.getDescription());
        imsItem.setTimeDependent("false");
        imsItem.setAdaptive("false");
        imsItem.setBankKey(Integer.toString(item.getItemBankId()));
        imsItem.setHref("item-" + item.getItemBankId() + "-" + item.getId()
                + ".xml");
        imsItem.setHrefBase("Item_" + item.getId());
        imsItem.setMetadataHrefBase("Item_" + item.getId());
        imsItem.setMetadataHref("item-" + item.getItemBankId() + "-"
                + item.getId() + "_metadata.xml");

        updateAssets(imsItem, item);
        updateAttachments(imsItem, item);
        updateExteranlContent(imsItem, item);
        updateExternalContentMetadata(imsItem, item);

        updatePassages(imsItem, item);

        return imsItem;
    }

    private void updatePassages(IMSItem imsItem, Item item) {
        List<Passage> passages = contentMoveService.findPassagesByItemId(item
                .getId());

        if (CollectionUtils.isNotEmpty(passages)) {
            for (Passage passage : passages) {
                if (passage != null) {
                    IMSItem passageItem = new IMSItem();
                    passageItem.setBankKey(Integer.toString(item
                            .getItemBankId()));
                    passageItem.setIdentifier(Long.toString(passage.getId()));
                    passageItem.setHref("stim-" + passage.getItemBankId() + "-"
                            + passage.getId() + ".xml");
                    passageItem.setHrefBase("Stim_" + passage.getId());
                    passageItem.setMetadataHrefBase("Stim_" + passage.getId());
                    passageItem.setMetadataHref("stim-"
                            + passage.getItemBankId() + "-" + passage.getId()
                            + "_metadata.xml");
                    passageItem.setFormat(IMSPackageConstants.STIMULUS_FORMAT);

                    updatePassageExternalContent(passageItem, passage);
                    updatePassageAttachments(passageItem, passage);
                    updatePassageAssets(passageItem, item.getItemBankId(),
                            passage);

                    imsItem.getPassages().add(passageItem);
                }
            }
        }
    }

    private void updatePassageAssets(IMSItem passageItem, int itemBankId,
            Passage passage) {
        String imageDir = IMSItemUtil.getPassageImageDirPath(itemBankId,
                passage.getId());
        String mediaDir = IMSItemUtil.getPassageMediaDirPath(itemBankId,
                passage.getId());
        Map<String, String> mediaFileMap = IMSItemUtil
                .readFilesFromPath(imageDir);
        Map<String, String> imageFileMap = IMSItemUtil
                .readFilesFromPath(mediaDir);
        passageItem.getAssets().putAll(imageFileMap);
        passageItem.getAssets().putAll(mediaFileMap);
    }

    private void updatePassageAttachments(IMSItem passageItem, Passage passage) {
        List<ContentAttachment> passageContentAttachmentList = contentMoveService
                .findAttachmentsByPassageId(passage.getId());

        if (CollectionUtils.isNotEmpty(passageContentAttachmentList)) {
            Map<String, String> passageAttachmentMap = new HashMap<String, String>();
            for (ContentAttachment attachment : passageContentAttachmentList) {
                passageAttachmentMap.put(attachment.getFilename(),
                        attachment.getSourceUrl());
            }
            passageItem.setAttachments(passageAttachmentMap);
        }
    }

    private void updatePassageExternalContent(IMSItem passageItem,
            Passage passage) {
        List<ExternalContentMetadata> passageExternalContentMetadataList = contentMoveService
                .findExternalContentMetadatasByPassageId(passage.getId());
        if (CollectionUtils.isNotEmpty(passageExternalContentMetadataList)) {
            for (ExternalContentMetadata contentMetadata : passageExternalContentMetadataList) {
                if (StringUtils.equalsIgnoreCase(
                        contentMetadata.getContentType(),
                        IMSPackageConstants.IMS_APIP_STIMULUS_TYPE)) {
                    String updatedXmlContent = IMSItemUtil
                            .updatePassageXmlContent(
                                    contentMetadata.getContentData(),
                                    Integer.toString(passage.getId()),
                                    passage.getName());
                    passageItem.setXmlContent(updatedXmlContent);
                }
                if (StringUtils.equalsIgnoreCase(
                        contentMetadata.getContentType(),
                        IMSPackageConstants.IMS_METADATA_TYPE)) {
                    Genre genre = contentMoveService.findGenreById(passage
                            .getGenre());
                    String updatedXmlContent = IMSItemUtil
                            .updatePassageMetadata(
                                    contentMetadata.getContentData(), passage,
                                    genre.getName());
                    passageItem.setMetadataXmlContent(updatedXmlContent);
                }
            }
        }
    }

    private void updateExternalContentMetadata(IMSItem imsItem, Item item) {
        try {
            List<ExternalContentMetadata> itemExternalContentMetadataList = contentMoveService
                    .findExternalContentMetadatasByItemId(item.getId());
            // item content and metadata content
            if (CollectionUtils.isNotEmpty(itemExternalContentMetadataList)) {
                for (ExternalContentMetadata contentMetadata : itemExternalContentMetadataList) {
                    if (StringUtils.equalsIgnoreCase(
                            contentMetadata.getContentType(),
                            IMSPackageConstants.IMS_APIP_QTI_ITEM_TYPE_V2)) {
                        String updatedXmlContent = IMSItemUtil
                                .updateItemXmlContent(
                                        contentMetadata.getContentData(),
                                        imsItem.getIdentifier(),
                                        imsItem.getTitle());
                        imsItem.setXmlContent(updatedXmlContent);
                    }
                    if (StringUtils.equalsIgnoreCase(
                            contentMetadata.getContentType(),
                            IMSPackageConstants.IMS_METADATA_TYPE)) {
                        Difficulty difficulty = contentMoveService
                                .findDifficultyById(item.getDifficulty());
                        String updatedMetdataXmlContent = IMSItemUtil
                                .updateItemMetadata(
                                        contentMetadata.getContentData(), item,
                                        difficulty.getName());
                        imsItem.setMetadataXmlContent(updatedMetdataXmlContent);
                    }
                }
            }

        } catch (Exception e) {
            LOGGER.error(
                    "Error fetching external content metadata for the item "
                            + e.getMessage(), e);
        }
    }

    private void updateExteranlContent(IMSItem imsItem, Item item) {
        try {
            List<ContentExternalAttribute> itemContentExternalAttributeList = contentMoveService
                    .findContentExternalAttributeByItemId(item.getId());
            // finding item format
            if (CollectionUtils.isNotEmpty(itemContentExternalAttributeList)) {
                for (ContentExternalAttribute externalAttribute : itemContentExternalAttributeList) {
                    if (!StringUtils.equalsIgnoreCase(
                            externalAttribute.getFormat(),
                            IMSPackageConstants.STIMULUS_FORMAT)) {
                        imsItem.setExternalId(externalAttribute.getExternalID());
                        imsItem.setFormat(externalAttribute.getFormat());
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error fetching external attribute for the item "
                            + e.getMessage(), e);
        }

    }

    private void updateAttachments(IMSItem imsItem, Item item) {
        try {
            List<ContentAttachment> itemContentAttachmentList = contentMoveService
                    .findAttachmentsByItemId(item.getId());

            // finding item attachments
            if (CollectionUtils.isNotEmpty(itemContentAttachmentList)) {
                Map<String, String> attachmentMap = new HashMap<String, String>();
                for (ContentAttachment attachment : itemContentAttachmentList) {
                    attachmentMap.put(attachment.getFilename(),
                            attachment.getSourceUrl());
                }
                imsItem.setAttachments(attachmentMap);
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error fetching Attachments for the item " + e.getMessage(),
                    e);
        }
    }

    private void updateAssets(IMSItem imsItem, Item item) {
        try {
            List<ItemAssetAttribute> itemAssetAttributeList = contentMoveService
                    .findItemAssetsByItemId(item.getId());
            // finding item asset
            if (CollectionUtils.isNotEmpty(itemAssetAttributeList)) {
                Map<String, String> assetMap = new HashMap<String, String>();
                for (ItemAssetAttribute asset : itemAssetAttributeList) {
                    assetMap.put(asset.getFileName(), asset.getSourceUrl());
                }
                imsItem.setAssets(assetMap);
            }
        } catch (Exception e) {
            LOGGER.error(
                    "Error fetching Attachments for the item " + e.getMessage(),
                    e);
        }
    }
}
