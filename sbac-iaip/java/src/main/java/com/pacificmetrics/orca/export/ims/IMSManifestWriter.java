package com.pacificmetrics.orca.export.ims;

import java.io.IOException;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FileUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.ieee.ltsc.lom.manifest.Lom;

import com.pacificmetrics.ims.apip.cp.DependencyType;
import com.pacificmetrics.ims.apip.cp.FileType;
import com.pacificmetrics.ims.apip.cp.Manifest;
import com.pacificmetrics.ims.apip.cp.ManifestMetadataType;
import com.pacificmetrics.ims.apip.cp.ObjectFactory;
import com.pacificmetrics.ims.apip.cp.OrganizationsType;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.apip.cp.ResourcesType;
import com.pacificmetrics.orca.export.saaif.SAAIFManifestWriter;
import com.pacificmetrics.orca.loader.ims.IMSPackageConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.utils.JAXBUtil;

public class IMSManifestWriter {

    private static final Log LOGGER = LogFactory
            .getLog(SAAIFManifestWriter.class);

    private static final String ITEM_FILE_PREFIX = "item-";
    private static final String STIMULUS_FILE_PREFIX = "stim-";
    private static final String XML_FILE_EXT = ".xml";
    private static final String METADATA_FILE_EXT = "_metadata.xml";
    private static final String METADATA_POSTFIX = "_metadata";

    private final ObjectFactory of = new ObjectFactory();
    private final org.ieee.ltsc.lom.manifest.ObjectFactory lomOf = new org.ieee.ltsc.lom.manifest.ObjectFactory();
    private final Manifest m = this.of.createManifest();
    private final ResourcesType resources = of.createResourcesType();
    private final Set<String> uniqueIds = new HashSet<String>();
    private final Set<String> resourceIdentifiers = new HashSet<String>();

