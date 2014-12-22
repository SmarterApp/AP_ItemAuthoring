package com.pacificmetrics.orca.export.saaif;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.utils.FileUtil;

@Stateless
public class SAAIFItemExporter {

    @EJB
    private SAAIFItemWriter itemWriter;

    @EJB
    private ORCA2SAAIFItemWriter orcaItemWriter;

    @EJB
    private ContentMoveServices contentMoveService;

    private SAAIFManifestWriter manifestWriter;

    private static final Logger LOGGER = Logger
            .getLogger(SAAIFItemExporter.class.getName());

    public InputStream export(File baseDir, List<Item> items,
            String externalFileName, ItemMoveMonitor itemMoveMonitor)
            throws ItemExportException {
        try {

            LOGGER.info("Processing items for exporting in SAAIF format ... ");

            createBaseDir(baseDir);

            String itemBankId = "";
            manifestWriter = new SAAIFManifestWriter();
            for (Item item : items) {
                if (item == null) {
                    throw new ItemExportException(
                            "An item in the list was null. Exiting the export process.");
                } else if (item.getExternalId() == null) {
                    throw new ItemExportException("Item with id:"
                            + item.getId() + " had an unusable external id.");
                }

                LOGGER.info("Parsing item id:" + item.getId());
                SAAIFItem saaifItem = null;
                Item itemByFormat = contentMoveService.findItemByFormat(
                        item.getId(),
                        new ArrayList<String>(Arrays.asList("Unsupported",
                                "Performance Task", "Activity Based")));
                if (itemByFormat != null) {
                    saaifItem = itemWriter.getItem(item);
                } else {
                    saaifItem = orcaItemWriter.getItem(item);
                }

                if (StringUtils.isNotEmpty(itemBankId)) {
                    itemBankId = saaifItem.getBankKey();
                }

                LOGGER.info("Writing XML to distribution directory.");
                File itemXMLDir = new File(baseDir, "build/Items/"
                        + saaifItem.getHrefBase());
                FileUtil.createDir(itemXMLDir);
                LOGGER.info("Created item xml directory "
                        + itemXMLDir.getAbsolutePath());

                File itemXml = new File(itemXMLDir, saaifItem.getHref());
                FileUtils.write(itemXml, saaifItem.getXmlContent(), "UTF-8");
                LOGGER.info("Created item xml file "
                        + itemXml.getAbsolutePath());

                LOGGER.info("Writing Metadata XML to distribution directory.");

                File metadataXml = new File(itemXMLDir,
                        saaifItem.getMetadataHref());
                FileUtils.write(metadataXml, saaifItem.getMetadataXmlContent());

                LOGGER.info("Created item xml metadata file "
                        + metadataXml.getAbsolutePath());

                LOGGER.info("Writing attachments to distribution directory.");
                Map<String, String> attachmentMap = saaifItem.getAttachments();

                if (attachmentMap != null
                        && CollectionUtils.isNotEmpty(attachmentMap.entrySet())) {
                    for (String fileName : attachmentMap.keySet()) {
                        File attachmentFile = new File(
                                attachmentMap.get(fileName));
                        FileUtils.copyFileToDirectory(attachmentFile,
                                itemXMLDir);
                        LOGGER.info("Created item attachment file "
                                + attachmentFile.getAbsolutePath());
                    }
                }

                LOGGER.info("Writing assets to distribution directory.");
                Map<String, String> assetMap = saaifItem.getAssets();

                if (assetMap != null
                        && CollectionUtils.isNotEmpty(assetMap.entrySet())) {
                    for (String fileName : assetMap.keySet()) {
                        File assetFile = new File(assetMap.get(fileName));
                        FileUtils.copyFileToDirectory(assetFile, itemXMLDir);
                        LOGGER.info("Created item assets file "
                                + assetFile.getAbsolutePath());
                    }
                }

                if (CollectionUtils.isNotEmpty(saaifItem.getWordlists())) {
                    for (SAAIFItem wordlist : saaifItem.getWordlists()) {

                        LOGGER.info("Writing wordlist to distribution directory.");
                        File wordlistXMLDir = new File(baseDir, "build/Items/"
                                + wordlist.getHrefBase());
                        FileUtil.createDir(wordlistXMLDir);
                        LOGGER.info("Created wordlist item directory "
                                + wordlistXMLDir.getAbsolutePath());

                        File wordlistXml = new File(wordlistXMLDir,
                                wordlist.getHref());
                        FileUtils.write(wordlistXml, wordlist.getXmlContent());
                        LOGGER.info("Created wordlist item file "
                                + wordlistXml.getAbsolutePath());

                        LOGGER.info("Writing wordlist Metadata XML to distribution directory.");

                        File wordlistMetadataXml = new File(wordlistXMLDir,
                                wordlist.getMetadataHref());
                        FileUtils.write(wordlistMetadataXml,
                                wordlist.getMetadataXmlContent());
                        LOGGER.info("Created wordlist item metadata file "
                                + wordlistMetadataXml.getAbsolutePath());
                    }
                }

                if (CollectionUtils.isNotEmpty(saaifItem.getTutorials())) {
                    for (SAAIFItem tutorial : saaifItem.getTutorials()) {

                        LOGGER.info("Writing tutorial to distribution directory.");
                        File tutorialXMLDir = new File(baseDir, "build/Items/"
                                + tutorial.getHrefBase());
                        FileUtil.createDir(tutorialXMLDir);
                        LOGGER.info("Created tutorial item directory "
                                + tutorialXMLDir.getAbsolutePath());

                        File tutorialXml = new File(tutorialXMLDir,
                                tutorial.getHref());
                        FileUtils.write(tutorialXml, tutorial.getXmlContent());
                        LOGGER.info("Created tutorial item file "
                                + tutorialXml.getAbsolutePath());

                        LOGGER.info("Writing tutorial Metadata XML to distribution directory.");

                        File tutorialMetadataXml = new File(tutorialXMLDir,
                                tutorial.getMetadataHref());
                        FileUtils.write(tutorialMetadataXml,
                                tutorial.getMetadataXmlContent());
                        LOGGER.info("Created tutorial item metadata file "
                                + tutorialMetadataXml.getAbsolutePath());

                        LOGGER.info("Writing attachments to distribution directory.");
                        Map<String, String> tutorialAttachmentMap = tutorial
                                .getAttachments();

                        if (tutorialAttachmentMap != null
                                && CollectionUtils
                                        .isNotEmpty(tutorialAttachmentMap
                                                .entrySet())) {
                            for (String fileName : tutorialAttachmentMap
                                    .keySet()) {
                                File tutorialAttachmentFile = new File(
                                        tutorialAttachmentMap.get(fileName));
                                FileUtils.copyFileToDirectory(
                                        tutorialAttachmentFile, tutorialXMLDir);
                                LOGGER.info("Created item attachment file "
                                        + tutorialAttachmentFile
                                                .getAbsolutePath());
                            }
                        }

                        LOGGER.info("Writing assets to distribution directory.");
                        Map<String, String> tutorialAssetMap = tutorial
                                .getAssets();

                        if (tutorialAssetMap != null
                                && CollectionUtils.isNotEmpty(tutorialAssetMap
                                        .entrySet())) {
                            for (String fileName : tutorialAssetMap.keySet()) {
                                File tutorialAssetFile = new File(
                                        tutorialAssetMap.get(fileName));
                                FileUtils.copyFileToDirectory(
                                        tutorialAssetFile, tutorialXMLDir);
                                LOGGER.info("Created item assets file "
                                        + tutorialAssetFile.getAbsolutePath());
                            }
                        }
                    }
                }

                if (CollectionUtils.isNotEmpty(saaifItem.getPassages())) {
                    for (SAAIFItem passage : saaifItem.getPassages()) {
                        LOGGER.info("Writing passage to distribution directory.");
                        File passageXMLDir = new File(baseDir, "build/Stimuli/"
                                + passage.getHrefBase());
                        FileUtil.createDir(passageXMLDir);
                        LOGGER.info("Created passage item directory "
                                + passageXMLDir.getAbsolutePath());

                        File passageXml = new File(passageXMLDir,
                                passage.getHref());
                        FileUtils.write(passageXml, passage.getXmlContent(),
                                "UTF-8");
                        LOGGER.info("Created passage item file "
                                + passageXml.getAbsolutePath());

                        LOGGER.info("Writing passage Metadata XML to distribution directory.");

                        File passageMetadataXml = new File(passageXMLDir,
                                passage.getMetadataHref());
                        FileUtils.write(passageMetadataXml,
                                passage.getMetadataXmlContent());
                        LOGGER.info("Created passage item metadata file "
                                + passageMetadataXml.getAbsolutePath());

                        LOGGER.info("Writing passage attachments to distribution directory.");
                        Map<String, String> passageAttachmentMap = passage
                                .getAttachments();

                        if (passageAttachmentMap != null
                                && CollectionUtils
                                        .isNotEmpty(passageAttachmentMap
                                                .entrySet())) {
                            for (String fileName : passageAttachmentMap
                                    .keySet()) {
                                File tutorialAttachmentFile = new File(
                                        passageAttachmentMap.get(fileName));
                                FileUtils.copyFileToDirectory(
                                        tutorialAttachmentFile, passageXMLDir);
                                LOGGER.info("Created passage attachment file "
                                        + tutorialAttachmentFile
                                                .getAbsolutePath());
                            }
                        }

                        LOGGER.info("Writing passage assets to distribution directory.");
                        Map<String, String> passageAssetMap = passage
                                .getAssets();

                        if (passageAssetMap != null
                                && CollectionUtils.isNotEmpty(passageAssetMap
                                        .entrySet())) {
                            for (String fileName : passageAssetMap.keySet()) {
                                File tutorialAssetFile = new File(
                                        passageAssetMap.get(fileName));
                                FileUtils.copyFileToDirectory(
                                        tutorialAssetFile, passageXMLDir);
                                LOGGER.info("Created passage assets file "
                                        + tutorialAssetFile.getAbsolutePath());
                            }
                        }
                    }
                }

                LOGGER.info("Adding item information to manifest.");
                this.manifestWriter.addItem(saaifItem);

            }

            LOGGER.info("Writing SBAC APIP compliant manifest.");
            File manifestXML = new File(baseDir, "build/imsmanifest.xml");
            LOGGER.info("Manifest file path:" + manifestXML.getAbsolutePath());
            this.manifestWriter.write(manifestXML);

            SAAIFItemValidator siv = new SAAIFItemValidator();
            siv.validataXMLWithXSD(manifestXML.getAbsolutePath(), 1);

            LOGGER.info("Creating final zip archive.");
            File zip = new File(baseDir, "dist/" + externalFileName);
            LOGGER.info("Zip file path:" + zip.getAbsolutePath());
            File buildDir = new File(baseDir, "build");
            LOGGER.info("Zip content directory:" + buildDir.getAbsolutePath());
            FileUtil.zip(buildDir, zip);

            return new FileInputStream(zip);
        } catch (Exception e) {
            LOGGER.info("Error- " + e.getMessage());
            throw new ItemExportException(e);
        }
    }

    public void createBaseDir(File baseDir) throws ItemExportException {
        LOGGER.info("Creating build directory structure ...");

        File items = new File(baseDir, "build/Items");
        items.mkdirs();
        LOGGER.info("Build items directory : " + items.getAbsolutePath());

        File dist = new File(baseDir, "dist");
        dist.mkdirs();
        LOGGER.info("Distribution directory : " + dist.getAbsolutePath());

        if (!items.exists() || !dist.exists()) {
            throw new ItemExportException(
                    "Unable to create items or distribution directory : "
                            + items.getAbsolutePath());
        }
    }

    public SAAIFManifestWriter getManifestWriter() {
        return manifestWriter;
    }

    public void setManifestWriter(SAAIFManifestWriter manifestWriter) {
        this.manifestWriter = manifestWriter;
    }

}
