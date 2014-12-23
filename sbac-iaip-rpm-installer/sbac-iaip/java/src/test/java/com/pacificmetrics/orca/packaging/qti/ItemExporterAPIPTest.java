/**
 * 
 */
package com.pacificmetrics.orca.packaging.qti;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.commons.io.FileUtils;
import org.junit.Before;
import org.junit.Test;

import com.pacificmetrics.orca.entities.DevState;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.export.apip.APIPItemExporter;
import com.pacificmetrics.orca.export.apip.APIPItemParser;
import com.pacificmetrics.orca.export.apip.APIPManifestWriter;

/**
 * @author maumock
 * 
 */
@SuppressWarnings("static-method")
public class ItemExporterAPIPTest {

    private static final Logger LOGGER = Logger
            .getLogger(ItemExporterAPIPTest.class.getName());
    private static APIPItemExporter ex;
    private static APIPItemParser apipItemParser;
    private static APIPManifestWriter manifestWriterAPIP = new APIPManifestWriter();

    // IMS items
    private static final String IMS_DIR = "/apipPkgs/apipv1p0_EntryTest_VE_TP_06/Items/";
    private static final String ITEM_VE_IP_01 = IMS_DIR
            + "Item_VE_IP_01/apipv1p0_EntryTest_VE_IP_01.xml";
    private static final String ITEM_VE_IP_02 = IMS_DIR
            + "Item_VE_IP_02/apipv1p0_EntryTest_VE_IP_02.xml";
    private static final String ITEM_VE_IP_03 = IMS_DIR
            + "Item_VE_IP_03/apipv1p0_EntryTest_VE_IP_03.xml";
    private static final String ITEM_VE_IP_04 = IMS_DIR
            + "Item_VE_IP_04/apipv1p0_EntryTest_VE_IP_04.xml";
    private static final String ITEM_VE_IP_05 = IMS_DIR
            + "Item_VE_IP_05/apipv1p0_EntryTest_VE_IP_05.xml";

    // Imported items in CDE
    private static final String CDE_DIR = "/apipPkgs/cde_resources/devcdesbac";
    private static final String VE_IP_02 = CDE_DIR + "/VE-IP-02.xml";
    private static final String VE_IP_05 = CDE_DIR + "/VE-IP-05.txt";
    private static final String VE_IP_06 = CDE_DIR + "/VE-IP-06.xml";

    private static final String BASE_DIR = "target/apipExportTesting/";

    static {
        try {
            apipItemParser = new APIPItemParser(true);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Error in APIPitemParser: " + e.getMessage(), e);
            fail("Unable to start test due to static initialization error.");
        }
    }

    /**
     * @throws java.lang.Exception
     */
    @Before
    public void setUp() throws Exception {
        ex = new APIPItemExporter();
        ex.setBaseDir(new File(BASE_DIR));
        ex.setManifestWriter(manifestWriterAPIP);
        ex.setItemParser(apipItemParser);
        ex.addDefaultManifestMetadata("version", "description", "packageName");
    }

    @Test
    public final void initializeTest() throws ItemExportException {
        ex.initialize();
        assertTrue(new File(BASE_DIR, "build/items").exists());
        assertTrue(new File(BASE_DIR, "dist").exists());
        ex.destroy();
    }

    @Test
    public final void destroyTest() throws ItemExportException {
        ex.initialize();
        ex.destroy();
        assertTrue(!new File(BASE_DIR, "build/items").exists());
        assertTrue(!new File(BASE_DIR, "dist").exists());
    }

    @Test
    public final void manifestTest() {
        assertEquals(ItemExporterAPIPTest.manifestWriterAPIP,
                ex.getManifestWriter());
    }

    @Test
    public final void apipParserTest() {
        assertEquals(ItemExporterAPIPTest.apipItemParser, ex.getItemParser());
    }

