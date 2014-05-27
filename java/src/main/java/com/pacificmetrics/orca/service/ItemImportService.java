package com.pacificmetrics.orca.service;

import java.io.IOException;
import java.util.List;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.jws.WebService;
import javax.servlet.http.HttpServletRequest;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.PathParam;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPathExpressionException;

import org.apache.commons.lang.StringUtils;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.MetadataServices;
import com.pacificmetrics.orca.entities.MetadataMapping;
import com.pacificmetrics.orca.mbeans.CacheManager;
import com.pacificmetrics.orca.utils.XMLUtil;

/**
 * Web service for all requests related to item import. Supports import of item's metadata in QTI/APIP XML format and mapping data to the domain tables 
 * 
 * @author amiliteev
 *
 */
@Path("/service/import")
@WebService
public class ItemImportService {

    private static final Logger log = Logger.getLogger(ItemImportService.class.getName());
    
    @EJB
    transient private MetadataServices metadataServices;
    
    @EJB
    transient private ItemServices itemServices;
    
    /**
     * Convenience method for testing if service is available.
     * 
     * @return "pong"
     */
    @GET
    @Path("ping")
    public String ping() {
        return "pong";
    }

    /**
     * This method imports APIP/QTI metadata for the item with given ID; 
     * First, the entire XML persisted in i_metadata_xml field of 'item' table
     * Second, mapping of the values is performed according to rules in metadata_mapping table; 
     * fields in item table may be populated and entries in item_characterization table may be made
     * 
     * 
     * @param itemId   Item ID (i_id) for the item (injected from url path). Item for which metadata imported must exist
     * @param xml      XML bean of LomResourceType containing metadata for the item
     * @param request  Injected HTTP Servlet Request
     * @return
     * @throws IOException
     */
    @POST
    @Path("itemMetadata/{item}")
    @Consumes(MediaType.APPLICATION_XML)
    public Response itemMetadata(final @PathParam("item") long itemId, final String xmlString, @Context HttpServletRequest request) {
        log.info("/service/import/itemMetadata");
        log.info("item id: " + itemId);
        try {
//            String xmlString = XMLUtil.marchal(xml);
            log.info(xmlString);
            
            itemServices.updateItemField(itemId, "i_metadata_xml", xmlString);
            
            //Application-scoped managed bean can be found in the attribute map of servlet context
            CacheManager cache = (CacheManager)request.getServletContext().getAttribute(CacheManager.class.getAnnotation(ManagedBean.class).name());
            
//            XMLUtil parser = new XMLUtil(false);
//            parser.load(xmlString);
//            
//            Object vv = parser.getValues("/lom/qtiMetadata/feedbackType/text()");
//            System.out.println(vv);
            
            mapLomResourceType(itemId, xmlString, cache);
            
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR).entity(e.toString()).build(); //TODO more sophisticated error handling to follow in next user stories
        }
        return Response.ok().build();        
    }
    
    /**
     * This method performs mapping of the data in XML bean (LomResourceType) to fields in 'item' table and entries in 'item_characterization' table
     * Mapping data is retrieved from 'metadata_mapping' table; mapping specifies path to the source data in XML Bean object (using JXPath) and corresponding 
     * target data elements where data should be placed. Mapping also may require looking up values in lookup tables. LookupCache object is used to perform lookup   
     * 
     * @param itemId Id of the item for which mapping is performed 
     * @param lom    XML bean of LomResourceType
     * @param cache  CacheManager instance to access LookupCache
     * @throws IOException 
     * @throws SAXException 
     * @throws ParserConfigurationException 
     * @throws XPathExpressionException 
     */
    private void mapLomResourceType(long itemId, String xmlString, CacheManager cache) throws ParserConfigurationException, SAXException, IOException, XPathExpressionException {
        XMLUtil parser = new XMLUtil(false);
        parser.load(xmlString);
        List<MetadataMapping> metadataMappingList = metadataServices.getMetadataMappingsForItems();
        for (MetadataMapping mm: metadataMappingList) {
            String valueToMap = StringUtils.join(parser.getValues(mm.getxPath()), " ");
            if (StringUtils.isEmpty(StringUtils.trim(valueToMap))) { //value not found for xpath
                continue;
            }
            Object valueToSave = valueToMap;
            if (!StringUtils.isEmpty(mm.getLookupTableName())) {
                //looking up for the numeric code corresponding to the supplied string value
                valueToSave = cache.getLookupCache().getLookupCode(mm.getLookupTableName(), mm.getLookupByField(), mm.getLookupPrefix(), mm.getLookupValueField(), valueToMap);
                if (valueToSave == null) {
                    log.warning("Cannot determine lookup code for " + mm.getxPath() + " = " + valueToMap);
                    continue;
                }
            }
            if (StringUtils.isNotEmpty(mm.getFieldName())) {
                //updating 'item' table's field
                itemServices.updateItemField(itemId, mm.getFieldName(), valueToSave);
            } else if (mm.getCharacteristic() > 0) {
                //inserting record into 'item_characteristic' table; value must be numeric!
                if (valueToSave instanceof Number) {
                    itemServices.upsertItemCharacterization(itemId, mm.getCharacteristic(), ((Number)valueToSave).intValue());
                } else {
                    log.warning("Value to save: " + valueToSave + " is not numeric");
                }
            } else {
                log.warning("Invalid mapping entry: neither field nor characteristic code specified. Mapping ID: " + mm.getId());
            }
        }
    }
    
}