    public void addItem(IMSItem item) {
        String itemIdentifier = ITEM_FILE_PREFIX + item.getBankKey() + "-"
                + item.getIdentifier();

        item.setHref(getItemHref(
                item.getIdentifier(),
                ITEM_FILE_PREFIX + item.getBankKey() + "-"
                        + item.getIdentifier() + XML_FILE_EXT));
        item.setHrefBase(getItemHrefBase(item.getIdentifier()));
        item.setMetadataHref(getItemHref(item.getIdentifier(), ITEM_FILE_PREFIX
                + item.getBankKey() + "-" + item.getIdentifier()
                + METADATA_FILE_EXT));
        item.setMetadataHrefBase(getItemHrefBase(item.getIdentifier()));

        // Add Item resource
        ResourceType itemResource = of.createResourceType();

        // Add Item File
        FileType itemFile = of.createFileType();
        itemFile.setHref(item.getHref());

        itemResource.setIdentifier(itemIdentifier);
        itemResource.setType(IMSPackageConstants.IMS_APIP_QTI_ITEM_TYPE_V2);
        itemResource.setHref(item.getHref());
        itemResource.getFiles().add(itemFile);

        // Add Item metadata resource
        ResourceType metadataResource = of.createResourceType();
        FileType metadataFile = of.createFileType();

        metadataResource.setIdentifier(itemIdentifier + METADATA_POSTFIX);
        metadataResource.setType(IMSPackageConstants.IMS_METADATA_TYPE);
        metadataFile.setHref(item.getMetadataHref());
        metadataResource.getFiles().add(metadataFile);

        // Add Item metadata dependency
        DependencyType metadataDependency = of.createDependencyType();
        metadataDependency.setIdentifierref(metadataResource);
        itemResource.getDependencies().add(metadataDependency);

        resources.getResources().add(itemResource);
        resources.getResources().add(metadataResource);

        // Add attachment dependencies
        if (item.getAttachments() != null
                && CollectionUtils.isNotEmpty(item.getAttachments().entrySet())) {
            for (String fileName : item.getAttachments().keySet()) {
                String fileKey = fileName.replace(".", "_");
                String fileIdentifier = ITEM_FILE_PREFIX + item.getIdentifier()
                        + "_" + fileKey;

                // Add attachment resource
                ResourceType attachmentResource = of.createResourceType();

                // Add attachment file
                FileType attachmentFile = of.createFileType();
                attachmentFile.setHref(item.getHrefBase() + fileName);

                attachmentResource.setIdentifier(fileIdentifier);
                attachmentResource
                        .setType(IMSPackageConstants.IMS_CONTENT_TYPE);
                attachmentResource.getFiles().add(attachmentFile);

                // Add Attachment dependency
                DependencyType attachmentDependency = of.createDependencyType();
                attachmentDependency.setIdentifierref(attachmentResource);

                itemResource.getDependencies().add(attachmentDependency);

                resources.getResources().add(attachmentResource);
            }
        }

        // Add assets dependencies
        if (item.getAssets() != null
                && CollectionUtils.isNotEmpty(item.getAssets().entrySet())) {
            for (String fileName : item.getAssets().keySet()) {
                String fileKey = fileName.replace(".", "_");
                String fileIdentifier = fileKey;

                // Add Assets dependency
                ResourceType assetResource = of.createResourceType();

                // Add attachment file
                FileType attachmentFile = of.createFileType();
                attachmentFile.setHref(item.getHrefBase() + fileName);

                assetResource.setIdentifier(fileIdentifier);
                assetResource.setType(SAAIFPackageConstants.CONTENT_TYPE);
                assetResource.getFiles().add(attachmentFile);

                // Add Attachment dependency
                DependencyType assetDependency = of.createDependencyType();
                assetDependency.setIdentifierref(assetResource);

                itemResource.getDependencies().add(assetDependency);

                resources.getResources().add(assetResource);
            }
        }

        // TODO : Check for duplicate passage
        if (CollectionUtils.isNotEmpty(item.getPassages())) {
            for (IMSItem passage : item.getPassages()) {

                String dependencyIdentifier = STIMULUS_FILE_PREFIX
                        + item.getBankKey() + "-" + passage.getIdentifier();
                if (!resourceIdentifiers.contains(dependencyIdentifier)) {
                    resourceIdentifiers.add(dependencyIdentifier);

                    passage.setHref(getStimuliHref(passage.getIdentifier(),
                            STIMULUS_FILE_PREFIX + item.getBankKey() + "-"
                                    + passage.getIdentifier() + XML_FILE_EXT));
                    passage.setHrefBase(getStimuliHrefBase(passage
                            .getIdentifier()));
                    passage.setMetadataHref(getStimuliHref(
                            passage.getIdentifier(),
                            STIMULUS_FILE_PREFIX + item.getBankKey() + "-"
                                    + passage.getIdentifier()
                                    + METADATA_FILE_EXT));
                    passage.setMetadataHrefBase(getStimuliHrefBase(passage
                            .getIdentifier()));

                    // Add stimuli Resource
                    ResourceType passageResource = of.createResourceType();
                    FileType passageFile = of.createFileType();

                    passageFile.setHref(passage.getHref());
                    passageResource
                            .setType(SAAIFPackageConstants.STIMULUS_TYPE);
                    passageResource.setIdentifier(dependencyIdentifier);
                    passageResource.getFiles().add(passageFile);

                    // Add stimuli dependency
                    DependencyType passageDependency = of
                            .createDependencyType();
                    passageDependency.setIdentifierref(passageResource);
                    itemResource.getDependencies().add(passageDependency);

                    // Add stimuli Resource metadata
                    ResourceType passageMetadataResource = of
                            .createResourceType();
                    FileType passageMetadatatFile = of.createFileType();

                    passageMetadatatFile.setHref(passage.getMetadataHref());
                    passageMetadataResource
                            .setType(SAAIFPackageConstants.METADATA_TYPE);
                    passageMetadataResource.setIdentifier(dependencyIdentifier
                            + METADATA_POSTFIX);
                    passageMetadataResource.getFiles()
                            .add(passageMetadatatFile);

                    // Add stimuli metadata dependency
                    DependencyType passageddMetadataDependency = of
                            .createDependencyType();
                    passageddMetadataDependency
                            .setIdentifierref(passageMetadataResource);
                    passageResource.getDependencies().add(
                            passageddMetadataDependency);

                    resources.getResources().add(passageResource);
                    resources.getResources().add(passageMetadataResource);

                    // Add attachment dependencies
                    if (passage.getAttachments() != null
                            && CollectionUtils.isNotEmpty(passage
                                    .getAttachments().entrySet())) {
                        for (String fileName : passage.getAttachments()
                                .keySet()) {
                            String fileKey = fileName.replace(".", "_");
                            String fileIdentifier = "Passage-"
                                    + passage.getIdentifier() + "_" + fileKey;

                            // Add attachment resource
                            ResourceType attachmentResource = of
                                    .createResourceType();

                            // Add attachment file
                            FileType attachmentFile = of.createFileType();
                            attachmentFile.setHref(passage.getHrefBase()
                                    + fileName);

                            attachmentResource.setIdentifier(fileIdentifier);
                            attachmentResource
                                    .setType(SAAIFPackageConstants.CONTENT_TYPE);
                            attachmentResource.getFiles().add(attachmentFile);

                            // Add Attachment dependency
                            DependencyType attachmentDependency = of
                                    .createDependencyType();
                            attachmentDependency
                                    .setIdentifierref(attachmentResource);

                            passageResource.getDependencies().add(
                                    attachmentDependency);

                            resources.getResources().add(attachmentResource);
                        }
                    }

                    // Add assets dependencies
                    if (passage.getAssets() != null
                            && CollectionUtils.isNotEmpty(passage.getAssets()
                                    .entrySet())) {
                        for (String fileName : passage.getAssets().keySet()) {
                            String fileKey = fileName.replace(".", "_");
                            String fileIdentifier = fileKey;

                            // Add Assets dependency
                            ResourceType assetResource = of
                                    .createResourceType();

                            // Add attachment file
                            FileType attachmentFile = of.createFileType();
                            attachmentFile.setHref(passage.getHrefBase()
                                    + fileName);

                            assetResource.setIdentifier(fileIdentifier);
                            assetResource
                                    .setType(SAAIFPackageConstants.CONTENT_TYPE);
                            assetResource.getFiles().add(attachmentFile);

                            // Add Attachment dependency
                            DependencyType assetDependency = of
                                    .createDependencyType();
                            assetDependency.setIdentifierref(assetResource);

                            passageResource.getDependencies().add(
                                    assetDependency);

                            resources.getResources().add(assetResource);
                        }
                    }
                }
            }
        }

        m.setResources(resources);
        addDefaultManifestMetadata();
    }

