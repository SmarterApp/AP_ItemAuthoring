package com.pacificmetrics.orca.service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
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
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.xpath.XPathExpressionException;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.cxf.jaxrs.ext.multipart.Multipart;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;
import org.xml.sax.SAXException;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.MetadataServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.entities.MetadataMapping;
import com.pacificmetrics.orca.loader.ims.IMSPackageReader;
import com.pacificmetrics.orca.loader.ims.IMSValidator;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageConstants;
import com.pacificmetrics.orca.loader.saaif.SAAIFPackageReader;
import com.pacificmetrics.orca.mbeans.CacheManager;
import com.pacificmetrics.orca.utils.XMLUtil;

/**
 * Web service for all requests related to item import. Supports import of
 * item's metadata in QTI/APIP XML format and mapping data to the domain tables
 * 
 * @author amiliteev
 * 
 */
@Path("/service/import")
@WebService
public class ItemImportService {

    private static final Logger LOGGER = Logger
            .getLogger(ItemImportService.class.getName());
    private static final long ITEM_MOVE_STATUS_COMPLETE = 1;
    private static final long ITEM_MOVE_STATUS_INCOMPLETE = 2;
    private static final long ITEM_MOVE_STATUS_INPROGRESS = 3;

    @EJB
    private transient MetadataServices metadataServices;

    @EJB
    private transient ItemServices itemServices;

    @EJB
    private transient ContentMoveServices contentMoveServices;

    @EJB
    private transient SAAIFPackageReader saaifPackageReader;

    @EJB
    private transient IMSPackageReader imsPackageReader;

    @EJB
    private transient IMSValidator imsValidator;

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
     * This method imports APIP/QTI metadata for the item with given ID; First,
     * the entire XML persisted in i_metadata_xml field of 'item' table Second,
     * mapping of the values is performed according to rules in metadata_mapping
     * table; fields in item table may be populated and entries in
     * item_characterization table may be made
     * 
     * 
     * @param itemId
     *            Item ID (i_id) for the item (injected from url path). Item for
     *            which metadata imported must exist
     * @param xml
     *            XML bean of LomResourceType containing metadata for the item
     * @param request
     *            Injected HTTP Servlet Request
     * @return
     * @throws IOException
     */
    @POST
    @Path("itemMetadata/{item}")
    @Consumes(MediaType.APPLICATION_XML)
    public Response itemMetadata(final @PathParam("item") long itemId,
            final String xmlString, @Context HttpServletRequest request) {
        LOGGER.info("/service/import/itemMetadata");
        LOGGER.info("item id: " + itemId);
        try {

            LOGGER.info(xmlString);

            itemServices.updateItemField(itemId, "i_metadata_xml", xmlString);

            // Application-scoped managed bean can be found in the attribute map
            // of servlet context
            CacheManager cache = (CacheManager) request.getServletContext()
                    .getAttribute(
                            CacheManager.class.getAnnotation(ManagedBean.class)
                                    .name());

            mapLomResourceType(itemId, xmlString, cache);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to import item metadata " + e.getMessage(), e);
            // TODO more sophisticated error handling to follow in next user
            // stories
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(e.toString()).build();

        }
        return Response.ok().build();
    }

