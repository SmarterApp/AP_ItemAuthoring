package com.pacificmetrics.orca.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.Response;
import javax.xml.bind.JAXBException;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.io.annotation.FileContent;
import org.unitils.mock.Mock;
import org.unitils.mock.annotation.AfterCreateMock;
import org.unitils.orm.jpa.JpaUnitils;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.MetadataServices;
import com.pacificmetrics.orca.ejb.MiscServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.mbeans.CacheManager;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

@DataSet("ItemImportServiceTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class ItemImportServiceTest extends UnitilsJUnit4 {

    @TestedObject
    ItemImportService itemImportService;
    
    @TestedObject
    CacheManager cacheManager;
    
    @InjectIntoByTypeExt(target={"itemImportService"})
    @TestedObject
    MetadataServices metadataServices;

    @InjectIntoByTypeExt(target={"itemImportService"})
    @TestedObject
    ItemServices itemServices;

    @InjectIntoByTypeExt(target={"cacheManager"})
    @TestedObject
    MiscServices miscServices;

    @InjectIntoByTypeExt(target={"itemServices", "metadataServices", "miscServices"})
    @PersistenceContext
    EntityManager entityManager;
    
    @FileContent("/import/ItemMetadata.xml")
    String itemMetadataXML;
    
    Mock<HttpServletRequest> request;
    
    @AfterCreateMock
    void initMock(Object mock, String name, Class<?> type) throws IOException {
//        if ("request".equals(name)) {
//            request.returns(cacheManager).getServletContext().getAttribute("cache");
//        }
    }
    
    @Test
    public void testPing() {
        assertEquals("pong", itemImportService.ping());
    }

    /**
     * This method tests itemMetadata call for item with id=1001; XML is read from /import/ItemMetadata.xml file,
     * It verifies that i_metadata_xml and i_description fields are updated for this item, and that 
     * new entry is made into item_characterization for this item with ic_type = 101 and ic_value = 8
     * 
     * @throws JAXBException
     * @throws FileNotFoundException
     */
    @Test
    public void testItemMetadata() throws JAXBException, FileNotFoundException {
//        File file = new File("test-classes/import/ItemMetadata.xml");
//        File file = new File("src/test/resources/import/ItemMetadata.xml");
        
//        JAXBContext jaxbCtx = JAXBContext.newInstance(LomResourceType.class.getPackage().getName());
//        Unmarshaller u = jaxbCtx.createUnmarshaller();
//        SAXSource saxSource = new SAXSource(new InputSource(new StringReader(itemMetadataXML)));
//        JAXBElement<LomResourceType> xml = (JAXBElement<LomResourceType>)u.unmarshal(saxSource, LomResourceType.class);
        
        //Initializing mock for HttpServletRequest
        cacheManager.load();
        request.returns(cacheManager).getServletContext().getAttribute("cache");
        
        //Invoking web service method
        Response r = itemImportService.itemMetadata(1001, itemMetadataXML, request.getMock());
        //Verifying web service returned OK 
        assertEquals(200, r.getStatus());
        JpaUnitils.flushDatabaseUpdates();
        
        //Retrieving item, checking description and metadata XML
        Item item = itemServices.findItemById(1001);
        assertNotNull(item);
        assertNotNull(item.getDescription());
        String metadataXML = item.getMetadataXml();
        assertTrue(metadataXML != null && metadataXML.length() > 100);
        
        //Retrieving and checking item characterization
        List<ItemCharacterization> characterizationList = item.getItemCharacterizations();
        assertTrue(characterizationList != null && characterizationList.size() > 0);
        ItemCharacterization ic = characterizationList.get(0);
        assertEquals(101, ic.getType());
        assertEquals(8, ic.getIntValue());
        
    }

}
