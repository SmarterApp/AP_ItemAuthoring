package com.pacificmetrics.orca.loader.saaif;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.net.URL;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import javax.ejb.EJB;
import javax.ejb.Stateless;
import javax.ejb.TransactionAttribute;
import javax.ejb.TransactionAttributeType;
import javax.xml.XMLConstants;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.Schema;
import javax.xml.validation.SchemaFactory;
import javax.xml.validation.Validator;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.ContentResources;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.loader.ims.IMSItemUtil;
import com.pacificmetrics.orca.loader.ims.IMSPackageConstants;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.PropertyUtil;
import com.pacificmetrics.orca.utils.SAAIFItemUtil;
import com.pacificmetrics.orca.utils.ZipUtil;
import com.pacificmetrics.saaif.item.ImportExportErrorConstants;
import com.pacificmetrics.saaif.item1.AssessmentitemType;
import com.pacificmetrics.saaif.item1.ItemattribType;
import com.pacificmetrics.saaif.manifest.Manifest;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource.Dependency;
import com.pacificmetrics.saaif.metadata.Metadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata;
import com.pacificmetrics.saaif.metadata.Metadata.SmarterAppMetadata.StandardPublication;
import com.pacificmetrics.saaif.metadata.MetadataFieldConstants;
import com.pacificmetrics.saaif.metadata.SAAIFMetadataParser;
import com.pacificmetrics.saaif.passage1.PassageType;
import com.pacificmetrics.saaif.passage1.PassageattribType;
import com.pacificmetrics.saaif.passage1.PassagecontentType;
import com.pacificmetrics.saaif.tutorial.TutorialitemType;
import com.pacificmetrics.saaif.wordlist.WordlistitemType;

@Stateless
public class SAAIFPackageReader {

    @EJB
    private transient ItemServices itemServices;

    @EJB
    private transient ContentMoveServices contentMoveServices;

    private static final Log LOGGER = LogFactory
            .getLog(SAAIFPackageReader.class);

    public boolean unzipPackage(InputStream inputStream, String outputZipFolder) {
        try {
            // Step 1 : extract the package in temp folder
            ZipUtil.unzipPackage(inputStream, outputZipFolder);
            return true;
        } catch (Exception e) {
            LOGGER.error("Error in unziping package ", e);
        }
        return false;
    }