    /**
     * This method performs mapping of the data in XML bean (LomResourceType) to
     * fields in 'item' table and entries in 'item_characterization' table
     * Mapping data is retrieved from 'metadata_mapping' table; mapping
     * specifies path to the source data in XML Bean object (using JXPath) and
     * corresponding target data elements where data should be placed. Mapping
     * also may require looking up values in lookup tables. LookupCache object
     * is used to perform lookup
     * 
     * @param itemId
     *            Id of the item for which mapping is performed
     * @param lom
     *            XML bean of LomResourceType
     * @param cache
     *            CacheManager instance to access LookupCache
     * @throws IOException
     * @throws SAXException
     * @throws ParserConfigurationException
     * @throws XPathExpressionException
     */
    private void mapLomResourceType(long itemId, String xmlString,
            CacheManager cache) throws ParserConfigurationException,
            SAXException, IOException, XPathExpressionException {
        XMLUtil parser = new XMLUtil(false);
        parser.load(xmlString);
        List<MetadataMapping> metadataMappingList = metadataServices
                .getMetadataMappingsForItems();
        for (MetadataMapping mm : metadataMappingList) {
            String valueToMap = StringUtils.join(
                    parser.getValues(mm.getxPath()), " ");
            // value not found for xpath
            if (StringUtils.isEmpty(StringUtils.trim(valueToMap))) {
                continue;
            }
            Object valueToSave = valueToMap;
            if (!StringUtils.isEmpty(mm.getLookupTableName())) {
                // looking up for the numeric code corresponding to the supplied
                // string value
                valueToSave = cache.getLookupCache().getLookupCode(
                        mm.getLookupTableName(), mm.getLookupByField(),
                        mm.getLookupPrefix(), mm.getLookupValueField(),
                        valueToMap);
                if (valueToSave == null) {
                    LOGGER.warning("Cannot determine lookup code for "
                            + mm.getxPath() + " = " + valueToMap);
                    continue;
                }
            }
            if (StringUtils.isNotEmpty(mm.getFieldName())) {
                // updating 'item' table's field
                itemServices.updateItemField(itemId, mm.getFieldName(),
                        valueToSave);
            } else if (mm.getCharacteristic() > 0) {
                // inserting record into 'item_characteristic' table; value must
                // be numeric!
                if (valueToSave instanceof Number) {
                    itemServices.upsertItemCharacterization(itemId,
                            mm.getCharacteristic(),
                            ((Number) valueToSave).intValue());
                } else {
                    LOGGER.warning("Value to save: " + valueToSave
                            + " is not numeric");
                }
            } else {
                LOGGER.warning("Invalid mapping entry: neither field nor characteristic code specified. Mapping ID: "
                        + mm.getId());
            }
        }
    }

