/**
 * 
 */
package com.pacificmetrics.orca.export.apip;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.FileNotFoundException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.logging.Logger;

import javax.xml.bind.JAXBContext;
import javax.xml.bind.JAXBException;
import javax.xml.bind.Marshaller;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.stream.StreamResult;
import javax.xml.transform.stream.StreamSource;
import javax.xml.xpath.XPathExpressionException;

import com.pacificmetrics.apip.cp.manifest.CopyrightAndOtherRestrictionsType;
import com.pacificmetrics.apip.cp.manifest.DependencyType;
import com.pacificmetrics.apip.cp.manifest.DescriptionType;
import com.pacificmetrics.apip.cp.manifest.EducationalType;
import com.pacificmetrics.apip.cp.manifest.FileType;
import com.pacificmetrics.apip.cp.manifest.GeneralType;
import com.pacificmetrics.apip.cp.manifest.IdentifierType;
import com.pacificmetrics.apip.cp.manifest.LearningResourceTypeType;
import com.pacificmetrics.apip.cp.manifest.LifeCycleType;
import com.pacificmetrics.apip.cp.manifest.LomManifestType;
import com.pacificmetrics.apip.cp.manifest.LomResourceType;
import com.pacificmetrics.apip.cp.manifest.Manifest;
import com.pacificmetrics.apip.cp.manifest.ObjectFactory;
import com.pacificmetrics.apip.cp.manifest.QtiMetadataType;
import com.pacificmetrics.apip.cp.manifest.ResourceType;
import com.pacificmetrics.apip.cp.manifest.RightsType;
import com.pacificmetrics.apip.cp.manifest.StringType;
import com.pacificmetrics.apip.cp.manifest.TitleType;
import com.pacificmetrics.apip.cp.manifest.VersionType;

/**
 * @author maumock
 * 
 */
public class APIPManifestWriter {
    private static final Logger LOGGER = Logger
            .getLogger(APIPManifestWriter.class.getName());
    private final ObjectFactory of = new ObjectFactory();
    private final Manifest m = this.of.createManifest();
    private final Set<String> uniqueIds = new HashSet<String>();

    public void addItem(APIPItem item) throws XPathExpressionException {
        if (item.getId() == null || this.uniqueIds.contains(item.getId())) {
            item.setId(getUniqueId());
        } else {
            item.setId(formatUniqueId(item.getId()));
        }

        item.setHref(getItemHref(item.getId(), item.getId() + ".xml"));
        item.setHrefBase(getItemHrefBase(item.getId()));

        ResourceType resource = this.of.createResourceType();
        resource.setHref(item.getHref());
        resource.setType("imsqti_apipitem_xmlv2p1");
        resource.setId(item.getId());
        this.m.getResources().add(resource);

        

        item.setMetadataHref(getItemMetadataHref(item.getId(), item.getId()
                + "_metadata.xml"));
        item.setMetadataHrefBase(getItemMetadataHrefBase(item.getId()));

        
        ResourceType metadataResource = this.of.createResourceType();
        metadataResource.setHref(item.getMetadataHref());
        metadataResource.setType("controlfile/apip_xmlv1p0");
       
        metadataResource.setId("metadata_" + item.getId());
        this.m.getResources().add(metadataResource);

        
        FileType metadataFile = this.of.createFileType();
        metadataFile.setHref(item.getMetadataHref());
        metadataResource.getFiles().add(metadataFile);

        List<String> dependencies = new ArrayList<String>();

      
        dependencies.add("metadata_" + item.getId());

        for (String r : item.getResources()) {
            LOGGER.info(item.getHrefBase() + r);
            ResourceType file = getFile(item.getHrefBase() + r);
            file.setHref(item.getHrefBase() + r);
            this.m.getResources().add(file);
            dependencies.add(file.getId());
        }

        for (String depend : dependencies) {
            DependencyType dep = this.of.createDependencyType();
            dep.setIdRef(depend);
            resource.getDependencies().add(dep);
        }

        FileType file = this.of.createFileType();
        file.setHref(item.getHref());
        resource.getFiles().add(file);
    }

