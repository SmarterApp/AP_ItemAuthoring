package com.pacificmetrics.orca.loader.ims;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.pacificmetrics.ims.apip.cp.DependencyType;
import com.pacificmetrics.ims.apip.cp.Manifest;
import com.pacificmetrics.ims.apip.cp.ResourceType;
import com.pacificmetrics.ims.apip.metadata.APIPMetadata;
import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.metadata.Metadata;
import com.pacificmetrics.saaif.metadata.SAAIFMetadataParser;

public class IMSManifestReader {

    private static final Log LOGGER = LogFactory
            .getLog(IMSManifestReader.class);

    private IMSManifestReader() {
    }

    public static Manifest readManifest(String filePath) {
        Manifest manifest = null;
        LOGGER.info("Parsing manifest file from path " + filePath);
        try {
            File file = new File(filePath);
            String manifestContent = FileUtil
                    .readXMLFileWithoutDeclaration(file);
            manifest = JAXBUtil.unmershall(manifestContent, Manifest.class);
            LOGGER.info("Complete parsing manifest file from path " + filePath);
        } catch (Exception e) {
            LOGGER.error("Unable to unmershall manifest file from path "
                    + filePath, e);
        }
        return manifest;
    }

    public static Map<String, ResourceType> readResources(Manifest manifest) {
        Map<String, ResourceType> resourceMap = new HashMap<String, ResourceType>();
        if (manifest != null
                && null != manifest.getResources()
                && CollectionUtils.isNotEmpty(manifest.getResources()
                        .getResources())) {
            for (ResourceType resource : manifest.getResources().getResources()) {
                resourceMap.put(resource.getIdentifier(), resource);
            }
        }
        return resourceMap;
    }

    public static String readMetadataContent(String outputZipFolder,
            ResourceType resource, Map<String, ResourceType> resourceMap) {
        String xmlContent = "";
        try {
            if (resource != null
                    && CollectionUtils.isNotEmpty(resource.getDependencies())) {
                for (DependencyType dependency : resource.getDependencies()) {
                    ResourceType dependencyResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (dependencyResource != null
                            && StringUtils.equals(dependencyResource.getType(),
                                    IMSPackageConstants.IMS_METADATA_TYPE)
                            && StringUtils.isNotBlank(IMSItemReader
                                    .getHref(dependencyResource))) {
                        File resourceFile = new File(outputZipFolder
                                + File.separator
                                + IMSItemReader.getHref(dependencyResource));
                        String fileContent = FileUtil
                                .readXMLFileWithoutDeclaration(resourceFile);
                        if (StringUtils.startsWith(fileContent, "<metadata>")) {
                            xmlContent = fileContent;
                        }
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Unable to read apip metadata " + e.getMessage(), e);
        }
        return xmlContent;
    }

    public static APIPMetadata readAPIPMetadata(String outputZipFolder,
            ResourceType resource, Map<String, ResourceType> resourceMap) {
        APIPMetadata apipMetadata = new APIPMetadata();
        try {
            if (resource != null
                    && CollectionUtils.isNotEmpty(resource.getDependencies())) {
                for (DependencyType dependency : resource.getDependencies()) {
                    ResourceType dependencyResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (dependencyResource != null
                            && StringUtils.equals(dependencyResource.getType(),
                                    IMSPackageConstants.IMS_METADATA_TYPE)
                            && StringUtils.isNotBlank(IMSItemReader
                                    .getHref(dependencyResource))) {
                        File resourceFile = new File(outputZipFolder
                                + File.separator
                                + IMSItemReader.getHref(dependencyResource));
                        String xmlContent = FileUtil
                                .readXMLFileWithoutDeclaration(resourceFile);
                        if (StringUtils.startsWith(xmlContent, "<metadata>")) {
                            apipMetadata = JAXBUtil.unmershall(xmlContent,
                                    APIPMetadata.class);
                        }
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Error parsing apip metadata " + e.getMessage(), e);
        }
        return apipMetadata;
    }

    public static Metadata readSBACMetadata(String outputZipFolder,
            ResourceType resource, Map<String, ResourceType> resourceMap) {
        Metadata sbacMetadata = null;
        try {
            if (resource != null
                    && CollectionUtils.isNotEmpty(resource.getDependencies())) {
                for (DependencyType dependency : resource.getDependencies()) {
                    ResourceType dependencyResource = (ResourceType) dependency
                            .getIdentifierref();
                    if (dependencyResource != null
                            && StringUtils.equals(dependencyResource.getType(),
                                    IMSPackageConstants.IMS_METADATA_TYPE)
                            && StringUtils.isNotBlank(IMSItemReader
                                    .getHref(dependencyResource))) {
                        File resourceFile = new File(outputZipFolder
                                + File.separator
                                + IMSItemReader.getHref(dependencyResource));
                        String xmlContent = FileUtil
                                .readXMLFileWithoutDeclaration(resourceFile);
                        if (StringUtils.startsWith(xmlContent, "<metadata>")
                                && StringUtils.contains(xmlContent,
                                        "<smarterAppMetadata")) {
                            sbacMetadata = SAAIFMetadataParser
                                    .parseMetdata(xmlContent);
                        }
                    }
                }
            }
        } catch (Exception e) {
            LOGGER.error("Error parsing apip metadata " + e.getMessage(), e);
        }
        return sbacMetadata;
    }
}
