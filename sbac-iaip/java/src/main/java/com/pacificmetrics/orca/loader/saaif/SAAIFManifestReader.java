package com.pacificmetrics.orca.loader.saaif;

import java.io.InputStream;
import java.util.HashMap;
import java.util.Map;

import org.apache.commons.collections.CollectionUtils;

import com.pacificmetrics.orca.utils.FileUtil;
import com.pacificmetrics.orca.utils.JAXBUtil;
import com.pacificmetrics.saaif.manifest.Manifest;
import com.pacificmetrics.saaif.manifest.Manifest.Resources.Resource;

public class SAAIFManifestReader {

    private SAAIFManifestReader() {
    }

    public static Manifest readManifest(InputStream inputStream) {
        String manifestContent = FileUtil.readToString(inputStream, false);
        Manifest manifest = JAXBUtil.<Manifest> unmershall(manifestContent,
                Manifest.class);
        return manifest;
    }

    public static Map<String, Resource> readResources(Manifest manifest) {
        Map<String, Resource> resourceMap = new HashMap<String, Resource>();
        if (manifest != null
                && manifest.getResources() != null
                && CollectionUtils.isNotEmpty(manifest.getResources()
                        .getResource())) {
            for (Resource resource : manifest.getResources().getResource()) {
                resourceMap.put(resource.getIdentifier(), resource);
            }
        }
        return resourceMap;
    }

}