    public void addDefaultManifestMetadata(String version, String description,
            String packageName) {
        this.m.setId(getUniqueId());

        LomManifestType lom = this.of.createLomManifestType();
        this.m.setLom(lom);
        this.m.setSchema("APIP Item Bank");
        this.m.setSchemaVersion("1.0.0");

        EducationalType ed = this.of.createEducationalType();
        LearningResourceTypeType lrt = this.of.createLearningResourceTypeType();
        lrt.setSource("APIPv1.0");
        lrt.setValue("APIP Package");
        ed.setLearningResourceType(lrt);
        lom.setEducational(ed);

        GeneralType gen = this.of.createGeneralType();
        lom.setGeneral(gen);

        IdentifierType id = this.of.createIdentifierType();
        id.setEntry(packageName);
        gen.setIdentifier(id);

        TitleType title = this.of.createTitleType();
        title.getStrings().add(getStr(description));
        gen.setTitle(title);

        LifeCycleType lf = this.of.createLifeCycleType();
        lom.setLifeCycle(lf);

        VersionType vt = this.of.createVersionType();
        vt.getStrings().add(getStr(version));
        lf.setVersion(vt);

        RightsType rights = this.of.createRightsType();
        lom.setRights(rights);

        CopyrightAndOtherRestrictionsType copy = this.of
                .createCopyrightAndOtherRestrictionsType();
        copy.setSource("LOMv1.0");
        copy.setValue("yes");
        rights.setCopyrightAndOtherRestrictions(copy);

        DescriptionType dt = this.of.createDescriptionType();
        dt.getStrings().add(getStr("2012 IMS Global Learning Consortium Inc."));
        rights.setDescription(dt);
    }

    public final void write(OutputStream outputStream) throws JAXBException,
            FileNotFoundException, TransformerException {
        ByteArrayOutputStream os = new ByteArrayOutputStream();
        JAXBContext jc = JAXBContext.newInstance(this.m.getClass().getPackage()
                .getName());
        Marshaller marshaller = jc.createMarshaller();
        marshaller.marshal(this.m, os);
        String xml = new String(os.toByteArray());
        xml = xml.replaceAll("[ ]+xmlns=\\\".*?\\\"", "");

        TransformerFactory tFactory = TransformerFactory.newInstance();
        tFactory.setAttribute("indent-number", 4);
        Transformer transformer = tFactory.newTransformer(new StreamSource(
                APIPManifestWriter.class
                        .getResourceAsStream("/xslt/apip/manifest.xsl")));
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        transformer.transform(
                new StreamSource(new ByteArrayInputStream(xml.getBytes())),
                new StreamResult(outputStream));
    }

    private static String getItemHref(String base, String fileName) {
        return getItemHrefBase(base) + fileName;
    }

    private static String getItemMetadataHref(String base, String fileName) {
        return getItemMetadataHrefBase(base) + fileName;
    }

    private static String getItemHrefBase(String base) {
        return "items/" + base + '/';
    }

    private static String getItemMetadataHrefBase(String base) {
        return "metadata/" + base + "/";
    }

    @SuppressWarnings("boxing")
    private LomResourceType mkResourceLom(APIPItem item, String description)
            throws XPathExpressionException {
        LomResourceType lom = this.of.createLomResourceType();

        GeneralType gen = this.of.createGeneralType();
        lom.setGeneral(gen);
        IdentifierType id = this.of.createIdentifierType();
        id.setEntry(item.getId());
        gen.setIdentifier(id);

        LifeCycleType lf = this.of.createLifeCycleType();
        lom.setLifeCycle(lf);
        VersionType vt = this.of.createVersionType();
        vt.getStrings().add(getStr(item.getVersion()));
        lf.setVersion(vt);

        EducationalType ed = this.of.createEducationalType();
        lom.setEducational(ed);
        DescriptionType dt = this.of.createDescriptionType();
        dt.getStrings().add(getStr(description));
        ed.setDescription(dt);

        QtiMetadataType meta = this.of.createQtiMetadataType();
        meta.setComposite(item.isComposite());
        meta.setFeedbackType(item.getFeedbackType());
        meta.getInteractionTypes().addAll(item.getInteractionTypes());
        meta.setSolutionAvailable(item.isSolutionAvailable());
        meta.setTimeDependent(item.isTimeDependent());
        meta.setToolName(item.getToolName());
        meta.setToolVersion(item.getToolVersion());
        meta.setToolVendor(item.getToolVendor());
        lom.setQtiMetadata(meta);

        return lom;
    }

    private ResourceType getFile(String href) {
        ResourceType item = this.of.createResourceType();
        item.setType("associatedcontent/apip_xmlv1p0/learning-application-resource");
        item.setId(getUniqueId());

        FileType file = this.of.createFileType();
        file.setHref(href);
        item.getFiles().add(file);
        return item;
    }

    private static final StringType getStr(String value) {
        StringType st = new StringType();
        st.setValue(value);
        return st;
    }

    private String formatUniqueId(String id) {
        String out = id.replaceAll("[^0-9a-zA-Z\\-_]", "");
        if (out.length() == 0) {
            return getUniqueId();
        }
        this.uniqueIds.add(out);
        return out;
    }

    private final String getUniqueId() {
        String key = 'A' + UUID.randomUUID().toString().substring(1)
                .toUpperCase();
        this.uniqueIds.add(key);
        return key;
    }
}
