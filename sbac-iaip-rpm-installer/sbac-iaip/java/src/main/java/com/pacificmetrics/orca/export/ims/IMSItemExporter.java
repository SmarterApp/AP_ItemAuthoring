package com.pacificmetrics.orca.export.ims;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;

import javax.ejb.EJB;
import javax.ejb.Stateless;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.utils.FileUtil;

@Stateless
public class IMSItemExporter {

    @EJB
    private IMSItemWriter itemWriter;

    @EJB
    private ORCA2IMSItemWriter orcaItemWriter;

    @EJB
    private ContentMoveServices contentMoveService;

    private IMSManifestWriter manifestWriter;

    private static final Log LOGGER = LogFactory.getLog(IMSItemExporter.class
            .getName());

    public InputStream export(File baseDir, List<Item> items,
            String externalFileName, ItemMoveMonitor itemMoveMonitor)
            throws ItemExportException {
        try {
            LOGGER.info("Processing items for exporting in IMS format ... ");

            createBaseDir(baseDir);

            manifestWriter = new IMSManifestWriter();
            for (Item item : items) {
                if (item == null) {
                    throw new ItemExportException(
                            "An item in the list was null. Exiting the export process.");
                } else if (item.getExternalId() == null) {
                    throw new ItemExportException("Item with id:"
                            + item.getId() + " had an unusable external id.");
                }

                LOGGER.info("Parsing item id:" + item.getId());
                IMSItem imsItem = null;
                Item itemByFormat = contentMoveService.findItemByFormat(
                        item.getId(),
                        new ArrayList<String>(Arrays.asList("Unsupported",
                                "Performance Task", "Activity Based")));
                if (itemByFormat == null) {
                    imsItem = orcaItemWriter.getItem(item);
                } else {
                    imsItem = itemWriter.getItem(item);
                }
                LOGGER.info("Writing XML to distribution directory.");
                File itemXMLDir = new File(baseDir, "build/Items/"
                        + imsItem.getHrefBase());
                FileUtil.createDir(itemXMLDir);
                LOGGER.info("Created item xml directory "
                        + itemXMLDir.getAbsolutePath());

                File itemXml = new File(itemXMLDir, imsItem.getHref());
                FileUtils.write(itemXml, imsItem.getXmlContent(), "UTF-8");
                LOGGER.info("Created item xml file "
                        + itemXml.getAbsolutePath());

                LOGGER.info("Writing Metadata XML to distribution directory.");

                File metadataXml = new File(itemXMLDir,
                        imsItem.getMetadataHref());
                FileUtils.write(metadataXml, imsItem.getMetadataXmlContent(),
                        "UTF-8");

                LOGGER.info("Created item xml metadata file "
                        + metadataXml.getAbsolutePath());

                LOGGER.info("Writing attachments to distribution directory.");
                Map<String, String> attachmentMap = imsItem.getAttachments();

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
                Map<String, String> assetMap = imsItem.getAssets();

                if (assetMap != null
                        && CollectionUtils.isNotEmpty(assetMap.entrySet())) {
                    for (String fileName : assetMap.keySet()) {
                        File assetFile = new File(assetMap.get(fileName));
                        FileUtils.copyFileToDirectory(assetFile, itemXMLDir);
                        LOGGER.info("Created item assets file "
                                + assetFile.getAbsolutePath());
                    }
                }

                if (CollectionUtils.isNotEmpty(imsItem.getPassages())) {
                    for (IMSItem passage : imsItem.getPassages()) {
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
                this.manifestWriter.addItem(imsItem);

            }

            LOGGER.info("Writing SBAC APIP compliant manifest.");
            File manifestXML = new File(baseDir, "build/imsmanifest.xml");
            LOGGER.info("Manifest file path:" + manifestXML.getAbsolutePath());
            this.manifestWriter.write(manifestXML);

            LOGGER.info("Creating final zip archive.");
            File zip = new File(baseDir, "dist/" + externalFileName);
            LOGGER.info("Zip file path:" + zip.getAbsolutePath());
            File buildDir = new File(baseDir, "build");
            LOGGER.info("Zip content directory:" + buildDir.getAbsolutePath());
            FileUtil.zip(buildDir, zip);

            return new FileInputStream(zip);
        } catch (Exception e) {
            LOGGER.error("Error exporting IMS package " + e.getMessage(), e);
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

    /**
     * @return the manifestWriter
     */
    public IMSManifestWriter getManifestWriter() {
        return manifestWriter;
    }

    /**
     * @param manifestWriter
     *            the manifestWriter to set
     */
    public void setManifestWriter(IMSManifestWriter manifestWriter) {
        this.manifestWriter = manifestWriter;
    }

}