    /**
     * This service imports the input item package
     * 
     * @param program
     * @param user
     * @param moveType
     * @param fileName
     * @param fileInputStream
     * @return
     */
    @POST
    @Path("importItmPkg")
    @Consumes(MediaType.MULTIPART_FORM_DATA)
    @Produces(MediaType.APPLICATION_JSON)
    public Response importItmPkg(final @Multipart("program") String program,
            @Multipart("user") String user,
            @Multipart("moveType") String moveType,
            @Multipart("fileName") final String fileName,
            @Multipart("file") final InputStream fileInputStream,
            @Multipart("itemPkgFormat") final String itemPkgFormat) {

        LOGGER.info("/service/import/importItmPkg");
        JSONObject jsonResponse = new JSONObject();
        try {
            LOGGER.info("Importing package :" + fileName);

            if (fileName == null || fileName.length() == 0) {
                jsonResponse.put("importStatusCode", "1");
                jsonResponse.put("importStatusMsg",
                        "No file is selected to import");
            } else if (!fileName.endsWith(".zip")) {
                jsonResponse.put("importStatusCode", "1");
                jsonResponse.put("importStatusMsg",
                        "Only zip file can be imported");
            } else {
                String source = "External File";
                String destination = "Item Authoring System";
                Timestamp timeOfMove = new Timestamp(System.currentTimeMillis());

                jsonResponse.put("importStatusCode", "0");
                jsonResponse.put("importStatusMsg",
                        "Import process has been initialized for the file: "
                                + fileName);

                String fileSeparatorLinux = "/";
                String fileSeparatorWindows = "\\";
                String modifiedFileName = fileName
                        .lastIndexOf(fileSeparatorLinux) >= 0 ? fileName
                        .substring(fileName.lastIndexOf(fileSeparatorLinux) + 1)
                        : (fileName.lastIndexOf(fileSeparatorWindows) >= 0 ? fileName
                                .substring(fileName
                                        .lastIndexOf(fileSeparatorWindows) + 1)
                                : fileName);
                final ItemMoveMonitor itemMoveMonitor = contentMoveServices
                        .insertItemMoveMonitor(Integer.parseInt(program),
                                Integer.parseInt(user),
                                Long.parseLong(moveType),
                                ITEM_MOVE_STATUS_INPROGRESS, source,
                                destination, modifiedFileName, timeOfMove,
                                itemPkgFormat);

                Thread thread = new Thread() {
                    @Override
                    public void run() {

                        final String outputZipFolder = "/www/cde_tmp/cdesbac/"
                                + fileName.substring(0,
                                        fileName.lastIndexOf("."));

                        /* Unzipping Item package */
                        saaifPackageReader.unzipPackage(fileInputStream,
                                outputZipFolder);

                        Map<String, Map<String, String>> errorMap = null;
                        Map<String, Object> values = new HashMap<String, Object>();

                        if (Integer.parseInt(itemPkgFormat) == 1) {
                            errorMap = imsValidator.validate(outputZipFolder);
                        } else {
                            /*
                             * Validate Package Structure (Existence of all
                             * resources and validation against proper XSD)
                             */
                            errorMap = saaifPackageReader
                                    .validationPackageStructure(outputZipFolder);
                        }

                        if (!errorMap
                                .containsKey(SAAIFPackageConstants.MANIFST_FILE_NAME)) {

                            if (Integer.parseInt(itemPkgFormat) == 1) {
                                imsPackageReader.readPackage(outputZipFolder,
                                        Integer.parseInt(program),
                                        itemMoveMonitor, errorMap);
                            } else {
                                saaifPackageReader.readPackage(outputZipFolder,
                                        Integer.parseInt(program),
                                        itemMoveMonitor, errorMap);
                            }
                            values.put("itemMoveStatus",
                                    ITEM_MOVE_STATUS_COMPLETE);
                        } else {
                            values.put("itemMoveStatus",
                                    ITEM_MOVE_STATUS_INCOMPLETE);

                            Map<String, String> subErrorList = errorMap
                                    .get(SAAIFPackageConstants.MANIFST_FILE_NAME);

                            List<ItemDetailStatus> itemDetailStatuslist = new ArrayList<ItemDetailStatus>();

                            for (String value : subErrorList.keySet()) {
                                ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                                String errorId = value.split("#")[1];
                                DetailStatusType detailStatusType = contentMoveServices
                                        .findDetailStatusTypeId(Integer
                                                .valueOf(errorId));
                                itemDetailStatus.setStatusDetail(subErrorList
                                        .get(value));
                                itemDetailStatus
                                        .setDetailStatusType(detailStatusType);

                                itemDetailStatuslist.add(itemDetailStatus);
                            }

                            String externalId = "";

                            String imdExternalId = SAAIFPackageConstants.MANIFST_FILE_NAME;
                            contentMoveServices.insertItemMoveDetails(
                                    externalId, itemMoveMonitor, null,
                                    itemDetailStatuslist, imdExternalId);
                        }

                        contentMoveServices.updateItemMonitor(itemMoveMonitor,
                                values);

                        File unzippedFolder = new File(outputZipFolder);
                        if (unzippedFolder.exists()) {
                            FileUtils.deleteQuietly(unzippedFolder);
                        }

                        LOGGER.info("End of Importing package :" + fileName);
                    }
                };
                thread.start();
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to import item package " + e.getMessage(), e);
            // TODO more sophisticated error handling to follow in next user
            // stories
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(e.toString()).build();
        }

        return Response.ok(jsonResponse.toString()).build();
    }

    /**
     * This service roll back the input item package
     * 
     * @param itemMessageId
     * @param packageName
     * @return
     * @throws org.codehaus.jettison.json.JSONException
     */
    @GET
    @Path("rollbackItmPkg/{id}/{name}")
    @Produces(MediaType.APPLICATION_JSON)
    public Response rollbackItmPkg(@PathParam("id") String id,
            @PathParam("name") String name) throws JSONException {

        JSONObject jsonObject = new JSONObject();

        String msg = "";
        try {
            msg = contentMoveServices.deleteItemMove(id);
            jsonObject.put("rollbackStatusMsg", msg + name);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, e.getMessage(), e);
            jsonObject.put("rollbackStatusMsg", msg);
        }

        return Response.ok(jsonObject.toString()).build();
    }

}