    @TransactionAttribute(TransactionAttributeType.SUPPORTS)
    public void readPackage(String outputZipFolder, int itemBankId,
            ItemMoveMonitor itemMoveMonitor,
            Map<String, Map<String, String>> errorMap) {
        Manifest manifest = null;
        Map<String, Resource> resourceMap = new HashMap<String, Resource>();
        Map<String, Map<String, String>> itemMap = new HashMap<String, Map<String, String>>();
        Map<String, Map<String, String>> passageMap = new HashMap<String, Map<String, String>>();
        Map<String, Map<String, String>> passageMetadataMap = new HashMap<String, Map<String, String>>();
        List<String> extnMedia = new ArrayList<String>(Arrays.asList("mp3",
                "m4a", "m4v", "swf", "mp4", "ogg"));
        List<String> extnGraphic = new ArrayList<String>(Arrays.asList("gif",
                "png", "jpg", "jpeg", "svg"));

        try {

            List<String> dependancyList = new ArrayList<String>();

            // Step 1 : read the manifest of the package

            File manifestFile = new File(outputZipFolder,
                    SAAIFPackageConstants.MANIFST_FILE_NAME);
            if (manifestFile != null) {
                InputStream manifestStream = new FileInputStream(manifestFile);
                manifest = SAAIFManifestReader.readManifest(manifestStream);
                resourceMap = SAAIFManifestReader.readResources(manifest);
                // Step 2 : read resources from the manifest
                if (manifest != null
                        && manifest.getResources() != null
                        && CollectionUtils.isNotEmpty(manifest.getResources()
                                .getResource())) {
                    for (Resource resource : manifest.getResources()
                            .getResource()) {
                        if (CollectionUtils
                                .isNotEmpty(resource.getDependency())) {
                            for (Dependency itemDependency : resource
                                    .getDependency()) {
                                Resource dependentResource = resourceMap
                                        .get(itemDependency.getIdentifierref());
                                dependancyList.add(FilenameUtils.getName(dependentResource.getFile()
                                        .getHref()));
                            }
                        }
                    }

                    for (Resource resource : manifest.getResources()
                            .getResource()) {

                        List<ItemDetailStatus> itemDetailStatuslist = new ArrayList<ItemDetailStatus>();

                        // If the dependent item resource is passage/stimuli
                        if (resource != null
                                && SAAIFPackageConstants.STIMULUS_TYPE
                                        .equalsIgnoreCase(resource.getType())) {
                            String passageDirName = resource.getFile()
                                    .getHref().split("/")[1];

                            String sourceFilePath = outputZipFolder + "/"
                                    + resource.getFile().getHref();

                            PassageType passage = SAAIFPassageReader
                                    .readPassage(sourceFilePath);
                            List<String> htmlFiles = new ArrayList<String>();
                            String passageMetadataContent = null;
                            Map<String, String> passageattachmentMap = new HashMap<String, String>();
                            Map<String, String> passageassetMap = new HashMap<String, String>();
                            int i = 60;
                            if (CollectionUtils
                                    .isNotEmpty(passage.getContent())) {
                                for (PassagecontentType content : passage
                                        .getContent()) {

                                    // TODO : extrat html from stem
                                    String htmlContent = "";
                                    // TODO : read maximum id + 1 from passage
                                    // table
                                    String htmlFileName = "file" + i + ".htm";
                                    String htmlFilePath = SAAIFPassageReader
                                            .savePassageHtml(htmlFileName,
                                                    htmlContent, itemBankId);
                                    htmlFiles.add(htmlFilePath);
                                }
                            }
                            if (CollectionUtils.isNotEmpty(resource
                                    .getDependency())) {
                                for (Dependency itemDependency : resource
                                        .getDependency()) {
                                    Resource passageDependentResource = resourceMap
                                            .get(itemDependency
                                                    .getIdentifierref());

                                    String passageSourcePath = outputZipFolder
                                            + "/"
                                            + passageDependentResource
                                                    .getFile().getHref();

                                    String passageFileName = FilenameUtils.getName(passageDependentResource
                                            .getFile().getHref());

                                    // If the dependent resource is metadata
                                    // file
                                    if (passageDependentResource != null
                                            && SAAIFPackageConstants.METADATA_TYPE
                                                    .equalsIgnoreCase(passageDependentResource
                                                            .getType())) {
                                        passageMetadataContent = FileUtil
                                                .readToString(passageSourcePath);
                                    }
                                    // If the dependent resource is content type
                                    if (passageDependentResource != null
                                            && SAAIFPackageConstants.CONTENT_TYPE
                                                    .equalsIgnoreCase(passageDependentResource
                                                            .getType())) {
                                        // if the resource is attachment
                                        if (SAAIFItemUtil.isAttachmentResource(
                                                passage, passageFileName)) {
                                            String resourcePath = SAAIFItemReader
                                                    .saveItemAttachment(
                                                            passageSourcePath,
                                                            passageFileName,
                                                            itemBankId,
                                                            passageDirName);
                                            passageattachmentMap.put(
                                                    passageFileName,
                                                    resourcePath);
                                        } else { // else save it under images
                                                 // folder
                                            String resourcePath = SAAIFItemReader
                                                    .saveItemAsset(
                                                            passageSourcePath,
                                                            passageFileName,
                                                            itemBankId,
                                                            passageDirName);
                                            passageassetMap.put(
                                                    passageFileName,
                                                    resourcePath);
                                        }
                                    }
                                }
                            }
                        }
                        // If the resource is of Item type
                        if (SAAIFPackageConstants.ITEM_TYPE
                                .equalsIgnoreCase(resource.getType())) {

                            Map<String, String> itemAttributeMap = new HashMap<String, String>();
                            String itemDirName = resource.getFile().getHref()
                                    .split("/")[1];
                            String fileName = FilenameUtils.getName(resource.getFile().getHref());
                            String sourceFilePath = outputZipFolder + "/"
                                    + resource.getFile().getHref();
                            String contentType = resource.getType();
                            String interactionType = "";

                            String formatOrType = SAAIFItemUtil
                                    .getFormatOrTypeOfItem(sourceFilePath);

                            // If the resource is tutorial
                            if (SAAIFPackageConstants.TUTORIAL_FORMAT
                                    .equalsIgnoreCase(formatOrType)) {
                                SAAIFItemReader.saveTutorial(sourceFilePath,
                                        fileName, 15, itemDirName);
                                if (CollectionUtils.isNotEmpty(resource
                                        .getDependency())) {
                                    for (Dependency dependency : resource
                                            .getDependency()) {
                                        Resource dependentResource = resourceMap
                                                .get(dependency
                                                        .getIdentifierref());
                                        if (dependentResource != null) {
                                            String dependentSourcePath = outputZipFolder
                                                    + "/"
                                                    + dependentResource
                                                            .getFile()
                                                            .getHref();
                                            String dependentFileName = FilenameUtils.getName(dependentResource
                                                    .getFile().getHref());
                                            SAAIFItemReader.saveTutorial(
                                                    dependentSourcePath,
                                                    dependentFileName,
                                                    itemBankId, itemDirName);
                                        }
                                    }
                                }
                                // TODO : update the content attachment
                            }
                            // If the source is of the wordlist
                            if (SAAIFPackageConstants.WORDLIST_FORMAT
                                    .equalsIgnoreCase(formatOrType)) {
                                SAAIFItemReader.saveWordList(sourceFilePath,
                                        fileName, 15, itemDirName);
                                if (CollectionUtils.isNotEmpty(resource
                                        .getDependency())) {
                                    for (Dependency dependency : resource
                                            .getDependency()) {
                                        Resource dependentResource = resourceMap
                                                .get(dependency
                                                        .getIdentifierref());
                                        if (dependentResource != null) {
                                            String dependentSourcePath = outputZipFolder
                                                    + "/"
                                                    + dependentResource
                                                            .getFile()
                                                            .getHref();
                                            String dependentFileName = FilenameUtils.getName(dependentResource
                                                    .getFile().getHref());                                                    
                                            SAAIFItemReader.saveWordList(
                                                    dependentSourcePath,
                                                    dependentFileName,
                                                    itemBankId, itemDirName);
                                        }
                                    }
                                }

                                // TODO : update the content attachment
                            }
                            // the resource is of Item type
                            if (!SAAIFPackageConstants.WORDLIST_FORMAT
                                    .equalsIgnoreCase(formatOrType)
                                    && !SAAIFPackageConstants.TUTORIAL_FORMAT
                                            .equalsIgnoreCase(formatOrType)) {
                                AssessmentitemType item = SAAIFItemReader
                                        .readItem(sourceFilePath);
                                // TODO : process Item
                                File itemFile = new File(sourceFilePath);
                                String itemContent = FileUtil
                                        .readXMLFileWithoutDeclaration(itemFile);
                                String metadataContent = "";

                                Map<String, String> attachmentMap = new HashMap<String, String>();
                                Map<String, String> assetsMap = new HashMap<String, String>();

                                Map<String, String> passageattachmentMap = new HashMap<String, String>();
                                Map<String, String> passageassetMap = new HashMap<String, String>();

                                if (CollectionUtils.isNotEmpty(resource
                                        .getDependency())) {

                                    String itemDescription = "";
                                    String itemXMLId = "";
                                    String itemFormat = "";
                                    String educationDifficulty = "";
                                    String points = "";
                                    String grade = "";
                                    String grdSpanStart = "";
                                    String grdSpanEnd = "";
                                    String depthOfKnowledge = "";
                                    String publicationStatus = "";
                                    String language = "";
                                    String alternateIdentifier = "";
                                    String imdExternalId = "";
                                    String primaryStandard = null;
                                    List<String> secondaryStandardList = new ArrayList<String>();

                                    if (item != null) {
                                        for (ItemattribType attrib : item
                                                .getAttriblist().getAttrib()) {
                                            if (StringUtils.equalsIgnoreCase(
                                                    "itm_item_desc",
                                                    attrib.getAttid())) {
                                                itemDescription = attrib
                                                        .getVal();
                                                /*
                                                 * Item Description
                                                 */
                                                break;
                                            }
                                        }

                                        itemXMLId = String
                                                .valueOf(item.getId());
                                        itemFormat = item.getFormat().value();
                                        imdExternalId = String.valueOf(item
                                                .getId());

                                        for (Dependency dependency : resource
                                                .getDependency()) {
                                            Resource dependentResource = resourceMap
                                                    .get(dependency
                                                            .getIdentifierref());
                                            String dependentSourcePath = outputZipFolder
                                                    + "/"
                                                    + dependentResource
                                                            .getFile()
                                                            .getHref();
                                            String dependentItemDir = dependentResource
                                                    .getFile().getHref()
                                                    .split("/")[1];
                                            String dependentFileName = FilenameUtils.getName(dependentResource
                                                    .getFile().getHref());
                                                    
                                            // handle dependent content of the
                                            // items
                                            if (dependentResource != null
                                                    && SAAIFPackageConstants.CONTENT_TYPE
                                                            .equalsIgnoreCase(dependentResource
                                                                    .getType())) {
                                                // if attachment then save it
                                                // under attachments folder
                                                if (SAAIFItemUtil
                                                        .isAttachmentResource(
                                                                item,
                                                                dependentFileName)) {
                                                    String resourcePath = SAAIFItemReader
                                                            .saveItemAttachment(
                                                                    dependentSourcePath,
                                                                    dependentFileName,
                                                                    itemBankId,
                                                                    itemDirName);
                                                    attachmentMap
                                                            .put(dependentFileName
                                                                    + "#attachment",
                                                                    dependentSourcePath);
                                                } else { // else save it under
                                                         // images folder
                                                    String resourcePath = SAAIFItemReader
                                                            .saveItemAsset(
                                                                    dependentSourcePath,
                                                                    dependentFileName,
                                                                    itemBankId,
                                                                    itemDirName);
                                                    assetsMap.put(
                                                            dependentFileName,
                                                            dependentSourcePath);
                                                }
                                            }
                                            // handle item metadata
                                            if (dependentResource != null
                                                    && SAAIFPackageConstants.METADATA_TYPE
                                                            .equalsIgnoreCase(dependentResource
                                                                    .getType())) {
                                                File metadataFile = new File(
                                                        dependentSourcePath);
                                                metadataContent = FileUtil
                                                        .readXMLFileWithoutDeclaration(metadataFile);

                                                Metadata metadata = SAAIFMetadataParser
                                                        .parseMetdata(metadataContent);
                                                educationDifficulty = metadata
                                                        .getSmarterAppMetadata()
                                                        .getEducationalDifficulty();
                                                language = metadata
                                                        .getSmarterAppMetadata()
                                                        .getLanguage().get(0);
                                                points = String
                                                        .valueOf(metadata
                                                                .getSmarterAppMetadata()
                                                                .getMaximumNumberOfPoints());
                                                grade = String
                                                        .valueOf(metadata
                                                                .getSmarterAppMetadata()
                                                                .getIntendedGrade());
                                                grdSpanStart = String
                                                        .valueOf(metadata
                                                                .getSmarterAppMetadata()
                                                                .getMinimumGrade());
                                                grdSpanEnd = String
                                                        .valueOf(metadata
                                                                .getSmarterAppMetadata()
                                                                .getMaximumGrade());
                                                depthOfKnowledge = String
                                                        .valueOf(metadata
                                                                .getSmarterAppMetadata()
                                                                .getDepthOfKnowledge());
                                                publicationStatus = metadata
                                                        .getSmarterAppMetadata()
                                                        .getStatus();
                                                alternateIdentifier = metadata
                                                        .getSmarterAppMetadata()
                                                        .getAlternateIdentifier();
                                                
                                                if(metadata != null && CollectionUtils.isNotEmpty(metadata.getSmarterAppMetadata().getStandardPublication())) {
	                                                primaryStandard = metadata
	                                                        .getSmarterAppMetadata().getStandardPublication().get(0)
	                                                        .getPrimaryStandard();
	                                                int spCount = 0;
	                                                for (StandardPublication sp : metadata
	                                                        .getSmarterAppMetadata().getStandardPublication()) {
	                                                	if (spCount > 0) {
	                                                		secondaryStandardList.add(sp.getPrimaryStandard());
	                                                	}
	                                                	if (!sp.getSecondaryStandard().isEmpty()) {
	                                                		for (int j = 0; j < sp.getSecondaryStandard().size(); j++) {
	                                                			secondaryStandardList.add(sp.getSecondaryStandard().get(j));
															}                                                		
	                                                	}
	                                                	spCount++;
													}
                                                }
                                               

                                                itemAttributeMap.put("type",
                                                        dependentResource
                                                                .getType());
                                                itemAttributeMap.put("content",
                                                        metadataContent);
                                                itemAttributeMap.put(
                                                        "sourceType",
                                                        "itemMetadata");
                                                itemMap.put(dependentFileName,
                                                        itemAttributeMap);
                                                itemAttributeMap = new HashMap<String, String>();

                                            }
                                            // handle item dependency
                                            if (dependentResource != null
                                                    && SAAIFPackageConstants.ITEM_TYPE
                                                            .equalsIgnoreCase(dependentResource
                                                                    .getType())) {
                                                String dependentFormatOrType = SAAIFItemUtil
                                                        .getFormatOrTypeOfItem(dependentSourcePath);
                                                String dependentItemId = SAAIFItemUtil
                                                        .getItemExternalId(dependentSourcePath);

                                                // If the dependent item
                                                // resource is tutorial
                                                if (SAAIFPackageConstants.TUTORIAL_FORMAT
                                                        .equalsIgnoreCase(dependentFormatOrType)) {

                                                    TutorialitemType dependentItem = SAAIFItemReader
                                                            .readTutorialFromPath(dependentSourcePath);

                                                    String tutorialPath = SAAIFItemReader
                                                            .saveTutorial(
                                                                    dependentSourcePath,
                                                                    dependentFileName,
                                                                    itemBankId,
                                                                    dependentItemDir);
                                                    if (CollectionUtils
                                                            .isNotEmpty(dependentResource
                                                                    .getDependency())) {

                                                        itemAttributeMap
                                                                .put("type",
                                                                        dependentResource
                                                                                .getType());
                                                        itemAttributeMap
                                                                .put("content",
                                                                        FileUtil.readXMLFileWithoutDeclaration(new File(
                                                                                dependentSourcePath)));
                                                        itemAttributeMap
                                                                .put("itemId",
                                                                        dependentItemId);
                                                        itemAttributeMap
                                                                .put("itemFormat",
                                                                        dependentFormatOrType);
                                                        itemAttributeMap
                                                                .put("source",
                                                                        tutorialPath
                                                                                .substring(
                                                                                        0,
                                                                                        tutorialPath
                                                                                                .lastIndexOf(File.separator)));
                                                        itemAttributeMap
                                                                .put("sourceType",
                                                                        SAAIFPackageConstants.TUTORIAL_FORMAT);
                                                        itemMap.put(
                                                                dependentFileName,
                                                                itemAttributeMap);
                                                        itemAttributeMap = new HashMap<String, String>();

                                                        for (Dependency itemDependency : dependentResource
                                                                .getDependency()) {
                                                            Resource itemDependentResource = resourceMap
                                                                    .get(itemDependency
                                                                            .getIdentifierref());

                                                            if (itemDependentResource != null) {
                                                                String itemDependentSourcePath = outputZipFolder
                                                                        + "/"
                                                                        + itemDependentResource
                                                                                .getFile()
                                                                                .getHref();
                                                                String itemDependentFileName = FilenameUtils.getName(itemDependentResource
                                                                        .getFile()
                                                                        .getHref());                                                                        
                                                                SAAIFItemReader
                                                                        .saveTutorial(
                                                                                itemDependentSourcePath,
                                                                                itemDependentFileName,
                                                                                itemBankId,
                                                                                dependentItemDir);

                                                                // If the
                                                                // dependent
                                                                // resource is
                                                                // resource file
                                                                if (itemDependentResource != null
                                                                        && SAAIFPackageConstants.CONTENT_TYPE
                                                                                .equalsIgnoreCase(itemDependentResource
                                                                                        .getType())) {
                                                                    // if
                                                                    // attachment
                                                                    // then save
                                                                    // it under
                                                                    // attachments
                                                                    // folder
                                                                    if (SAAIFItemUtil
                                                                            .isAttachmentResource(
                                                                                    dependentItem,
                                                                                    itemDependentFileName)) {
                                                                        String resourcePath = SAAIFItemReader
                                                                                .saveItemAttachment(
                                                                                        itemDependentSourcePath,
                                                                                        itemDependentFileName,
                                                                                        itemBankId,
                                                                                        dependentItemDir);
                                                                        attachmentMap
                                                                                .put(itemDependentFileName
                                                                                        + "#"
                                                                                        + SAAIFPackageConstants.TUTORIAL_FORMAT,
                                                                                        resourcePath);
                                                                    } else { // else
                                                                             // save
                                                                             // it
                                                                             // under
                                                                             // images
                                                                             // folder

                                                                        String resourcePath = SAAIFItemReader
                                                                                .saveTutorial(
                                                                                        itemDependentSourcePath,
                                                                                        itemDependentFileName,
                                                                                        itemBankId,
                                                                                        dependentItemDir);

                                                                    }
                                                                }

                                                                // If the
                                                                // dependent
                                                                // resource is
                                                                // metadata file
                                                                if (itemDependentResource != null
                                                                        && SAAIFPackageConstants.METADATA_TYPE
                                                                                .equalsIgnoreCase(itemDependentResource
                                                                                        .getType())) {
                                                                    String tutorialMetadataContent = FileUtil
                                                                            .readXMLFileWithoutDeclaration(new File(
                                                                                    itemDependentSourcePath));

                                                                    itemAttributeMap
                                                                            .put("type",
                                                                                    itemDependentResource
                                                                                            .getType());
                                                                    itemAttributeMap
                                                                            .put("content",
                                                                                    tutorialMetadataContent);
                                                                    itemAttributeMap
                                                                            .put("sourceType",
                                                                                    SAAIFPackageConstants.TUTORIAL_FORMAT
                                                                                            + "Metadata");
                                                                    itemMap.put(
                                                                            itemDependentFileName,
                                                                            itemAttributeMap);
                                                                    itemAttributeMap = new HashMap<String, String>();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                // If the dependent item
                                                // resource is wordlist
                                                if (SAAIFPackageConstants.WORDLIST_FORMAT
                                                        .equalsIgnoreCase(dependentFormatOrType)) {
                                                    WordlistitemType dependentItem = SAAIFItemReader
                                                            .readWordlistFromPath(dependentSourcePath);

                                                    String wordlistPath = SAAIFItemReader
                                                            .saveWordList(
                                                                    dependentSourcePath,
                                                                    dependentFileName,
                                                                    itemBankId,
                                                                    dependentItemDir);
                                                    if (CollectionUtils
                                                            .isNotEmpty(dependentResource
                                                                    .getDependency())) {

                                                        itemAttributeMap
                                                                .put("type",
                                                                        dependentResource
                                                                                .getType());
                                                        itemAttributeMap
                                                                .put("content",
                                                                        FileUtil.readXMLFileWithoutDeclaration(new File(
                                                                                dependentSourcePath)));
                                                        itemAttributeMap
                                                                .put("itemId",
                                                                        String.valueOf(dependentItem
                                                                                .getId()));
                                                        itemAttributeMap
                                                                .put("itemFormat",
                                                                        dependentItem
                                                                                .getType());
                                                        itemAttributeMap
                                                                .put("source",
                                                                        wordlistPath
                                                                                .substring(
                                                                                        0,
                                                                                        wordlistPath
                                                                                                .lastIndexOf(File.separator)));
                                                        itemAttributeMap
                                                                .put("sourceType",
                                                                        SAAIFPackageConstants.WORDLIST_FORMAT);
                                                        itemMap.put(
                                                                dependentFileName,
                                                                itemAttributeMap);
                                                        itemAttributeMap = new HashMap<String, String>();

                                                        for (Dependency itemDependency : dependentResource
                                                                .getDependency()) {
                                                            Resource itemDependentResource = resourceMap
                                                                    .get(itemDependency
                                                                            .getIdentifierref());

                                                            if (itemDependentResource != null) {
                                                                String itemDependentSourcePath = outputZipFolder
                                                                        + "/"
                                                                        + itemDependentResource
                                                                                .getFile()
                                                                                .getHref();
                                                                String itemDependentFileName = FilenameUtils.getName(itemDependentResource
                                                                        .getFile()
                                                                        .getHref());                                                                       
                                                                SAAIFItemReader
                                                                        .saveWordList(
                                                                                itemDependentSourcePath,
                                                                                itemDependentFileName,
                                                                                itemBankId,
                                                                                dependentItemDir);

                                                                // If the
                                                                // dependent
                                                                // resource is
                                                                // resource file
                                                                if (itemDependentResource != null
                                                                        && SAAIFPackageConstants.CONTENT_TYPE
                                                                                .equalsIgnoreCase(itemDependentResource
                                                                                        .getType())) {
                                                                    // if
                                                                    // attachment
                                                                    // then save
                                                                    // it under
                                                                    // attachments
                                                                    // folder
                                                                    // else save
                                                                    // it under
                                                                    // images
                                                                    // folder

                                                                    String resourcePath = SAAIFItemReader
                                                                            .saveWordList(
                                                                                    itemDependentSourcePath,
                                                                                    itemDependentFileName,
                                                                                    itemBankId,
                                                                                    dependentItemDir);
                                                                    assetsMap
                                                                            .put(itemDependentFileName,
                                                                                    resourcePath);

                                                                }

                                                                if (itemDependentResource != null
                                                                        && SAAIFPackageConstants.METADATA_TYPE
                                                                                .equalsIgnoreCase(itemDependentResource
                                                                                        .getType())) {
                                                                    String wordlistMetadataContent = FileUtil
                                                                            .readXMLFileWithoutDeclaration(new File(
                                                                                    itemDependentSourcePath));

                                                                    itemAttributeMap
                                                                            .put("type",
                                                                                    itemDependentResource
                                                                                            .getType());
                                                                    itemAttributeMap
                                                                            .put("content",
                                                                                    wordlistMetadataContent);
                                                                    itemAttributeMap
                                                                            .put("sourceType",
                                                                                    SAAIFPackageConstants.WORDLIST_FORMAT
                                                                                            + "Metadata");
                                                                    itemMap.put(
                                                                            itemDependentFileName,
                                                                            itemAttributeMap);
                                                                    itemAttributeMap = new HashMap<String, String>();
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            // If the dependent item resource is
                                            // passage/stimuli
                                            if (dependentResource != null
                                                    && SAAIFPackageConstants.STIMULUS_TYPE
                                                            .equalsIgnoreCase(dependentResource
                                                                    .getType())) {
                                                Map<String, String> passageAttributeMap = new HashMap<String, String>();                                                
                                                PassageType passage = SAAIFPassageReader
                                                        .readPassage(dependentSourcePath);
                                                
                                                String passageMetadataContent = null;
                                                
                                                if (CollectionUtils
                                                        .isNotEmpty(dependentResource
                                                                .getDependency())) {

                                                    passageAttributeMap.put(
                                                            "type",
                                                            dependentResource
                                                                    .getType());
                                                    passageAttributeMap
                                                            .put("content",
                                                                    FileUtil.readXMLFileWithoutDeclaration(new File(
                                                                            dependentSourcePath)));
                                                    passageAttributeMap
                                                            .put("passageId",
                                                                    String.valueOf(passage
                                                                            .getId()));
                                                    for (PassageattribType attrib : passage
                                                            .getAttriblist()
                                                            .getAttrib()) {
                                                        if (StringUtils
                                                                .equalsIgnoreCase(
                                                                        "stm_pass_subject",
                                                                        attrib.getAttid())) {
                                                            passageAttributeMap
                                                                    .put("subject",
                                                                            attrib.getVal()); /*
                                                                                               * Passage
                                                                                               * Subject
                                                                                               */
                                                        } else if (StringUtils
                                                                .equalsIgnoreCase(
                                                                        "stm_pass_desc",
                                                                        attrib.getAttid())) {
                                                            passageAttributeMap
                                                                    .put("description",
                                                                            attrib.getVal()); /*
                                                                                               * Passage
                                                                                               * Description
                                                                                               */
                                                        }
                                                    }

                                                    passageAttributeMap
                                                            .put("source",
                                                                    "");
                                                    passageMap
                                                            .put(dependentFileName,
                                                                    passageAttributeMap);
                                                    passageAttributeMap = new HashMap<String, String>();

                                                    for (Dependency itemDependency : dependentResource
                                                            .getDependency()) {
                                                        Resource passageDependentResource = resourceMap
                                                                .get(itemDependency
                                                                        .getIdentifierref());

                                                        String passageSourcePath = outputZipFolder
                                                                + "/"
                                                                + passageDependentResource
                                                                        .getFile()
                                                                        .getHref();
                                                        String passageDirName = passageDependentResource
                                                                .getFile()
                                                                .getHref()
                                                                .split("/")[1];
                                                        String passageFileName = FilenameUtils.getName(passageDependentResource
                                                                .getFile()
                                                                .getHref());                                                               

                                                        // If the dependent
                                                        // resource is metadata
                                                        // file
                                                        if (passageDependentResource != null
                                                                && SAAIFPackageConstants.METADATA_TYPE
                                                                        .equalsIgnoreCase(passageDependentResource
                                                                                .getType())) {
                                                            passageMetadataContent = FileUtil
                                                                    .readXMLFileWithoutDeclaration(new File(
                                                                            passageSourcePath));
                                                            Metadata metadata = SAAIFMetadataParser
                                                                    .parseMetdata(passageMetadataContent);
                                                            interactionType = metadata
                                                                    .getSmarterAppMetadata()
                                                                    .getInteractionType();
                                                            passageAttributeMap
                                                                    .put("type",
                                                                            passageDependentResource
                                                                                    .getType());
                                                            passageAttributeMap
                                                                    .put("content",
                                                                            passageMetadataContent);
                                                            passageAttributeMap
                                                                    .put("grade",
                                                                            String.valueOf(metadata
                                                                                    .getSmarterAppMetadata()
                                                                                    .getIntendedGrade()));
                                                            passageAttributeMap
                                                                    .put("gradeSpanStart",
                                                                            String.valueOf(metadata
                                                                                    .getSmarterAppMetadata()
                                                                                    .getMinimumGrade()));
                                                            passageAttributeMap
                                                                    .put("gradeSpanEnd",
                                                                            String.valueOf(metadata
                                                                                    .getSmarterAppMetadata()
                                                                                    .getMaximumGrade()));
                                                            passageAttributeMap
                                                                    .put("genre",
                                                                            metadata.getSmarterAppMetadata()
                                                                                    .getStimulusGenre());
                                                            passageAttributeMap
                                                                    .put("publicationStatus",
                                                                            metadata.getSmarterAppMetadata()
                                                                                    .getStatus());
                                                            passageMetadataMap
                                                                    .put(dependentFileName,
                                                                            passageAttributeMap);
                                                            passageAttributeMap = new HashMap<String, String>();
                                                        }
                                                        // If the dependent
                                                        // resource is content
                                                        // type
                                                        if (passageDependentResource != null
                                                                && SAAIFPackageConstants.CONTENT_TYPE
                                                                        .equalsIgnoreCase(passageDependentResource
                                                                                .getType())) {

                                                            // if the resource
                                                            // is attachment
                                                            if (SAAIFItemUtil
                                                                    .isAttachmentResource(
                                                                            passage,
                                                                            passageFileName)) {                                                                
                                                                passageattachmentMap
                                                                        .put(passageFileName,
                                                                        		passageSourcePath);
                                                            } else { // else
                                                                     // save it
                                                                     // under
                                                                     // images
                                                                     // folder                                                                
                                                                passageassetMap
                                                                        .put(passageFileName,
                                                                        		passageSourcePath);
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // ########### CREATE ITEM DATABASE
                                        // RECORD ################
                                        // ########################################################

                                        com.pacificmetrics.orca.entities.Item insertedItem = null;
                                        String externalId = itemMoveMonitor
                                                .getItemBank().getExternalId()
                                                .substring(0, 3)
                                                + Calendar.getInstance().get(
                                                        Calendar.YEAR)
                                                + "-WCNONE-"
                                                + String.format(
                                                        "%04d",
                                                        itemServices
                                                                .getMaxItemId() + 1);

                                        imdExternalId = (imdExternalId != null
                                                && !("").equals(imdExternalId) ? imdExternalId
                                                : itemDirName);

                                        boolean passagePass = true;
                                        List<String> errorPassageList = new ArrayList<String>();
                                        for (Entry<String, Map<String, String>> entry : passageMap
                                                .entrySet()) {
                                            Map<String, String> tempMap = entry
                                                    .getValue();
                                            com.pacificmetrics.orca.entities.Passage fetchedPassage = contentMoveServices
                                                    .checkPassageByIdentifier(
                                                            itemMoveMonitor
                                                                    .getItemBank(),
                                                            tempMap.get("passageId"));
                                            if (fetchedPassage == null) {
                                                fetchedPassage = contentMoveServices
                                                        .checkPassageByDescription(
                                                                itemMoveMonitor
                                                                        .getItemBank(),
                                                                tempMap.get("description"));
                                                if (fetchedPassage != null) {
                                                    String placeHolder = ImportExportErrorConstants.PASSAGE_UNIQUE
                                                            .replace(
                                                                    "<passageName>",
                                                                    tempMap.get("description"));
                                                    placeHolder = placeHolder
                                                            .replace(
                                                                    "<programName>",
                                                                    itemMoveMonitor
                                                                            .getItemBank()
                                                                            .getExternalId());
                                                    placeHolder = placeHolder
                                                            .replace(
                                                                    "<passageId>",
                                                                    tempMap.get("passageId"));
                                                    errorPassageList
                                                            .add(placeHolder);
                                                    passagePass = false;
                                                }
                                            }
                                        }

                                        com.pacificmetrics.orca.entities.Item fetchedItem = contentMoveServices
                                                .checkItem(itemMoveMonitor
                                                        .getItemBank(),
                                                        imdExternalId);

                                        if (passagePass
                                                && (((alternateIdentifier == null || ("")
                                                        .equals(alternateIdentifier)) && fetchedItem == null) || (alternateIdentifier != null && !("")
                                                        .equals(alternateIdentifier)))) {

                                            // Insert into Item & Item
                                            // Characterization
                                            if (!errorMap
                                                    .containsKey(imdExternalId)) {
                                                if (fetchedItem == null) {
                                                    insertedItem = contentMoveServices
                                                            .insertItem(
                                                                    externalId,
                                                                    5,
                                                                    itemMoveMonitor
                                                                            .getItemBank(),
                                                                    itemMoveMonitor
                                                                            .getUser(),
                                                                    itemDescription,
                                                                    educationDifficulty,
                                                                    language,
                                                                    publicationStatus,
                                                                    metadataContent,
                                                                    primaryStandard,
                                                                    secondaryStandardList,
                                                                    0, null, 0);
                                                } else {
                                                    insertedItem = contentMoveServices
                                                            .insertItem(
                                                                    fetchedItem
                                                                            .getExternalId(),
                                                                    5 /*
                                                                       * (
                                                                       * Unsupported
                                                                       * )
                                                                       */
                                                                    ,
                                                                    itemMoveMonitor
                                                                            .getItemBank(),
                                                                    itemMoveMonitor
                                                                            .getUser(),
                                                                    itemDescription,
                                                                    educationDifficulty,
                                                                    language,
                                                                    publicationStatus,
                                                                    metadataContent,
                                                                    primaryStandard,
                                                                    secondaryStandardList,
                                                                    fetchedItem
                                                                            .getVersion() + 1,
                                                                    fetchedItem
                                                                            .getItemGuid(),
                                                                    0);

                                                    fetchedItem
                                                            .setIsOldVersion(1);
                                                    contentMoveServices
                                                            .updateItem(fetchedItem);
                                                }
                                                for (ItemattribType attrib : item
                                                        .getAttriblist()
                                                        .getAttrib()) {
                                                    if (StringUtils
                                                            .equalsIgnoreCase(
                                                                    "itm_item_subject",
                                                                    attrib.getAttid())) {
                                                        // CONTENT AREA
                                                        contentMoveServices
                                                                .manageItemCharacterization(
                                                                        1,
                                                                        attrib.getVal(),
                                                                        insertedItem
                                                                                .getId());

                                                    }
                                                }

                                                // GRADE/LEVEL
                                                contentMoveServices
                                                        .manageItemCharacterization(
                                                                2,
                                                                grade,
                                                                insertedItem
                                                                        .getId());
                                                // POINTS
                                                contentMoveServices
                                                        .manageItemCharacterization(
                                                                3,
                                                                points,
                                                                insertedItem
                                                                        .getId());
                                                // GRADE SPAN START
                                                contentMoveServices
                                                        .manageItemCharacterization(
                                                                4,
                                                                grdSpanStart,
                                                                insertedItem
                                                                        .getId());
                                                // GRADE SPAN END
                                                contentMoveServices
                                                        .manageItemCharacterization(
                                                                5,
                                                                grdSpanEnd,
                                                                insertedItem
                                                                        .getId());
                                                // DOK
                                                contentMoveServices
                                                        .manageItemCharacterization(
                                                                6,
                                                                depthOfKnowledge,
                                                                insertedItem
                                                                        .getId());

                                                contentMoveServices
                                                        .insertExternalContentMetadata(
                                                                itemContent,
                                                                contentType,
                                                                insertedItem,
                                                                null, null);

                                                // Insert into Content External
                                                // Attribute

                                                contentMoveServices
                                                        .insertContentExternalAttribute(
                                                                itemXMLId,
                                                                itemFormat,
                                                                insertedItem,
                                                                null);

                                                // Update the content attachment

                                                Iterator it = attachmentMap
                                                        .entrySet().iterator();
                                                while (it.hasNext()) {
                                                    Map.Entry pairs = (Map.Entry) it
                                                            .next();
                                                    if (("attachment")
                                                            .equalsIgnoreCase(pairs
                                                                    .getKey()
                                                                    .toString()
                                                                    .split("#")[1])) {
                                                    	String resourcePath = SAAIFItemReader
                                                                .saveItemAttachment(
                                                                		pairs.getValue()
                                                                        .toString(),
                                                                        pairs.getKey()
                                                                        .toString().split("#")[0],
                                                                        itemBankId,
                                                                        insertedItem.getExternalId());
                                                        contentMoveServices
                                                                .contentAttachment(
                                                                        pairs.getKey()
                                                                                .toString()
                                                                                .split("#")[0],
                                                                                resourcePath,
                                                                        pairs.getKey()
                                                                                .toString()
                                                                                .split("#")[1],
                                                                        insertedItem,
                                                                        null,
                                                                        null);
                                                    }
                                                    it.remove(); // avoids a
                                                                 // ConcurrentModificationException
                                                }

                                                // Insert the content assets

                                                Iterator it2 = assetsMap
                                                        .entrySet().iterator();
                                                while (it2.hasNext()) {
                                                    Map.Entry pairs = (Map.Entry) it2
                                                            .next();
                                                    String resourcePath = SAAIFItemReader
                                                            .saveItemAsset(
                                                            		pairs.getValue()
                                                                    .toString(),
                                                                    pairs.getKey()
                                                                    .toString(),
                                                                    itemBankId,
                                                                    insertedItem.getExternalId());
                                                    contentMoveServices
                                                            .insertItemAssetAttribute(
                                                                    "" /* Classification */,
                                                                    pairs.getKey()
                                                                            .toString(),
                                                                    insertedItem,
                                                                    "" /* mediaDescription */,
                                                                    resourcePath,
                                                                    itemMoveMonitor
                                                                            .getUser());
                                                    it2.remove(); // avoids a
                                                                  // ConcurrentModificationException
                                                }

                                                /*
                                                 * For Wordlist and Tutorial and
                                                 * their Metadata
                                                 */
                                                /*
                                                 * Insert data into External
                                                 * Content Metadata, and Content
                                                 * External Attribute
                                                 */
                                                Iterator it3 = itemMap
                                                        .entrySet().iterator();
                                                Map<String, ContentResources> crMap = new HashMap<String, ContentResources>();
                                                while (it3.hasNext()) {
                                                    Map.Entry pairs = (Map.Entry) it3
                                                            .next();
                                                    Map<String, String> tempList = (Map<String, String>) pairs
                                                            .getValue();

                                                    ContentResources cr = null;
                                                    if (tempList
                                                            .get("sourceType")
                                                            .equalsIgnoreCase(
                                                                    SAAIFPackageConstants.WORDLIST_FORMAT)
                                                            || tempList
                                                                    .get("sourceType")
                                                                    .equalsIgnoreCase(
                                                                            SAAIFPackageConstants.TUTORIAL_FORMAT)) {
                                                        cr = contentMoveServices
                                                                .insertContentResources(
                                                                        externalId,
                                                                        tempList.get("source"),
                                                                        tempList.get("sourceType"));
                                                        crMap.put(
                                                                tempList.get("sourceType")
                                                                        + "Metadata",
                                                                cr);
                                                    }

                                                    for (Map.Entry<String, String> attachPairs : attachmentMap
                                                            .entrySet()) {
                                                        if (!("attachment")
                                                                .equalsIgnoreCase(pairs
                                                                        .getKey()
                                                                        .toString()
                                                                        .split("#")[1])) {
                                                            contentMoveServices
                                                                    .contentAttachment(
                                                                            pairs.getKey()
                                                                                    .toString()
                                                                                    .split("#")[0],
                                                                            pairs.getValue()
                                                                                    .toString(),
                                                                            pairs.getKey()
                                                                                    .toString()
                                                                                    .split("#")[1],
                                                                            null,
                                                                            null,
                                                                            crMap.get(pairs
                                                                                    .getKey()
                                                                                    .toString()
                                                                                    .split("#")[1]
                                                                                    + "Metadata"));
                                                        }
                                                    }

                                                    if (!("itemMetadata")
                                                            .equalsIgnoreCase(tempList
                                                                    .get("sourceType"))
                                                            && !("wordlistMetadata")
                                                                    .equalsIgnoreCase(tempList
                                                                            .get("sourceType"))
                                                            && !("tutMetadata")
                                                                    .equalsIgnoreCase(tempList
                                                                            .get("sourceType"))) {
                                                        contentMoveServices
                                                                .insertExternalContentMetadata(
                                                                        tempList.get("content") /* itemContent */,
                                                                        tempList.get("type") /* contentType */,
                                                                        insertedItem,
                                                                        null,
                                                                        cr);
                                                    } else if (("wordlistMetadata")
                                                            .equalsIgnoreCase(tempList
                                                                    .get("sourceType"))
                                                            || ("tutMetadata")
                                                                    .equalsIgnoreCase(tempList
                                                                            .get("sourceType"))) {
                                                        contentMoveServices
                                                                .insertExternalContentMetadata(
                                                                        tempList.get("content") /* itemContent */,
                                                                        tempList.get("type") /* contentType */,
                                                                        insertedItem,
                                                                        null,
                                                                        crMap.get(tempList
                                                                                .get("sourceType")));
                                                    } else {
                                                        contentMoveServices
                                                                .insertExternalContentMetadata(
                                                                        tempList.get("content") /* itemContent */,
                                                                        tempList.get("type") /* contentType */,
                                                                        insertedItem,
                                                                        null,
                                                                        null);

                                                    }

                                                    it3.remove(); // avoids a
                                                                  // ConcurrentModificationException
                                                }

                                                // ################# END
                                                // ################
                                                // ######################################

                                                // ########### CREATE PASSAGE
                                                // DATABASE RECORD #############
                                                // ########################################################

                                                com.pacificmetrics.orca.entities.Passage passage = null;
                                                Iterator it4 = passageMap
                                                        .entrySet().iterator();
                                                while (it4.hasNext()) {
                                                    Map.Entry pairs = (Map.Entry) it4
                                                            .next();
                                                    Map<String, String> tempList = (Map<String, String>) pairs
                                                            .getValue();

                                                    Map<String, String> metadataList = passageMetadataMap
                                                            .get(pairs.getKey());

                                                    passage = contentMoveServices
                                                            .checkPassageByIdentifier(
                                                                    itemMoveMonitor
                                                                            .getItemBank(),
                                                                    tempList.get("passageId"));
                                                    if (passage == null) {
                                                        passage = contentMoveServices
                                                                .checkPassageByDescription(
                                                                        itemMoveMonitor
                                                                                .getItemBank(),
                                                                        tempList.get("description"));
                                                        if (passage == null) {
                                                        	List<ItemDetailStatus> passageDetailStatusList = new ArrayList<ItemDetailStatus>();
                                                        	try {                                                        		
	                                                            passage = contentMoveServices
	                                                                    .insertPassage(
	                                                                            itemBankId,
	                                                                            tempList.get("description") /* Description */,
	                                                                            tempList.get("source") /* url */,
	                                                                            metadataList
	                                                                                    .get("genre"),
	                                                                            metadataList
	                                                                                    .get("publicationStatus"));
	                                                            
	                                                            String htmlContent = "";
	                                                            String htmlFileName = PropertyUtil
                                                                        .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX) + passage.getId() + ".htm";
                                                                String htmlFilePath = SAAIFPassageReader
                                                                        .savePassageHtml(
                                                                                htmlFileName,
                                                                                htmlContent,
                                                                                itemBankId);
                                                                Map<String, Object> values = new HashMap<String, Object>();
                                                                values.put("source", htmlFilePath);
                                                                
                                                                contentMoveServices.updatePassage(passage, values);
                                                                
	                                                            ItemDetailStatus passageDetailStatus = new ItemDetailStatus();
	                                                            DetailStatusType detailStatusType = contentMoveServices
	                                                                    .findDetailStatusTypeId(1);
	                                                            passageDetailStatus
	                                                                    .setStatusDetail("Passage has been imported successfully.");
	                                                            passageDetailStatus
	                                                                    .setDetailStatusType(detailStatusType);
	                                                            passageDetailStatusList
	                                                                    .add(passageDetailStatus);
                                                        	} catch (Exception e) {
                                                        		
                                                                ItemDetailStatus passageDetailStatus = new ItemDetailStatus();
                                                                DetailStatusType detailStatusType = contentMoveServices
                                                                        .findDetailStatusTypeId(1);
                                                                passageDetailStatus
                                                                        .setStatusDetail(e.getMessage());
                                                                passageDetailStatus
                                                                        .setDetailStatusType(detailStatusType);
                                                                passageDetailStatusList
                                                                        .add(passageDetailStatus);
                                                        	}

//                                                            List<ItemDetailStatus> passageDetailStatusList = new ArrayList<ItemDetailStatus>();
                                                            
                                                            contentMoveServices
                                                                    .insertPassageMoveDetails(
                                                                            tempList.get("passageId"),
                                                                            itemMoveMonitor,
                                                                            passage,
                                                                            passageDetailStatusList,
                                                                            externalId);
                                                        }
                                                    }

                                                    if (passage != null) {
	                                                    /*
	                                                     * Insert 'Item - Passage'
	                                                     * relationship
	                                                     */
	                                                    contentMoveServices
	                                                            .manageItemCharacterization(
	                                                                    7,
	                                                                    String.valueOf(passage
	                                                                            .getId()),
	                                                                    insertedItem
	                                                                            .getId());
	
	                                                    contentMoveServices
	                                                            .insertExternalContentMetadata(
	                                                                    tempList.get("content") /* itemContent */,
	                                                                    tempList.get("type") /* contentType */,
	                                                                    null,
	                                                                    passage,
	                                                                    null);
	                                                    if (tempList.size() > 2) {
	                                                        contentMoveServices
	                                                                .insertContentExternalAttribute(
	                                                                        tempList.get("passageId") /* itemXMLId */,
	                                                                        interactionType /* itemFormat */,
	                                                                        null,
	                                                                        passage);
	                                                    }
	
	                                                    // Passage success message
	
	                                                    // CONTENT AREA
	                                                    contentMoveServices
	                                                            .managePassageCharacterization(
	                                                                    1,
	                                                                    tempList.get("subject"),
	                                                                    passage.getId());
	
	                                                    contentMoveServices
	                                                            .insertExternalContentMetadata(
	                                                                    metadataList
	                                                                            .get("content") /* itemContent */,
	                                                                    metadataList
	                                                                            .get("type") /* contentType */,
	                                                                    null,
	                                                                    passage,
	                                                                    null);
	
	                                                    // GRADE LEVEL
	                                                    contentMoveServices
	                                                            .managePassageCharacterization(
	                                                                    2,
	                                                                    metadataList
	                                                                            .get("grade"),
	                                                                    passage.getId());
	
	                                                    // GRADE SPAN START
	                                                    contentMoveServices
	                                                            .managePassageCharacterization(
	                                                                    3,
	                                                                    metadataList
	                                                                            .get("gradeSpanStart"),
	                                                                    passage.getId());
	
	                                                    // GRADE SPAN END
	                                                    contentMoveServices
	                                                            .managePassageCharacterization(
	                                                                    4,
	                                                                    metadataList
	                                                                            .get("gradeSpanEnd"),
	                                                                    passage.getId());
	
	                                                    // Update the content
	                                                    // attachment
	                                                    Iterator it5 = passageattachmentMap
	                                                            .entrySet()
	                                                            .iterator();
	                                                    while (it5.hasNext()) {
	                                                        Map.Entry pairsAttach = (Map.Entry) it5
	                                                                .next();
	                                                        
	                                                        String resourcePath = SAAIFItemReader
                                                                    .saveItemAttachment(
                                                                    		String.valueOf(pairsAttach.getValue()),
                                                                    		String.valueOf(pairsAttach
                                                                            .getKey()),
                                                                            itemBankId,
                                                                            PropertyUtil
                                                                            .getProperty(PropertyUtil.RESOURCE_PASSAGE_PREFIX) + passage.getId());
	                                                        
	                                                        
	                                                        contentMoveServices
	                                                                .contentAttachment(
	                                                                        pairsAttach
	                                                                                .getKey()
	                                                                                .toString(),
	                                                                                resourcePath,
	                                                                        "attachment",
	                                                                        null,
	                                                                        passage,
	                                                                        null);
	                                                        it5.remove(); // avoids
	                                                                      // a
	                                                                      // ConcurrentModificationException
	                                                    }
	
	                                                    SimpleDateFormat format = new SimpleDateFormat(
	                                                            "yyyyMMdd_HHmmss");
	                                                    String currDateTime = format
	                                                            .format(new Date());
	
	                                                    // Insert the content assets
	                                                    Iterator it6 = passageassetMap
	                                                            .entrySet()
	                                                            .iterator();
	                                                    while (it6.hasNext()) {
	                                                        Map.Entry pairsAsset = (Map.Entry) it6
	                                                                .next();
	                                                        String mediaName = pairsAsset
	                                                                .getKey()
	                                                                .toString()
	                                                                .substring(
	                                                                        0,
	                                                                        pairsAsset
	                                                                                .getKey()
	                                                                                .toString()
	                                                                                .lastIndexOf(
	                                                                                        "."));
	                                                        String mediaExtn = pairsAsset
	                                                                .getKey()
	                                                                .toString()
	                                                                .substring(
	                                                                        pairsAsset
	                                                                                .getKey()
	                                                                                .toString()
	                                                                                .lastIndexOf(
	                                                                                        "."));
	                                                        String srvrFilename = mediaName
	                                                                + "_"
	                                                                + currDateTime
	                                                                + mediaExtn;
	                                                        	                                                        
	                                                        String ext = FilenameUtils
                                                                    .getExtension(srvrFilename);
                                                            if (extnMedia
                                                                    .contains(ext)) {
                                                            	String resourcePath = IMSItemUtil.savePassageMedia(String.valueOf(pairsAsset.getValue()), srvrFilename, passage.getItemBankId(), passage.getId());
                                                                
                                                            } else if (extnGraphic
                                                                    .contains(ext)) {
                                                            	String resourcePath = IMSItemUtil.savePassageImage(String.valueOf(pairsAsset.getValue()), srvrFilename, passage.getItemBankId(), passage.getId());
                                                            }
	                                                        
	                                                        contentMoveServices
	                                                                .insertPassageMedia(
	                                                                        pairsAsset
	                                                                                .getKey()
	                                                                                .toString() /* clntFilename */,
	                                                                        "" /* description */,
	                                                                        passage,
	                                                                        srvrFilename /* srvrFilename */,
	                                                                        itemMoveMonitor
	                                                                                .getUser());
	                                                        it6.remove(); // avoids
	                                                                      // a
	                                                                      // ConcurrentModificationException
	                                                    }
                                                    }

                                                    it4.remove(); // avoids a
                                                                  // ConcurrentModificationException
                                                }

                                                attachmentMap = new HashMap<String, String>();
                                                assetsMap = new HashMap<String, String>();
                                                itemMap = new HashMap<String, Map<String, String>>();
                                                passageMap = new HashMap<String, Map<String, String>>();
                                                passageMetadataMap = new HashMap<String, Map<String, String>>();
                                                passageattachmentMap = new HashMap<String, String>();
                                                passageassetMap = new HashMap<String, String>();
                                            } else {
                                                externalId = imdExternalId;
                                            }
                                        } else {
                                            ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                            DetailStatusType detailStatusType = contentMoveServices
                                                    .findDetailStatusTypeId(5); /*
                                                                                 * 
                                                                                 * Item
                                                                                 * Check
                                                                                 * ERROR
                                                                                 * for
                                                                                 * the
                                                                                 * Program
                                                                                 */
                                            itemDetailStatus
                                                    .setStatusDetail(detailStatusType
                                                            .getValue()
                                                            + itemMoveMonitor
                                                                    .getItemBank()
                                                                    .getExternalId());
                                            itemDetailStatus
                                                    .setDetailStatusType(detailStatusType);

                                            itemDetailStatuslist
                                                    .add(itemDetailStatus);

                                            for (String value : errorPassageList) {
                                                ItemDetailStatus itemDetailStatus2 = new ItemDetailStatus();
                                                DetailStatusType detailStatusType2 = contentMoveServices
                                                        .findDetailStatusTypeId(6); /*
                                                                                     * 6
                                                                                     * =
                                                                                     * Passage
                                                                                     * Check
                                                                                     * ERROR
                                                                                     * for
                                                                                     * the
                                                                                     * Program
                                                                                     */
                                                itemDetailStatus2
                                                        .setStatusDetail(value);
                                                itemDetailStatus2
                                                        .setDetailStatusType(detailStatusType2);

                                                itemDetailStatuslist
                                                        .add(itemDetailStatus2);
                                            }

                                            externalId = imdExternalId;
                                        }

                                        Map<String, String> subErrorList = errorMap
                                                .get(imdExternalId);
                                        errorMap.remove(imdExternalId);

                                        if (subErrorList != null) {
                                            for (String value : subErrorList
                                                    .keySet()) {
                                                ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                                String errorId = value
                                                        .split("#")[1];
                                                DetailStatusType detailStatusType = contentMoveServices
                                                        .findDetailStatusTypeId(Integer
                                                                .valueOf(errorId));
                                                itemDetailStatus
                                                        .setStatusDetail(subErrorList
                                                                .get(value));
                                                itemDetailStatus
                                                        .setDetailStatusType(detailStatusType);

                                                itemDetailStatuslist
                                                        .add(itemDetailStatus);
                                            }
                                        }

                                        if (!errorMap
                                                .containsKey(imdExternalId)
                                                && itemDetailStatuslist
                                                        .isEmpty()) {

                                            ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                            DetailStatusType detailStatusType = contentMoveServices
                                                    .findDetailStatusTypeId(1);
                                            itemDetailStatus
                                                    .setStatusDetail("Item has been imported successfully.");
                                            itemDetailStatus
                                                    .setDetailStatusType(detailStatusType);
                                            itemDetailStatuslist
                                                    .add(itemDetailStatus);

                                        }

                                        contentMoveServices
                                                .insertItemMoveDetails(
                                                        externalId,
                                                        itemMoveMonitor,
                                                        insertedItem,
                                                        itemDetailStatuslist,
                                                        imdExternalId);

                                    } else {

                                        imdExternalId = SAAIFItemUtil
                                                .getItemExternalId(sourceFilePath);
                                        imdExternalId = (imdExternalId != null
                                                && !("").equals(imdExternalId) ? imdExternalId
                                                : itemDirName);
                                        String externalId = imdExternalId;

                                        Map<String, String> subErrorList = errorMap
                                                .get(imdExternalId);
                                        errorMap.remove(imdExternalId);

                                        if (subErrorList != null) {
                                            for (String value : subErrorList
                                                    .keySet()) {
                                                ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                                String errorId = value
                                                        .split("#")[1];
                                                DetailStatusType detailStatusType = contentMoveServices
                                                        .findDetailStatusTypeId(Integer
                                                                .valueOf(errorId));
                                                itemDetailStatus
                                                        .setStatusDetail(subErrorList
                                                                .get(value));
                                                itemDetailStatus
                                                        .setDetailStatusType(detailStatusType);

                                                itemDetailStatuslist
                                                        .add(itemDetailStatus);
                                            }
                                        }

                                        // Insert into Item Move Details
                                        contentMoveServices
                                                .insertItemMoveDetails(
                                                        externalId,
                                                        itemMoveMonitor, null,
                                                        itemDetailStatuslist,
                                                        imdExternalId);

                                    }
                                }
                            } else {
                                if (!dependancyList.contains(fileName)) {

                                    String imdExternalId = "";
                                    imdExternalId = (imdExternalId != null
                                            && !("").equals(imdExternalId) ? imdExternalId
                                            : itemDirName);

                                    
                                    String itemIdentifier = imdExternalId.split("-")[imdExternalId.split("-").length - 1];
                                    if (errorMap.containsKey(imdExternalId) || errorMap.containsKey(itemIdentifier)) {
                                    	Map<String, String> subErrorList = errorMap
                                                .get(imdExternalId);
                                    	if (subErrorList == null || subErrorList.isEmpty()) {
                                    		subErrorList = errorMap.get(itemIdentifier);
                                    		errorMap.remove(itemIdentifier);
                                    	} else {
                                    		errorMap.remove(imdExternalId);
                                    	}

                                        if (subErrorList != null) {
                                            for (String value : subErrorList
                                                    .keySet()) {                                                
                                                String errorId = value
                                                        .split("#")[1];
                                                DetailStatusType detailStatusType = contentMoveServices
                                                        .findDetailStatusTypeId(Integer
                                                                .valueOf(errorId));
                                                ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                                itemDetailStatus
                                                        .setStatusDetail(subErrorList
                                                                .get(value));
                                                itemDetailStatus
                                                        .setDetailStatusType(detailStatusType);

                                                itemDetailStatuslist
                                                        .add(itemDetailStatus);
                                            }
                                        }
                                    }

                                    String externalId = imdExternalId;

                                    // Insert into Item Move Details
                                    contentMoveServices
                                            .insertItemMoveDetails(externalId,
                                                    itemMoveMonitor, null,
                                                    itemDetailStatuslist,
                                                    imdExternalId);

                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Error reading the Package ", e);
        }
    }

    public static List<String> validataXMLWithXSD(String sourceFilePath,
            int type) {

        boolean flag = false;
        List<String> statusList = new ArrayList<String>();
        // Parse xsd a provides a schema object
        try {

            URL dirURL = null;

            if (type == 1) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/SAAIF-IMS-Manifest.xsd");
            } else if (type == 2) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/assessmentitem_v1p0.xsd");
            } else if (type == 3) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/wordlist_v1p0.xsd");
            } else if (type == 4) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/SAAIF-Item-Metadata.xsd");
            } else if (type == 5) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/passageitem_v1p0.xsd");
            } else if (type == 6) {
                dirURL = SAAIFPackageReader.class.getClassLoader().getResource(
                        "/xsd/saaif/tutorial_v1p0.xsd");
            }

            SchemaFactory schemaFactory = SchemaFactory
                    .newInstance(XMLConstants.W3C_XML_SCHEMA_NS_URI);

            Schema schema = schemaFactory.newSchema(new File(dirURL.toURI()));

            // Processor to check XML is valid against schema
            Validator validator = schema.newValidator();

            File xmlFile = new File(sourceFilePath);
            // Validates the specified input
            validator.validate(new StreamSource(xmlFile));

            flag = true;
            statusList.add("true");
            statusList.add("");

        } catch (SAXException e) {
            flag = false;
            statusList.add("false");
            statusList.add(e.getMessage());
            LOGGER.error("Validate SAAIF package: " + e.getMessage(), e);
        } catch (IOException e) {
            flag = false;
            statusList.add("false");
            statusList.add(e.getMessage());
            LOGGER.error("Validate SAAIF package: " + e.getMessage(), e);
        } catch (URISyntaxException e) {
            flag = false;
            statusList.add("false");
            statusList.add(e.getMessage());
            LOGGER.error("Validate SAAIF package: " + e.getMessage(), e);
        }

        return statusList;

    }

    public Map<String, Map<String, String>> validationPackageStructure(
            String outputZipFolder) {
        boolean existStatusflag = true;
        boolean validationStatusflag = true;
        List<String> statusList = new ArrayList<String>();
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
                statusList = validataXMLWithXSD(outputZipFolder + "/"
                        + SAAIFPackageConstants.MANIFST_FILE_NAME, xsdType);
                validationStatusflag = Boolean.parseBoolean(statusList.get(0));

                if (!validationStatusflag) {
                    subErrorMap
                            .put(SAAIFPackageConstants.MANIFST_FILE_NAME
                                    + "#"
                                    + errorFromDBMap
                                            .get(SAAIFPackageConstants.ERROR_VALIDATION),
                                    SAAIFPackageConstants.MANIFST_FILE_NAME
                                            + " -> "
                                            + SAAIFPackageConstants.ERROR_VALIDATION
                                            + " ( " + outputZipFolder + " ) [ "
                                            + statusList.get(1).toString()
                                            + " ]");
                    errorMap.put(SAAIFPackageConstants.MANIFST_FILE_NAME,
                            subErrorMap);//
                } else {
                    LOGGER.info(SAAIFPackageConstants.MANIFST_FILE_NAME
                            + " has been validated. (Succesful)");
                    InputStream manifestStream = new FileInputStream(
                            manifestFile);
                    Manifest manifest = SAAIFManifestReader
                            .readManifest(manifestStream);
                    resourceMap = SAAIFManifestReader.readResources(manifest);
                    if (manifest != null
                            && manifest.getResources() != null
                            && CollectionUtils.isNotEmpty(manifest
                                    .getResources().getResource())) {

                        List<String> dependancyList = new ArrayList<String>();

                        for (Resource resource : manifest.getResources()
                                .getResource()) {
                            if (CollectionUtils.isNotEmpty(resource
                                    .getDependency())) {
                                for (Dependency itemDependency : resource
                                        .getDependency()) {
                                    Resource dependentResource = resourceMap
                                            .get(itemDependency
                                                    .getIdentifierref());
                                    dependancyList.add(FilenameUtils.getName(dependentResource
                                            .getFile().getHref()));
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

                            if (SAAIFPackageConstants.ITEM_TYPE
                                    .equalsIgnoreCase(resource.getType())) {
                                if (resourcefile.exists()) {

                                    String formatOrType = SAAIFItemUtil
                                            .getFormatOrTypeOfItem(sourceFilePath);
                                    String itemId = SAAIFItemUtil
                                            .getItemExternalId(sourceFilePath);

                                    if (!dependancyList.contains(fileName)) {
                                        if (subErrorMap.isEmpty()) {
                                            subErrorMap = new HashMap<String, String>();
                                        } else {
                                            errorMap.put(imdExternalId,
                                                    subErrorMap);
                                            subErrorMap = new HashMap<String, String>();
                                        }

                                        imdExternalId = StringUtils
                                                .isNotEmpty(itemId) ? itemId
                                                : itemDirName;
                                    }

                                    if (SAAIFPackageConstants.WORDLIST_FORMAT
                                            .equalsIgnoreCase(formatOrType)) {
                                        xsdType = 3;
                                    } else if (SAAIFPackageConstants.TUTORIAL_FORMAT
                                            .equalsIgnoreCase(formatOrType)) {
                                        xsdType = 6;
                                    } else {
                                        xsdType = 2;
                                    }

                                    statusList = validataXMLWithXSD(
                                            sourceFilePath, xsdType);
                                    validationStatusflag = Boolean
                                            .parseBoolean(statusList.get(0));
                                    if (validationStatusflag) {
                                        LOGGER.info(fileName
                                                + " is validated. (Succesful)");
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
                                                                + " ) [ "
                                                                + statusList
                                                                        .get(1)
                                                                        .toString()
                                                                + " ]");
                                    }
                                } else {
                                    if (!dependancyList.contains(fileName)) {
                                        imdExternalId = String
                                                .valueOf(itemDirName);
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
                                    .equalsIgnoreCase(resource.getType())) {
                                if (resourcefile.exists()) {
                                    xsdType = 5;
                                    statusList = validataXMLWithXSD(
                                            sourceFilePath, xsdType);
                                    validationStatusflag = Boolean
                                            .parseBoolean(statusList.get(0));
                                    if (validationStatusflag) {
                                        LOGGER.info(fileName
                                                + " is validated. (Succesful)");
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
                                                                + " ) [ "
                                                                + statusList
                                                                        .get(1)
                                                                        .toString()
                                                                + " ]");
                                    }
                                } else {
                                    existStatusflag = false;
                                    subErrorMap
                                            .put(fileName
                                                    + "#"
                                                    + errorFromDBMap
                                                            .get(SAAIFPackageConstants.ERROR_MISSING),
                                                    fileName
                                                            + " -> not found into ( "
                                                            + sourceFilePath
                                                                    .replace(
                                                                            outputZipFolder,
                                                                            "")
                                                            + " ) ");
                                }
                            } else if (SAAIFPackageConstants.METADATA_TYPE
                                    .equalsIgnoreCase(resource.getType())) {
                                if (resourcefile.exists()) {
                                    xsdType = 4;
                                    if ("stim".equalsIgnoreCase(fileName
                                            .substring(0, 4))) {
                                        validateMetadata(outputZipFolder,
                                                resource, errorFromDBMap,
                                                subErrorMap, imdExternalId, 2);
                                    } else {
                                        validateMetadata(outputZipFolder,
                                                resource, errorFromDBMap,
                                                subErrorMap, imdExternalId, 1);
                                    }
                                } else {
                                    existStatusflag = false;
                                    subErrorMap
                                            .put(fileName
                                                    + "#"
                                                    + errorFromDBMap
                                                            .get(SAAIFPackageConstants.ERROR_MISSING),
                                                    fileName
                                                            + " -> not found into ( "
                                                            + sourceFilePath
                                                                    .replace(
                                                                            outputZipFolder,
                                                                            "")
                                                            + " ) ");
                                }
                            } else if (SAAIFPackageConstants.CONTENT_TYPE
                                    .equalsIgnoreCase(resource.getType())) {
                                if (resourcefile.exists()) {
                                    LOGGER.info(fileName
                                            + " found.--(Successful)");
                                } else {
                                    existStatusflag = false;
                                    subErrorMap
                                            .put(fileName
                                                    + "#"
                                                    + errorFromDBMap
                                                            .get(SAAIFPackageConstants.ERROR_MISSING),
                                                    fileName
                                                            + " -> not found into ( "
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
            LOGGER.error("Validation failed." + e.getMessage(), e);
        }

        return errorMap;
    }

    private void validateMetadata(String outputZipFolder, Resource resource,
            Map<String, String> detailStatusTypeMap,
            Map<String, String> subErrorMap, String imdExternalId, int type) {
        try {
            List<String> missingRequiredFields = new ArrayList<String>();
            String filePath = outputZipFolder + File.separator
                    + resource.getFile().getHref();
            File metadataFile = new File(filePath);
            if (metadataFile.exists()) {
                String xmlContent = FileUtil
                        .readXMLFileWithoutDeclaration(metadataFile);
                Metadata metadata = SAAIFMetadataParser
                        .parseMetdata(xmlContent);
                if (metadata != null
                        && metadata.getSmarterAppMetadata() != null
                        && !(type == 1 ? isMetadataFieldPresent(
                                metadata.getSmarterAppMetadata(),
                                missingRequiredFields)
                                : isPassageMetadataFieldPresent(
                                        metadata.getSmarterAppMetadata(),
                                        missingRequiredFields))) {
                    subErrorMap
                            .put(metadataFile.getName()
                                    + "#"
                                    + detailStatusTypeMap
                                            .get(IMSPackageConstants.ERROR_INVALID_METADATA),
                                    metadataFile.getName()
                                            + " missing metadata element(s) "
                                            + (CollectionUtils
                                                    .isNotEmpty(missingRequiredFields) ? missingRequiredFields
                                                    : ""));
                } else if (metadata == null
                        || metadata.getSmarterAppMetadata() == null) {
                    subErrorMap
                            .put(metadataFile.getName()
                                    + "#"
                                    + detailStatusTypeMap
                                            .get(IMSPackageConstants.ERROR_INVALID_XML),
                                    metadataFile.getName()
                                            + " validation failed.");
                } else {
                    LOGGER.info(metadataFile.getName()
                            + " is validated.--(Successful)");
                }

            }
        } catch (Exception e) {
            LOGGER.error("Error validating metadata " + e.getMessage(), e);
        }
    }

    private boolean isMetadataFieldPresent(
            SmarterAppMetadata smarterAppMetadata,
            List<String> missingRequiredFields) {
        boolean validated = true;
        if (StringUtils.isNotBlank(smarterAppMetadata.getInteractionType())
                && (StringUtils.equalsIgnoreCase("WIT",
                        smarterAppMetadata.getInteractionType()) || StringUtils
                        .equalsIgnoreCase("TUT",
                                smarterAppMetadata.getInteractionType()))) {
            return validated;
        }
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
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getMinimumGrade()))) {
            missingRequiredFields.add(MetadataFieldConstants.MINIMUMGRADE);
            validated = false;
        }
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getMaximumGrade()))) {
            missingRequiredFields.add(MetadataFieldConstants.MAXIMUMGRADE);
            validated = false;
        }
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getIntendedGrade()))) {
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

    private boolean isPassageMetadataFieldPresent(
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
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getMinimumGrade()))) {
            missingRequiredFields.add(MetadataFieldConstants.MINIMUMGRADE);
            validated = false;
        }
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getMaximumGrade()))) {
            missingRequiredFields.add(MetadataFieldConstants.MAXIMUMGRADE);
            validated = false;
        }
        if (StringUtils.isBlank(Integer.toString(smarterAppMetadata
                .getIntendedGrade()))) {
            missingRequiredFields.add(MetadataFieldConstants.INTENDEDGRADE);
            validated = false;
        }
        if (smarterAppMetadata.getMaximumNumberOfPoints() < 0) {
            missingRequiredFields.add(MetadataFieldConstants.MAXNOOFPOINTS);
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

        return validated;
    }

}
