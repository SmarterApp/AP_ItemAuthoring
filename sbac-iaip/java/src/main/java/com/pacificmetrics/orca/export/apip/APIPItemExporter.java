/**
 * 
 */
package com.pacificmetrics.orca.export.apip;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.nio.channels.FileChannel;
import java.util.List;
import java.util.logging.Logger;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

import javax.xml.bind.JAXBException;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.TransformerException;
import javax.xml.xpath.XPathExpressionException;

import org.xml.sax.SAXException;

import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.Passage;
import com.pacificmetrics.orca.entities.Rubric;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.export.ItemExporter;

/**
 * @author maumock
 * 
 */
public class APIPItemExporter implements ItemExporter {
    private File baseDir;
    private File remoteContentBase;
    private APIPManifestWriter manifestWriter;
    private APIPItemParser itemParser;
    private static final Logger LOGGER = Logger.getLogger(APIPItemExporter.class.getName());

    /**
     * @see com.pacificmetrics.orca.export.ItemExporter#initialize()
     */
    @Override
    public void initialize() throws ItemExportException {
        LOGGER.info("Creating build directory structure.");

        File items = new File(this.baseDir, "build/items");
        LOGGER.info("Build items directory:" + items.getAbsolutePath());

        File dist = new File(this.baseDir, "dist");
        LOGGER.info("Distribution directory:" + dist.getAbsolutePath());
        items.mkdirs();
        dist.mkdirs();

        if (!items.exists() || !dist.exists()) {
            throw new ItemExportException("Unable to create directory:" + items.getAbsolutePath());
        }
    }

    /**
     * @see com.pacificmetrics.orca.export.ItemExporter#destroy()
     */
    @Override
    public void destroy() throws ItemExportException {
        LOGGER.info("Cleaning working directory");
        try {
            delete(this.baseDir);
        } catch (IOException e) {
            throw new ItemExportException(e);
        }
    }

