package com.pacificmetrics.orca.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.xml.bind.JAXBException;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;
import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.io.annotation.FileContent;
import org.unitils.mock.Mock;
import org.unitils.mock.annotation.AfterCreateMock;
import org.unitils.orm.jpa.JpaUnitils;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.MetadataServices;
import com.pacificmetrics.orca.ejb.MiscServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemCharacterization;
import com.pacificmetrics.orca.mbeans.CacheManager;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.UniformInterfaceException;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.multipart.FormDataBodyPart;
import com.sun.jersey.multipart.FormDataMultiPart;

@DataSet("ItemImportServiceTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class ItemImportServiceTest extends UnitilsJUnit4 {

	private static final Log LOGGER = LogFactory.getLog(ItemImportServiceTest.class);
	
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

    @InjectIntoByTypeExt(target={"itemImportService"})
    @TestedObject
    ContentMoveServices contentMoveServices;
    
    @InjectIntoByTypeExt(target={"itemServices", "metadataServices", "miscServices", "contentMoveServices"})
    @PersistenceContext
    EntityManager entityManager;
    
    @FileContent("/import/ItemMetadata.xml")
    String itemMetadataXML;
    
    Mock<HttpServletRequest> request;
    
    @AfterCreateMock
    void initMock(Object mock, String name, Class<?> type) throws IOException {
    	// Do nothing because of X and Y.
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
        assertTrue(characterizationList != null && !characterizationList.isEmpty());
        ItemCharacterization ic = characterizationList.get(0);
        assertEquals(101, ic.getType());
        assertEquals(8, ic.getIntValue());
        
    }
    
    @Test
    public void testImportItmPkg() {
    	String program = "15";
    	String user = "1";
    	String moveType = "1";
    	
    	String fileName = "apipv1p0_EntryTest_VE_IP_101.zip";    	
    	//Invoking web service method
    	String webServiceUrl = "https://iaip.pacificmetrics.com/orca-sbac/service/import/importItmPkg";
		try {
			FormDataMultiPart form = new FormDataMultiPart();
			
			form.bodyPart(new FormDataBodyPart("program",program));
			form.bodyPart(new FormDataBodyPart("user", user));
			form.bodyPart(new FormDataBodyPart("moveType", moveType));
			form.bodyPart(new FormDataBodyPart("fileName", fileName));
			
			FormDataBodyPart formDataBodyPart = new FormDataBodyPart("file",
					new ByteArrayInputStream(new byte[1]),
					MediaType.APPLICATION_OCTET_STREAM_TYPE);
			form.bodyPart(formDataBodyPart);
			
			//Invoking web service method
			WebResource resource = Client.create().resource(webServiceUrl);
			String response = resource.type(MediaType.MULTIPART_FORM_DATA)
			        .post(String.class, form);
			
			JSONObject jsonResponse = new JSONObject(response);
			String responseCode = jsonResponse.getString("importStatusCode");
			//Verifying web service returned import status code 0 
			assertEquals("0", responseCode);
			
			fileName = "apipv1p0_EntryTest_VE_IP_102.xls";
			form.bodyPart(new FormDataBodyPart("fileName", fileName));
			//Invoking web service method
			resource = Client.create().resource(webServiceUrl);
			response = resource.type(MediaType.MULTIPART_FORM_DATA)
			        .post(String.class, form);
			jsonResponse = new JSONObject(response);
			responseCode = jsonResponse.getString("importStatusCode");
			//Verifying web service returned import status code 0 
			assertEquals("0", responseCode);
	        JpaUnitils.flushDatabaseUpdates();
		} catch (UniformInterfaceException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			LOGGER.error(e.getMessage(),e);
		} catch (ClientHandlerException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			LOGGER.error(e.getMessage(),e);
		} catch (JSONException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			LOGGER.error(e.getMessage(),e);
		}
    }
    
    @Test
    public void testRollbackItmPkg() throws JAXBException, JSONException { 

        
        //Invoking web service method
        Response r = itemImportService.rollbackItmPkg("4", "file1.zip");
        //Verifying web service returned OK 
        assertEquals(200, r.getStatus());
        JpaUnitils.flushDatabaseUpdates();
       
    }


}