    @Test
    public final void remoteContentTest() {
        File f = new File("fileTesting");
        ex.setRemoteContentBase(f);
        assertEquals(f, ex.getRemoteContentBase());
    }

    @Test
    public final void baseDirTest() {
        File f = new File("fileTesting");
        ex.setBaseDir(f);
        assertEquals(f, ex.getBaseDir());
    }

    /**
     * Test method for
     * {@link com.pacificmetrics.orca.export.apip.APIPItemExporter#export(java.util.List)}
     * .
     * 
     * @throws ItemExportException
     * @throws IOException
     * @throws URISyntaxException
     */
    @Test
    public final void testIMSExport() throws ItemExportException, IOException,
            URISyntaxException {
        ex.setRemoteContentBase(new File(getClass().getResource(IMS_DIR)
                .toURI()));
        ex.initialize();
        InputStream is = ex.export(getIMSItems());
        is.close();
        ex.destroy();
    }

    @Test
    public final void testBadXMLExport() throws ItemExportException,
            IOException, URISyntaxException {
        // Update remote content base for resolution of CDE resources. Only
        // media files are currently pulled
        ex.setRemoteContentBase(new File(getClass().getResource(CDE_DIR)
                .toURI()));
        ex.initialize();
        try {
            ex.export(getCDEItems("VE-IP-05", VE_IP_05));
            fail("There should have been an error in this set.");
        } catch (ItemExportException e) {
            assertTrue(e.getMessage().contains(
                    "There are multiple occurrences of ID value 'content2'"));
        } finally {
            ex.destroy();
        }
    }

    @Test
    public final void testBadSchematronExport() throws ItemExportException,
            IOException, URISyntaxException {
        ex.setRemoteContentBase(new File(getClass().getResource(CDE_DIR)
                .toURI()));
        ex.initialize();
        try {
            ex.export(getCDEItems("VE-IP-06", VE_IP_06));
            fail("There should have been an error in this set.");
        } catch (ItemExportException e) {
            assertTrue(e
                    .getMessage()
                    .contains(
                            "The StringIdentifier and ResponseIdentifier attribute values must not be the same."));
            assertTrue(e.getMessage().contains(
                    "Invalid number of \"calculator\" elements"));
        } finally {
            ex.destroy();
        }
    }

    @Test
    public final void testGoodExport() throws ItemExportException, IOException,
            URISyntaxException {
        ex.setRemoteContentBase(new File(getClass().getResource(CDE_DIR)
                .toURI()));
        ex.initialize();
        InputStream fis = ex.export(getCDEItems("VE-IP-02", VE_IP_02));
        fis.close();
        ex.destroy();
    }

    // Magic is the bank id is not defined for these items.
    private List<Item> getIMSItems() throws IOException, URISyntaxException {
        final List<Item> items = new ArrayList<Item>(1);
        items.add(getItem("Item_VE_IP_01", ITEM_VE_IP_01, 0));
        items.add(getItem("Item_VE_IP_02", ITEM_VE_IP_02, 0));
        items.add(getItem("Item_VE_IP_03", ITEM_VE_IP_03, 0));
        items.add(getItem("Item_VE_IP_04", ITEM_VE_IP_04, 0));
        items.add(getItem("Item_VE_IP_05", ITEM_VE_IP_05, 0));
        return items;
    }

    private List<Item> getCDEItems(String id, String xml) throws IOException,
            URISyntaxException {
        final List<Item> items = new ArrayList<Item>(1);
        items.add(getItem(id, xml, 15));
        return items;
    }

    private Item getItem(String id, String xml, int bankId) throws IOException,
            URISyntaxException {
        Item item = new Item();
        item.setQtiData(FileUtils.readFileToString(new File(getClass()
                .getResource(xml).toURI()), "UTF-8"));
        item.setExternalId(id);
        item.setItemBankId(bankId);

        DevState state = new DevState();
        state.setName("Junit Testing");
        item.setDevState(state);

        return item;
    }
}