    /**
     * This method is assuming the item external id is part of the path to the
     * resources. This is a big assumption that could easily break.
     * 
     * @see com.pacificmetrics.orca.export.ItemExporter#export(java.util.List)
     */
    @Override
    public InputStream export(List<Item> items) throws ItemExportException {
        try {
            LOGGER.info("Processing items");
            File resourceDir;
            for (Item item : items) {
                if (item == null) {
                    throw new ItemExportException("An item in the list was null. Exiting the export process.");
                } else if (item.getExternalId() == null) {
                    throw new ItemExportException("Item with id:" + item.getId() + " had an unusable external id.");
                }

                LOGGER.info("Parsing item id:" + item.getId());
                APIPItem apipItem = this.itemParser.getAPIPItem(item);

                LOGGER.info("Adding item information to manifest.");
                this.manifestWriter.addItem(apipItem);

                LOGGER.info("Writing XML to distribution directory.");
                File qtiXML = new File(this.baseDir, "build/" + apipItem.getHref());
                LOGGER.info("QTI XML file path:" + qtiXML.getAbsolutePath());
                qtiXML.getParentFile().mkdirs();
                FileWriter out = new FileWriter(qtiXML);
                try {
                    out.write(item.getQtiData());
                } finally {
                    out.close();
                }

                // create item metadata resource file
                File metadataXML = new File(this.baseDir, "build/" + apipItem.getMetadataHref());
                LOGGER.info("Metadata XML file path:" + metadataXML.getAbsolutePath());
                metadataXML.getParentFile().mkdirs();
                out = new FileWriter(metadataXML);
                try {
                    out.write("<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"no\"?>");
                    if (item.getMetadataXml() != null && item.getMetadataXml().length() > 0
                            // DE1370 stripping LOM metadata since not how TIB expects metadata
                            && !item.getMetadataXml().contains("lom")) {
                        out.write(item.getMetadataXml());
                        LOGGER.info(item.getMetadataXml());
                    } else {
                        // TODO: Update once we get a common understanding of what metadata xml will require minimum TIB
                        // required metadata: these fields must not be null
                        StringBuilder buf = new StringBuilder();
                        buf.append("<metadata>")
                                .append("\t<SYSTEM_Source>")
                                .append(item.getSource())
                                .append("</SYSTEM_Source>\r\n")
                                .append("\t<SYSTEM_ItemKeywords>")
                                .append(item.getKeywords())
                                .append("</SYSTEM_ItemKeywords>\r\n")
                                .append("\t<SYSTEM_ItemSubcategory>")
                                .append(item.getSubCategory())
                                .append("</SYSTEM_ItemSubcategory>\r\n")
                                // .append("<!-- must be FT [field test] or OT [operational test] -->")
                                .append("\t<SYSTEM_Status>OT</SYSTEM_Status>\r\n")
                                // .append("<!-- must be a number gte 0 -->")
                                .append("\t<SYSTEM_ItemVersion>").append(item.getVersion())
                                .append("</SYSTEM_ItemVersion>\r\n").append("\t<SYSTEM_ItemType>")
                                .append(item.getItemType()).append("</SYSTEM_ItemType>\r\n").append("\t<SYSTEM_Grade>")
                                .append(item.getGradeLevel() == null ? "NONE" : item.getGradeLevel())
                                .append("</SYSTEM_Grade>\r\n").append("\t<SYSTEM_Subject>")
                                .append(item.getSubject() == null ? "NONE" : item.getSubject())
                                .append("</SYSTEM_Subject>\r\n").append("\t<SYSTEM_Author>")
                                .append(item.getAuthor() == null ? "NONE" : item.getAuthor().getUserName())
                                .append("</SYSTEM_Author>\r\n").append("\t<SB_Difficulty>")
                                .append(item.getDifficulty()).append("</SB_Difficulty>\r\n")
                                .append("\t<SYSTEM_ItemID>").append(item.getExternalId())
                                .append("</SYSTEM_ItemID>\r\n").append("</metadata>");

                        out.write(buf.toString());
                        LOGGER.info(buf.toString());
                    }
                } finally {
                    out.close();
                }
                
                LOGGER.info("Copying support files for item.");
                for (String resource : apipItem.getResources()) {
                    // XXX Very large assumption here. May not be the best way to handle this in CDE.
                    if (item.getItemBankId() > 0) {
                        resourceDir = new File(this.remoteContentBase, "images/lib" + item.getItemBankId() + '/'
                                + item.getExternalId());
                    } else {
                        // XXX not clear why this is here
                        resourceDir = new File(this.remoteContentBase, item.getExternalId());
                    }

                    File src = new File(resourceDir, resource);
                    LOGGER.info("Source file path:" + src.getAbsolutePath());
                    
                    // check passage resources
                    if (!src.exists()) {
                        for (Passage passage : item.getPassages()) {
                            // passage images
                            resourceDir = new File(this.remoteContentBase, "passages/lib" + passage.getItemBankId() + "/images/p" + passage.getId());
                            src = new File(resourceDir, resource);
                            
                            if (src.exists()) {
                                break;
                            }
                            
                            // passage media
                            resourceDir = new File(this.remoteContentBase, "passages/lib" + passage.getItemBankId() + "/media/p" + passage.getId());
                            src = new File(resourceDir, resource);
                            
                            if (src.exists()) {
                                break;
                            }
                        }
                    }
                    
                    // check rubric resources
                    if (!src.exists()) {
                        for (Rubric rubric : item.getRubrics()) {
                            // rubric images
                            resourceDir = new File(this.remoteContentBase, "rubrics/lib" + rubric.getItemBankId() + "/images/r" + rubric.getId());
                            src = new File (resourceDir, resource);
                            
                            if (src.exists()) {
                                break;
                            }
                        }
                    }

                    File dest = new File(this.baseDir, "build/" + apipItem.getHrefBase() + resource);
                    LOGGER.info("Destination file path:" + dest.getAbsolutePath());

                    
                    copyFile(src, dest);
                }
            }

            LOGGER.info("Writing APIP compliant manifest.");
            File manifestXML = new File(this.baseDir, "build/imsmanifest.xml");
            LOGGER.info("Manifest file path:" + manifestXML.getAbsolutePath());
            FileOutputStream fos = new FileOutputStream(manifestXML);
            this.manifestWriter.write(fos);
            fos.close();

            LOGGER.info("Creating final zip archive.");
            File zip = new File(this.baseDir, "dist/apip.zip");
            LOGGER.info("Zip file path:" + zip.getAbsolutePath());
            File buildDir = new File(this.baseDir, "build");
            LOGGER.info("Zip content directory:" + buildDir.getAbsolutePath());
            zip(buildDir, zip);

            return new FileInputStream(zip);
        } catch (XPathExpressionException e) {
            throw new ItemExportException(e);
        } catch (ParserConfigurationException e) {
            throw new ItemExportException(e);
        } catch (SAXException e) {
            throw new ItemExportException(e);
        } catch (IOException e) {
            throw new ItemExportException(e);
        } catch (JAXBException e) {
            throw new ItemExportException(e);
        } catch (TransformerException e) {
            throw new ItemExportException(e);
        }
    }