    public void write(java.io.File file) {
        try {
            String manifestContent = JAXBUtil.mershall(m, Manifest.class);
            FileUtils.write(file, manifestContent);
        } catch (IOException e) {
            LOGGER.error("Unable to write SAABIF manifest to file ", e);
        }
    }

    public void addDefaultManifestMetadata() {
        this.m.setIdentifier("MANIFEST-QTI-" + getUniqueId());

        ManifestMetadataType metadata = of.createManifestMetadataType();
        Lom lom = lomOf.createLom();
        lom.setXmlns("http://ltsc.ieee.org/xsd/apipv1p0/LOM/manifest");

        OrganizationsType organization = of.createOrganizationsType();

        m.setOrganizations(organization);

        metadata.setSchema("APIP Package");
        metadata.setSchemaversion("1.0.0");
        metadata.setLom(lom);

        m.setMetadata(metadata);
    }

    private static String getItemHref(String base, String fileName) {
        return getItemHrefBase(base) + fileName;
    }

    private static String getStimuliHref(String base, String fileName) {
        return getStimuliHrefBase(base) + fileName;
    }

    private static String getItemHrefBase(String base) {
        return "Items/Item_" + base + '/';
    }

    private static String getStimuliHrefBase(String base) {
        return "Stimuli/Stim_" + base + '/';
    }

    private final String getUniqueId() {
        String key = 'A' + UUID.randomUUID().toString().substring(1)
                .toUpperCase();
        this.uniqueIds.add(key);
        return key;
    }
}
