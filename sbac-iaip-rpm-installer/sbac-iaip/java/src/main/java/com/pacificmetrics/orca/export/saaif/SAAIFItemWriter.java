package com.pacificmetrics.orca.export.saaif;

import java.io.File;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.LocalBean;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;

import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.ContentAttachment;
import com.pacificmetrics.orca.entities.ContentExternalAttribute;
import com.pacificmetrics.orca.entities.Difficulty;
import com.pacificmetrics.orca.entities.ExternalContentMetadata;
import com.pacificmetrics.orca.entities.Genre;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemAssetAttribute;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.PassageMedia;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.saaif.ItemCharacterizationTypeConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.SAAIFItemUtil;
import com.pacificmetrics.saaif.metadata.SAAIFMetadataParser;

@Stateless
@LocalBean
public class SAAIFItemWriter {

    @EJB
    private ContentMoveServices contentMoveService;

    public SAAIFItem getItem(Item item) {
    	
    	List<String> extnMedia = new ArrayList<String>(Arrays.asList("mp3",
                "m4a", "m4v", "swf", "mp4", "ogg"));
        List<String> extnGraphic = new ArrayList<String>(Arrays.asList("gif",
                "png", "jpg", "jpeg", "svg"));
        
        SAAIFItem saaifItem = new SAAIFItem();

        saaifItem.setId(Long.toString(item.getId()));
        saaifItem.setUniqueId(item.getExternalId());
        saaifItem.setVersion(item.getVersion());
        saaifItem.setHref("item-" + item.getItemBankId() + "-"
                + saaifItem.getId() + ".xml");
        saaifItem.setHrefBase("Item_" + saaifItem.getId());
        saaifItem.setMetadataHrefBase("Item_" + saaifItem.getId());
        saaifItem.setMetadataHref("item-" + item.getItemBankId() + "-"
                + saaifItem.getId() + "_metadata.xml");
        saaifItem.setBankKey(Integer.toString(item.getItemBankId()));

        List<ContentExternalAttribute> itemContentExternalAttributeList = contentMoveService
                .findContentExternalAttributeByItemId(item.getId());

        List<ExternalContentMetadata> itemExternalContentMetadataList = contentMoveService
                .findExternalContentMetadatasByItemId(item.getId());

        List<ContentAttachment> itemContentAttachmentList = contentMoveService
                .findAttachmentsByItemId(item.getId());

        List<ItemAssetAttribute> itemAssetAttributeList = contentMoveService
                .findItemAssetsByItemId(item.getId());

        // finding item format if its not tutorial or wordlist
        if (CollectionUtils.isNotEmpty(itemContentExternalAttributeList)) {
            for (ContentExternalAttribute externalAttribute : itemContentExternalAttributeList) {

                if (!StringUtils.equalsIgnoreCase(
                        externalAttribute.getFormat(),
                        SAAIFPackageConstants.WORDLIST_FORMAT)
                        && !StringUtils.equalsIgnoreCase(
                                externalAttribute.getFormat(),
                                SAAIFPackageConstants.TUTORIAL_FORMAT)) {
                    saaifItem.setExternalId(externalAttribute.getExternalID());
                    saaifItem.setFormat(externalAttribute.getFormat());
                }
            }
        }

        // finding item attachments
        if (CollectionUtils.isNotEmpty(itemContentAttachmentList)) {
            Map<String, String> attachmentMap = new HashMap<String, String>();
            for (ContentAttachment attachment : itemContentAttachmentList) {
                attachmentMap.put(attachment.getFilename(),
                        attachment.getSourceUrl());
            }
            saaifItem.setAttachments(attachmentMap);
        }

        // finding item asset
        if (CollectionUtils.isNotEmpty(itemAssetAttributeList)) {
            Map<String, String> assetMap = new HashMap<String, String>();
            for (ItemAssetAttribute asset : itemAssetAttributeList) {
                assetMap.put(asset.getFileName(), asset.getSourceUrl());
            }
            saaifItem.setAssets(assetMap);
        }

        // item content and metadata content
        if (CollectionUtils.isNotEmpty(itemExternalContentMetadataList)) {
            for (ExternalContentMetadata contentMetadata : itemExternalContentMetadataList) {
                if (StringUtils.equalsIgnoreCase(
                        contentMetadata.getContentType(),
                        SAAIFPackageConstants.ITEM_TYPE)) {

                    String formatOrType = SAAIFItemUtil
                            .getFormatOrTypeOfItemFromString(contentMetadata
                                    .getContentData());
                    String itemId = SAAIFItemUtil
                            .getItemExternalIdFromString(contentMetadata
                                    .getContentData());
                    // tutorial content
                    if (StringUtils.equalsIgnoreCase(formatOrType,
                            SAAIFPackageConstants.TUTORIAL_FORMAT)) {
                        SAAIFItem tutorial = null;
                        if (!saaifItem.isTutorialAdded(itemId)) {
                            tutorial = new SAAIFItem();
                        } else {
                            tutorial = saaifItem.getTutorialById(itemId);
                        }
                        tutorial.setId(itemId);
                        tutorial.setVersion(item.getVersion());
                        tutorial.setBankKey(Integer.toString(item
                                .getItemBankId()));
                        tutorial.setId(itemId);

                        tutorial.setHref("item-" + item.getItemBankId() + "-"
                                + itemId + ".xml");
                        tutorial.setHrefBase("Item_" + itemId);
                        tutorial.setMetadataHrefBase("Item_" + itemId);
                        tutorial.setMetadataHref("item-" + item.getItemBankId()
                                + "-" + itemId + "_metadata.xml");

                        tutorial.setType(SAAIFPackageConstants.TUTORIAL_FORMAT);

                        tutorial.setXmlContent(contentMetadata.getContentData());
                        if (contentMetadata.getContentResources() != null) {
                            Map<String, String> attachments = readFilesFromPath(contentMetadata
                                    .getContentResources().getSourceUrl());
                            tutorial.setAttachments(attachments);
                        }

                        saaifItem.getTutorials().add(tutorial);
                    }
                    // wordlist content
                    if (StringUtils.equalsIgnoreCase(formatOrType,
                            SAAIFPackageConstants.WORDLIST_FORMAT)) {
                        SAAIFItem wordlist = null;
                        if (!saaifItem.isWordlistAdded(itemId)) {
                            wordlist = new SAAIFItem();
                        } else {
                            wordlist = saaifItem.getWordlistById(itemId);
                        }

                        wordlist.setId(itemId);
                        wordlist.setVersion(item.getVersion());
                        wordlist.setBankKey(Integer.toString(item
                                .getItemBankId()));

                        wordlist.setHref("item-" + item.getItemBankId() + "-"
                                + itemId + ".xml");
                        wordlist.setHrefBase("Item_" + itemId);
                        wordlist.setMetadataHrefBase("Item_" + itemId);
                        wordlist.setMetadataHref("item-" + item.getItemBankId()
                                + "-" + itemId + "_metadata.xml");
                        wordlist.setType(SAAIFPackageConstants.WORDLIST_FORMAT);

                        wordlist.setXmlContent(contentMetadata.getContentData());

                        saaifItem.getWordlists().add(wordlist);
                    }
                    // item content
                    if (!StringUtils.equalsIgnoreCase(formatOrType,
                            SAAIFPackageConstants.WORDLIST_FORMAT)
                            && !StringUtils.equalsIgnoreCase(formatOrType,
                                    SAAIFPackageConstants.TUTORIAL_FORMAT)) {
                        // TODO : Update original Item
                        String updatedXmlContent = SAAIFItemUtil
                                .setItemAttribute(
                                        contentMetadata.getContentData(),
                                        String.valueOf(item.getId()),
                                        String.valueOf(item.getItemBankId()),
                                        String.valueOf(item.getVersion()),
                                        item.getDescription(),
                                        item.getSubject(), item.getGradeLevel());
                        saaifItem.setXmlContent(updatedXmlContent);
                    }
                }

                if (StringUtils.equalsIgnoreCase(
                        contentMetadata.getContentType(),
                        SAAIFPackageConstants.METADATA_TYPE)) {
                    com.pacificmetrics.saaif.metadata.Metadata packageMetadata = SAAIFMetadataParser
                            .parseMetdata(contentMetadata.getContentData());
                    // tutorial metadata content
                    if (packageMetadata != null
                            && packageMetadata.getSmarterAppMetadata() != null
                            && StringUtils.equalsIgnoreCase(packageMetadata
                                    .getSmarterAppMetadata()
                                    .getInteractionType(),
                                    SAAIFPackageConstants.TUTORIAL_FORMAT)
                            && StringUtils.equalsIgnoreCase(
                                    contentMetadata.getContentType(),
                                    SAAIFPackageConstants.METADATA_TYPE)) {
                        SAAIFItem tutorial = null;
                        if (!saaifItem.isTutorialAdded(Integer
                                .toString(packageMetadata
                                        .getSmarterAppMetadata()
                                        .getIdentifier()))) {
                            tutorial = new SAAIFItem();
                            tutorial.setId(Integer.toString(packageMetadata
                                    .getSmarterAppMetadata().getIdentifier()));
                            saaifItem.getTutorials().add(tutorial);
                        } else {
                            tutorial = saaifItem.getTutorialById(Integer
                                    .toString(packageMetadata
                                            .getSmarterAppMetadata()
                                            .getIdentifier()));
                        }

                        tutorial.setMetadataXmlContent(contentMetadata
                                .getContentData());

                    }

                    // wordlist metadata content
                    if (packageMetadata != null
                            && packageMetadata.getSmarterAppMetadata() != null
                            && (StringUtils.equalsIgnoreCase(packageMetadata
                                    .getSmarterAppMetadata()
                                    .getInteractionType(),
                                    SAAIFPackageConstants.WORDLIST_FORMAT) || StringUtils
                                    .equalsIgnoreCase(packageMetadata
                                            .getSmarterAppMetadata()
                                            .getInteractionType(),
                                            SAAIFPackageConstants.WIT_FORMAT))
                            && StringUtils.equalsIgnoreCase(
                                    contentMetadata.getContentType(),
                                    SAAIFPackageConstants.METADATA_TYPE)) {
                        SAAIFItem wordlist = null;
                        if (!saaifItem.isWordlistAdded(Integer
                                .toString(packageMetadata
                                        .getSmarterAppMetadata()
                                        .getIdentifier()))) {
                            wordlist = new SAAIFItem();
                            wordlist.setId(Integer.toString(packageMetadata
                                    .getSmarterAppMetadata().getIdentifier()));
                            saaifItem.getWordlists().add(wordlist);
                        } else {
                            wordlist = saaifItem.getWordlistById(Integer
                                    .toString(packageMetadata
                                            .getSmarterAppMetadata()
                                            .getIdentifier()));
                        }

                        wordlist.setMetadataXmlContent(contentMetadata
                                .getContentData());
                    }

                    // item metadata content
                    if (packageMetadata != null
                            && packageMetadata.getSmarterAppMetadata() != null
                            && !StringUtils.equalsIgnoreCase(packageMetadata
                                    .getSmarterAppMetadata()
                                    .getInteractionType(),
                                    SAAIFPackageConstants.TUTORIAL_FORMAT)
                            && !StringUtils.equalsIgnoreCase(packageMetadata
                                    .getSmarterAppMetadata()
                                    .getInteractionType(),
                                    SAAIFPackageConstants.WORDLIST_FORMAT)
                            && StringUtils.equalsIgnoreCase(
                                    contentMetadata.getContentType(),
                                    SAAIFPackageConstants.METADATA_TYPE)) {
                        packageMetadata.getSmarterAppMetadata()
                                .setAlternateIdentifier(item.getExternalId());
                        Difficulty difficulty = contentMoveService
                                .findDifficultyById(item.getDifficulty());
                        String updatedXmlContent = SAAIFItemUtil
                                .setItemMetadataAttribute(
                                        contentMetadata.getContentData(),
                                        String.valueOf(item.getId()),
                                        item.getItemGuid(),
                                        item.getSubject(),
                                        item.getPoint(),
                                        difficulty != null ? difficulty
                                                .getName() : null,
                                        item.getDepthOfKnowdledge(),
                                        item.getItemPublicationStatus() != null ? item
                                                .getItemPublicationStatus()
                                                .getName() : null, item
                                                .getGradeLevel(), item
                                                .getMinimumGrade(), item
                                                .getMaximumGrade(), item
                                                .getPrimaryStandard(), item
                                                .getItemStandardList(), item
                                                .getDescription() != null ? item
                                                        .getDescription() : null);
                        saaifItem.setMetadataXmlContent(updatedXmlContent);
                    }
                }
            }
        }
        
        List<Object[]> itemCharacterizations = contentMoveService
                .findItemCharacterization(item.getId());
        if (CollectionUtils.isNotEmpty(itemCharacterizations)) {
            for (Object[] ic : itemCharacterizations) {
                int type = Integer.parseInt(ic[1].toString());
                int objId = Integer.parseInt(ic[2].toString());
                if (type == ItemCharacterizationTypeConstants.PASSAGE) {
                    Passage passage = contentMoveService.findPassageById(objId);	       
	                List<ExternalContentMetadata> passageExternalContentMetadataList = contentMoveService
	                        .findExternalContentMetadatasByPassageId(passage
	                                .getId());
	
	                List<ContentAttachment> passageContentAttachmentList = contentMoveService
	                        .findAttachmentsByPassageId(passage.getId());
	                
	                List<PassageMedia> passageMediaList = contentMoveService.findPassageMediaByPassage(passage.getId());
	
	                SAAIFItem saaifPassage = new SAAIFItem();
	                saaifPassage.setId(Long.toString(passage.getId()));
	                saaifPassage.setBankKey(Integer.toString(passage
	                        .getItemBankId()));
	
	                saaifPassage.setHref("stim-" + passage.getItemBankId() + "-"
	                        + saaifPassage.getId() + ".xml");
	                saaifPassage.setHrefBase("Stim_" + saaifPassage.getId());
	                saaifPassage
	                        .setMetadataHrefBase("Stim_" + saaifPassage.getId());
	                saaifPassage.setMetadataHref("stim-" + passage.getItemBankId()
	                        + "-" + saaifPassage.getId() + "_metadata.xml");
	
	                saaifPassage.setType(SAAIFPackageConstants.STIMULUS_FORMAT);
	
	                // passage content and metadata content
	                if (CollectionUtils
	                        .isNotEmpty(passageExternalContentMetadataList)) {
	                    for (ExternalContentMetadata contentMetadata : passageExternalContentMetadataList) {
	                        if (StringUtils.equalsIgnoreCase(
	                                contentMetadata.getContentType(),
	                                SAAIFPackageConstants.STIMULUS_TYPE)) {
	                            // TODO : update passage id
	                            String updatedXmlContent = SAAIFItemUtil
	                                    .setPassageAttribute(contentMetadata
	                                            .getContentData(), String
	                                            .valueOf(passage.getId()), String
	                                            .valueOf(passage.getItemBankId()),
	                                            String.valueOf(item.getVersion()),
	                                            passage.getSubject());
	                            saaifPassage.setXmlContent(updatedXmlContent);
	                        }
	                        if (StringUtils.equalsIgnoreCase(
	                                contentMetadata.getContentType(),
	                                SAAIFPackageConstants.METADATA_TYPE)) {
	                            // TODO : update metdata passage id
	                            Genre genre = contentMoveService
	                                    .findGenreById(passage.getGenre());
	                            String updatedXmlContent = SAAIFItemUtil
	                                    .setPassageMetadataAttribute(
	                                            contentMetadata.getContentData(),
	                                            String.valueOf(passage.getId()),
	                                            passage.getSubject(),
	                                            genre != null ? genre.getName()
	                                                    : null,
	                                            passage.getPassagePublicationStatus() != null ? passage
	                                                    .getPassagePublicationStatus()
	                                                    .getName()
	                                                    : null, passage
	                                                    .getGradeLevel(), passage
	                                                    .getMinimumGrade(), passage
	                                                    .getMaximumGrade());
	                            saaifPassage
	                                    .setMetadataXmlContent(updatedXmlContent);
	                        }
	                    }
	                }
	
	                if (CollectionUtils.isNotEmpty(passageContentAttachmentList)) {
	                    Map<String, String> passageAttachmentMap = new HashMap<String, String>();
	                    for (ContentAttachment attachment : passageContentAttachmentList) {
	                        passageAttachmentMap.put(attachment.getFilename(),
	                                attachment.getSourceUrl());
	                    }
	                    saaifPassage.setAttachments(passageAttachmentMap);
	                }
	                
	                if (CollectionUtils.isNotEmpty(passageMediaList)) {
	                    Map<String, String> passageMediaMap = new HashMap<String, String>();
	                    for (PassageMedia passageMedia : passageMediaList) {
	                    	String ext = FilenameUtils
	                                .getExtension(passageMedia.getSrvrFilename());
	                        if (extnMedia
	                                .contains(ext)) {
	                        	passageMediaMap.put(passageMedia.getSrvrFilename(),
	                        			IMSItemUtil.getPassageMediaDirPath(passage.getItemBankId(), passage.getId()) + File.separator
	    								+ passageMedia.getSrvrFilename());
	                        } else if (extnGraphic
	                                .contains(ext)) {
	                        	passageMediaMap.put(passageMedia.getSrvrFilename(),
	                        			IMSItemUtil.getPassageImageDirPath(passage.getItemBankId(), passage.getId()) + File.separator
	    								+ passageMedia.getSrvrFilename());
	                        }                    	
	                    }
	                    saaifPassage.setAssets(passageMediaMap);
	                }
	
	                String externalId = null;
	                if (CollectionUtils
	                        .isNotEmpty(itemContentExternalAttributeList)) {
	                    for (ContentExternalAttribute externalAttribute : itemContentExternalAttributeList) {
	                        externalId = externalAttribute.getExternalID();
	                        break;
	                    }
	                }
	
	                // FIXME : put images, cdesbac and Stim_ prefix path to
	                // server.peropeties file
	                String assetPath = ServerConfiguration
	                        .getProperty(ServerConfiguration.PASSAGES_DIRECTORY);
	                assetPath = assetPath
	                        + File.separator
	                        + "cdesbac"
	                        + File.separator
	                        + "images"
	                        + File.separator
	                        + ServerConfiguration
	                                .getProperty(ServerConfiguration.ITEM_BANK_METAFILE_DIR_PREFIX)
	                        + saaifPassage.getBankKey() + File.separator + "Stim_"
	                        + externalId;
	
//	                Map<String, String> passageAssetsMap = readFilesFromPath(assetPath);
//	                saaifPassage.setAssets(passageAssetsMap);
	
	                saaifItem.getPassages().add(saaifPassage);
	            }
            }
        }
        return saaifItem;
    }

    private static Map<String, String> readFilesFromPath(String filePath) {
        Map<String, String> filesMap = new HashMap<String, String>();
        File attachmentDir = new File(filePath);
        if (attachmentDir.exists()) {
            for (String fileName : attachmentDir.list()) {
                if (!fileName.endsWith(".xml")) {
                    filesMap.put(fileName, filePath + "/" + fileName);
                }
            }
        }
        return filesMap;
    }

}