    public void addDefaultManifestMetadata(String version, String description, String packageName) {
        this.manifestWriter.addDefaultManifestMetadata(version, description, packageName);
    }

    /**
     * @return the manifestWriter
     */
    public APIPManifestWriter getManifestWriter() {
        return this.manifestWriter;
    }

    /**
     * @param manifestWriter
     *            the manifestWriter to set
     */
    public void setManifestWriter(APIPManifestWriter manifestWriter) {
        this.manifestWriter = manifestWriter;
    }

    /**
     * @return the itemParser
     */
    public APIPItemParser getItemParser() {
        return this.itemParser;
    }

    /**
     * @param itemParser
     *            the itemParser to set
     */
    public void setItemParser(APIPItemParser itemParser) {
        this.itemParser = itemParser;
    }

    /**
     * @return the baseDir
     */
    public File getBaseDir() {
        return this.baseDir;
    }

    /**
     * @param baseDir
     *            the baseDir to set
     */
    public void setBaseDir(File baseDir) {
        this.baseDir = baseDir;
    }

    /**
     * @return the remoteContentBase
     */
    public File getRemoteContentBase() {
        return this.remoteContentBase;
    }

    /**
     * @param remoteContentBase
     *            the remoteContentBase to set
     */
    public void setRemoteContentBase(File remoteContentBase) {
        this.remoteContentBase = remoteContentBase;
        LOGGER.info("Content base directory:" + remoteContentBase.getAbsolutePath());
    }

    private static final void zip(File directory, File zip) throws IOException {
        byte[] buffer = new byte[8192];
        FileOutputStream fos = new FileOutputStream(zip);
        ZipOutputStream zos = new ZipOutputStream(fos);
        try {
            zip(directory, directory, zos, buffer);
        } finally {
            zos.close();
            fos.close();
        }
    }

    private static final void zip(File directory, File base, ZipOutputStream zos, byte[] buffer) throws IOException {
        int read = 0;
        for (File file : directory.listFiles()) {
            if (file.isDirectory()) {
                zip(file, base, zos, buffer);
            } else {
                FileInputStream in = new FileInputStream(file);
                try {
                    ZipEntry entry = new ZipEntry(file.getPath().substring(base.getPath().length() + 1));
                    zos.putNextEntry(entry);
                    while ((read = in.read(buffer)) > -1) {
                        zos.write(buffer, 0, read);
                    }
                } finally {
                    in.close();
                }
            }
        }
    }

    private static final void copyFile(File sourceFile, File destFile) throws IOException {
        if (!destFile.exists()) {
            destFile.createNewFile();
        }

        FileChannel source = null;
        FileChannel destination = null;
        try {
            source = new FileInputStream(sourceFile).getChannel();
            destination = new FileOutputStream(destFile).getChannel();
            destination.transferFrom(source, 0, source.size());
        } finally {
            if (source != null) {
                source.close();
            }
            if (destination != null) {
                destination.close();
            }
        }
    }

    private static final void delete(File f) throws IOException {
        if (f.isDirectory()) {
            for (File c : f.listFiles()) {
                delete(c);
            }
        }
        if (!f.delete()) {
            throw new FileNotFoundException("Failed to delete file: " + f.getAbsolutePath());
        }
    }
}
