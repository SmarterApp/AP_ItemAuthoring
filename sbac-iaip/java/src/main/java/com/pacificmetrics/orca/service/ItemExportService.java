/**
 * 
 */
package com.pacificmetrics.orca.service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.ejb.EJB;
import javax.jws.WebService;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;
import javax.ws.rs.Consumes;
import javax.ws.rs.FormParam;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.QueryParam;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.cxf.jaxrs.ext.multipart.Multipart;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.ResponseHandler;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.mime.MultipartEntity;
import org.apache.http.entity.mime.content.FileBody;
import org.apache.http.entity.mime.content.StringBody;
import org.apache.http.impl.client.BasicResponseHandler;
import org.apache.http.impl.client.DefaultHttpClient;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;
import org.xml.sax.SAXException;
import org.xml.sax.SAXParseException;

import com.jcraft.jsch.Channel;
import com.jcraft.jsch.ChannelSftp;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.JSchException;
import com.jcraft.jsch.Session;
import com.jcraft.jsch.SftpException;
import com.pacificmetrics.common.ItemNotFoundException;
import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.export.apip.APIPItemExporter;
import com.pacificmetrics.orca.export.apip.APIPItemParser;
import com.pacificmetrics.orca.export.apip.APIPManifestWriter;
import com.pacificmetrics.orca.export.ims.IMSItemExporter;
import com.pacificmetrics.orca.export.saaif.SAAIFItemExporter;
import com.pacificmetrics.orca.tib.SSOClient;
import com.pacificmetrics.orca.tib.TIBClient;
import com.pacificmetrics.orca.tib.TIBResponse;
import com.pacificmetrics.orca.utils.CertUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.UniformInterfaceException;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.multipart.FormDataMultiPart;
import com.sun.jersey.multipart.file.StreamDataBodyPart;

/**
 * Problems: FIXIT Item id is only an integer Imported QTI XML is truncated No
 * title from the original zip file is preserved Had to move from TOMEE too
 * light to TOMEE jax-rs Exposed services to allow export of items in an APIP
 * compliant package. Class currently pulls from a predefined package.
 * 
 * @author maumock
 * 
 */
@Path("/service/export")
@SuppressWarnings("static-method")
@WebService
public class ItemExportService {

    private static final Logger LOGGER = Logger
            .getLogger(ItemExportService.class.getName());

    private static final long ITEM_MOVE_EXPORT = 2;
    private static final long ITEM_MOVE_STATUS_COMPLETE = 1;
    private static final long ITEM_MOVE_STATUS_INCOMPLETE = 2;
    private static final long ITEM_MOVE_STATUS_INPROGRESS = 3;

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager em;

    @EJB
    private ItemServices itemService;

    @EJB
    private SAAIFItemExporter saaifItemExporter;

    @EJB
    private IMSItemExporter imsItemExporter;

    @EJB
    private ContentMoveServices contentMoveService;

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

    @GET
    @Path("tibItemStatus")
    public String getTestItemBankItemStatus(
            @QueryParam("STATUS_URL") String statusUrl) {
        final String tibBaseUrl = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);

        Client client = Client.create(CertUtil.getAllTrustingClientConfig());
        WebResource webResource = client.resource(tibBaseUrl + statusUrl);
        return webResource.get(String.class);
    }

    @POST
    @Path("packageZip")
    @Consumes("multipart/form-data")
    @Produces("application/zip")
    public Response pkgZip(final @Multipart("content") String title) {
        return null;
    }

    @POST
    @Path("packageSrcCSV")
    @Consumes("multipart/form-data")
    @Produces("application/zip")
    public Response pkgCSV(final @Multipart("content") String title) {
        final Set<Long> items;
        final List<Item> itemData;

        final String remoteContentBase = ServerConfiguration
                .getProperty(ServerConfiguration.PASSAGES_DIRECTORY)
                + '/'
                + ServerConfiguration
                        .getProperty(ServerConfiguration.APPLICATION_NAME)
                + '/';

        try {
            // Validation
            LOGGER.info("Cleaning input data.");
            items = getItemList(title);

            LOGGER.info("Accessing all items requested and verifying they exist in the database.");
            itemData = chkItemsExist(items);

            // setup
            LOGGER.info("Setup and initialization of item exporter");
            File tmpDir = new File(System.getProperty("java.io.tmpdir") + '/'
                    + UUID.randomUUID().toString());
            tmpDir.mkdirs();

            APIPItemExporter ex = new APIPItemExporter();
            ex.setBaseDir(tmpDir);
            ex.setRemoteContentBase(new File(remoteContentBase));
            ex.setManifestWriter(new APIPManifestWriter());
            ex.setItemParser(new APIPItemParser(true));
            ex.addDefaultManifestMetadata("0", "description", "packageName");
            ex.initialize();

            // process
            LOGGER.info("Creating package");
            InputStream is = ex.export(itemData);
            ex.destroy();

            // finished
            LOGGER.info("Returning zip stream to user");
            return Response
                    .ok(is)
                    .header("content-disposition",
                            "attachment; filename = pkg.zip").build();
        } catch (SAXException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;

            Throwable rootCause = e;

            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            LOGGER.info("Root cause:" + rootCause.getClass().getSimpleName());

            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException) rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(e.getMessage()).build();
            }

            throw new WebApplicationException(errorResponse);
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (NumberFormatException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity("Errors in input data.").build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemNotFoundException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final StringBuilder buf = new StringBuilder();
            buf.append("Errors in input data - following requested items were not found:");
            for (Long i : e.getMissingItems()) {
                buf.append(" " + i);
            }
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(buf.toString()).build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemExportException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;

            Throwable rootCause = e;

            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            LOGGER.info("Root cause:" + rootCause.getClass().getSimpleName());

            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException) rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(e.getMessage()).build();
            }
            throw new WebApplicationException(errorResponse);
        }
    }

    @POST
    @Path("items/tib")
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    @Produces(MediaType.APPLICATION_JSON)
    public Response exportsItemsToTestItemBank(
            @QueryParam("itemIds") final String itemIds,
            @QueryParam("itemBankId") final Integer itemBankId,
            @QueryParam("userId") final Integer userId,
            @QueryParam("packageType") final Integer packageType,
            @QueryParam("publicationStatus") final Integer publicationStatus,
            @QueryParam("itemPkgFormat") final String itemPkgFormat) {
        JSONObject jsonResponse = new JSONObject();
        try {
            LOGGER.info("Requested Item Ids: " + itemIds + " Item Bank Id: "
                    + itemBankId);
            // TODO : add validation of input parameters
            List<String> requestedItemIdList = Arrays
                    .asList(itemIds.split(","));

            LOGGER.info("Requsted item ids : " + requestedItemIdList.size());

            final List<Item> bankedItems = itemService
                    .findBankedItemsByExternalIds(requestedItemIdList,
                            itemBankId, publicationStatus);

            if (CollectionUtils.isNotEmpty(bankedItems)) {
                LOGGER.info("Number of Banked Items: " + bankedItems.size());

                Timestamp timeOfMove = new Timestamp(System.currentTimeMillis());
                final StringBuilder fileName = new StringBuilder(
                        packageType == 2 ? "SBAIF" : "IMS" + "_Items-");
                fileName.append(itemBankId != null ? itemBankId + "-" : "")
                        .append(String.format(
                                "%1$tY%1$tm%1$te%1$tH%1$tM%1$tS.zip",
                                new Date()));

                final ItemMoveMonitor itemMoveMonitor = contentMoveService
                        .insertItemMoveMonitor(itemBankId, // program id
                                userId, // user id
                                ITEM_MOVE_EXPORT, // export by default
                                ITEM_MOVE_STATUS_INPROGRESS, // In Progress by
                                                             // default
                                "Item Authoring System", // source "SBAC-IAIP"
                                "Test Item Bank", // destination
                                fileName.toString(), // file name format e.g
                                                     // SBAIF_Items-<BankId>-<YYYYDDMMHHmmSS>.zip
                                timeOfMove, itemPkgFormat); // time of move
                                                            // timestamp
                Thread thread = new Thread() {
                    @Override
                    public void run() {
                        exportItemInThread(itemMoveMonitor, packageType,
                                bankedItems, fileName);
                    }
                };

                thread.start();

                jsonResponse.put("exportStatusCode", "0");
                jsonResponse.put("exportFileName", fileName);
                jsonResponse.put("exportStatusMsg",
                        "Export process has been initialized for the file: "
                                + fileName);
            } else {
                jsonResponse.put("exportStatusCode", "-1");
                jsonResponse.put("exportStatusMsg",
                        "Selected items are not in banked state.");
            }
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to export items " + e.getMessage(), e);
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity(e.toString()).build();
        }
        return Response.ok(jsonResponse.toString()).build();
    }

    public void exportItemInThread(final ItemMoveMonitor itemMoveMonitor,
            int packageType, List<Item> bankedItems, StringBuilder fileName) {
        try {
            if (itemMoveMonitor != null) {

                File baseDir = new File(System.getProperty("java.io.tmpdir")
                        + '/' + UUID.randomUUID().toString());
                baseDir.mkdirs();

                InputStream is = null;

                if (packageType == 2) {
                    is = saaifItemExporter.export(baseDir, bankedItems,
                            fileName.toString(), itemMoveMonitor);
                } else if (packageType == 1) {
                    is = imsItemExporter.export(baseDir, bankedItems,
                            fileName.toString(), itemMoveMonitor);
                }
                LOGGER.info("Uploading file " + fileName + " to TIB FTP folder");
                TIBClient.ftpPackage(is, fileName.toString());
                LOGGER.info("Uploaded file " + fileName + " to TIB FTP folder");
                String token = SSOClient.fetchOAUTHToken();
                LOGGER.info("Token " + token);
                final String callbackURL = TIBClient.callSFTPFileUpload(token,
                        fileName.toString());
                if (StringUtils.isNotEmpty(callbackURL)) {
                    Timer uploadCheckerTimer = new Timer(true);
                    uploadCheckerTimer.scheduleAtFixedRate(new TimerTask() {
                        @Override
                        public void run() {
                            if (uploadCheckerTimer(callbackURL, itemMoveMonitor)) {
                                cancel();
                            }
                        }
                    }, 0, 60 * 1000);
                } else {
                    LOGGER.info("No proper response received from TIB");
                    List<ItemDetailStatus> itemDetailStatuslist = new ArrayList<ItemDetailStatus>();
                    ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                    DetailStatusType detailStatusType = contentMoveService
                            .findDetailStatusTypeId(8);
                    itemDetailStatus
                            .setStatusDetail("Unable to export item(s) to Test Item Bank");
                    itemDetailStatus.setDetailStatusType(detailStatusType);

                    itemDetailStatuslist.add(itemDetailStatus);
                    contentMoveService.insertItemMoveDetails("",
                            itemMoveMonitor, null, itemDetailStatuslist, "");
                    Map<String, Object> values = new HashMap<String, Object>();
                    values.put("itemMoveStatus", ITEM_MOVE_STATUS_INCOMPLETE);
                    contentMoveService.updateItemMonitor(itemMoveMonitor,
                            values);
                }

            } else {
                final Response errorResponse = Response
                        .status(Status.BAD_REQUEST)
                        .entity("Unable to Export to Test Item Bank").build();
                throw new WebApplicationException(errorResponse);
            }
        } catch (ItemExportException e) {
            LOGGER.log(Level.SEVERE, "Unable to export to Test Item Bank" + e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Unable to export to Test Item Bank" + e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }
    }

    public boolean uploadCheckerTimer(String callbackURL,
            ItemMoveMonitor itemMoveMonitor) {
        boolean flag = false;
        String token;
        try {
            token = SSOClient.fetchOAUTHToken();
            TIBResponse response = TIBClient.callImportSet(token, callbackURL);
            if (response != null
                    && "IMPORT_COMPLETE".equals(response.getImportStatus())) {
                Map<String, Object> values = new HashMap<String, Object>();
                values.put("itemMoveStatus", ITEM_MOVE_STATUS_COMPLETE);
                List<ItemDetailStatus> itemDetailStatuslist = new ArrayList<ItemDetailStatus>();
                if ("FAILED".equalsIgnoreCase(response.getFileImportStatus())) {
                    LOGGER.info("TIB failed in bank the exported file");
                    ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                    DetailStatusType detailStatusType = contentMoveService
                            .findDetailStatusTypeId(9);
                    itemDetailStatus
                            .setStatusDetail("Unable to export item(s) to Test Item Bank "
                                    + response.getMessage());
                    itemDetailStatus.setDetailStatusType(detailStatusType);

                    itemDetailStatuslist.add(itemDetailStatus);
                } else {
                    LOGGER.info("TIB successfully banked the exported file");
                    ItemDetailStatus itemDetailStatus = new ItemDetailStatus();
                    DetailStatusType detailStatusType = contentMoveService
                            .findDetailStatusTypeId(8);
                    itemDetailStatus
                            .setStatusDetail("Item(s) successfully exported to Test Item Bank");
                    itemDetailStatus.setDetailStatusType(detailStatusType);

                    itemDetailStatuslist.add(itemDetailStatus);
                }
                contentMoveService.insertItemMoveDetails("", itemMoveMonitor,
                        null, itemDetailStatuslist, "");
                contentMoveService.updateItemMonitor(itemMoveMonitor, values);
                flag = true;

            }
        } catch (Exception e) {
            flag = true;
            LOGGER.log(
                    Level.SEVERE,
                    "Error update Item move monitor status for TIB export "
                            + e.getMessage() + "\n" + e);
        }

        return flag;
    }

    @POST
    @Path("items")
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    @Produces("application/zip")
    public Response exportItemPkg(@QueryParam("itemIds") String itemIds,
            @QueryParam("itemBankId") Integer itemBankId,
            @QueryParam("userId") Integer userId,
            @QueryParam("packageType") Integer packageType,
            @QueryParam("destinationType") String destinationType,
            @QueryParam("publicationStatus") Integer publicationStatus,
            @QueryParam("itemPkgFormat") String itemPkgFormat) {

        LOGGER.info("Requested Item Ids: " + itemIds + " Item Bank Id: "
                + itemBankId);
        // TODO : add validation of input parameters
        List<String> requestedItemIdList = Arrays.asList(itemIds.split(","));

        LOGGER.info("Requsted item ids : " + requestedItemIdList.size());

        final List<Item> bankedItems = itemService
                .findBankedItemsByExternalIds(requestedItemIdList, itemBankId,
                        publicationStatus);

        if (CollectionUtils.isNotEmpty(bankedItems)) {
            LOGGER.info("Number of Banked Items: " + bankedItems.size());

            Timestamp timeOfMove = new Timestamp(System.currentTimeMillis());
            // TODO : add default source
            // Default file name pattern
            // SBAIF_Items-<ItemBankId>-<YYYYMMDDHHmmSS>.zip
            // IMS_Items-<ItemBankId>-<YYYYMMDDHHmmSS>.zip
            StringBuilder fileName = new StringBuilder(
                    packageType == 2 ? "SBAIF" : "IMS" + "_Items-");
            fileName.append(itemBankId != null ? itemBankId + "-" : "").append(
                    String.format("%1$tY%1$tm%1$te%1$tH%1$tM%1$tS.zip",
                            new Date()));

            ItemMoveMonitor itemMoveMonitor = contentMoveService
                    .insertItemMoveMonitor(itemBankId, // program id
                            userId, // user id
                            ITEM_MOVE_EXPORT, // export by default
                            ITEM_MOVE_STATUS_INPROGRESS, // In Progress by
                                                         // default
                            null, // source "SBAC-IAIP"
                            destinationType, // destination
                            fileName.toString(), // file name format e.g
                                                 // SBAIF_Items-<BankId>-<YYYYDDMMHHmmSS>.zip
                            timeOfMove, itemPkgFormat); // time of move
                                                        // timestamp
            try {
                if (itemMoveMonitor != null) {

                    // TODO : Add validation
                    File baseDir = new File(
                            System.getProperty("java.io.tmpdir") + '/'
                                    + UUID.randomUUID().toString());
                    baseDir.mkdirs();

                    InputStream is = null;

                    if (packageType == 2) {
                        is = saaifItemExporter.export(baseDir, bankedItems,
                                fileName.toString(), itemMoveMonitor);
                    } else if (packageType == 1) {
                        is = imsItemExporter.export(baseDir, bankedItems,
                                fileName.toString(), itemMoveMonitor);
                    }

                    // Update Item move monitor status to complete
                    Map<String, Object> values = new HashMap<String, Object>();
                    values.put("itemMoveStatus", 1);
                    contentMoveService.updateItemMonitor(itemMoveMonitor,
                            values);
                    // TODO : add Item status .

                    // finished
                    LOGGER.info("Returning zip stream to user");
                    return Response
                            .ok(is)
                            .header("content-disposition",
                                    "attachment; filename ="
                                            + fileName.toString()).build();
                } else {
                    final Response errorResponse = Response
                            .status(Status.BAD_REQUEST)
                            .entity("Unable to create Item Move Monitor")
                            .build();
                    throw new WebApplicationException(errorResponse);
                }
            } catch (ItemExportException e) {
                LOGGER.log(Level.SEVERE, "Unable to create the json response "
                        + e);
                final Response errorResponse = Response
                        .status(Status.BAD_REQUEST).entity(e.getMessage())
                        .build();
                throw new WebApplicationException(errorResponse);
            } catch (Exception e) {
                LOGGER.log(Level.SEVERE, "Unable to create the json response "
                        + e);
                final Response errorResponse = Response
                        .status(Status.BAD_REQUEST).entity(e.getMessage())
                        .build();
                throw new WebApplicationException(errorResponse);
            }
        } else {
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity("Unable to find any Banked Items").build();
            throw new WebApplicationException(errorResponse);
        }
    }

    @POST
    @Path("testItemBank")
    @Consumes("multipart/form-data")
    @Produces("application/json")
    public Response exportPkgToTestItemBank(
            final @Multipart("content") String itemIds) {
        // 1. process requested items:
        // a. validate requested items exist
        // * b. validate user has permissions to requested items
        // for items not available to user -> add warning to results and log
        // may not be possible to ascertain since web service is executed as
        // ws-user and not as user
        // c. validate items in banked (60) development state.
        // * for items not banked -> add info to results

        LOGGER.info("Requested Item Ids: " + itemIds);

        List<String> requestedItemIdList = Arrays.asList(itemIds
                .split("\\r?\\n"));

        LOGGER.info("Number of Requested Items: " + requestedItemIdList.size());
        final Query itemQuery = this.em
                .createQuery("SELECT i FROM Item i JOIN i.devState ds "
                        + "WHERE ds.name = 'Banked' "
                        + "AND i.version = (SELECT max(ii.version) FROM Item ii WHERE ii.externalId=i.externalId) "
                        + "AND i.id IN :requestedIds");

        itemQuery.setParameter("requestedIds", requestedItemIdList);

        @SuppressWarnings("unchecked")
        final List<Item> bankedItems = itemQuery.getResultList();
        LOGGER.info("Number of Banked Items: " + bankedItems.size());

        final List<Item> unbankedItems = new ArrayList<Item>();
        final List<Item> oldVersionItems = new ArrayList<Item>();

        // * check if items already exist in TIB

        if (requestedItemIdList.size() != bankedItems.size()) {
            // track which items aren't banked, wrong program, or are not max
            // version
            List<String> missingItemIdList = new ArrayList<String>();
            missingItemIdList.addAll(requestedItemIdList);

            // remove items found
            for (Item bankedItem : bankedItems) {
                missingItemIdList.remove(String.valueOf(bankedItem.getId()));
            }

            // search for missing items
            Query q = this.em
                    .createQuery("SELECT i FROM Item i WHERE i.id IN :missingIds");
            q.setParameter("missingIds", missingItemIdList);
            @SuppressWarnings("unchecked")
            final List<Item> missingItems = q.getResultList();
            LOGGER.info("Number of missing items: " + missingItems.size());
            // try to determine why item was excluded
            for (Item missingItem : missingItems) {
                // FIXME could be both
                if (!"Banked".equalsIgnoreCase(missingItem.getDevState()
                        .getName())) {
                    unbankedItems.add(missingItem);
                } else {
                    // FIXME query will only select items that were in query
                    // (that means if someone did not select max version item as
                    // well than wouldn't know without yet another query)

                    // XXX based on query can assume that if banked than it's an
                    // old item
                    oldVersionItems.add(missingItem);
                }
            }
            LOGGER.info("Number of unbanked items: " + unbankedItems.size());
            LOGGER.info("Number of old items: " + oldVersionItems.size());
        }

        if (bankedItems.isEmpty()) {
            JSONObject jsonResponse = new JSONObject();
            try {
                // overload response.importStatus as provided by TIB response
                // for our own purposes
                jsonResponse.put("importStatus", "NO_ITEMS_FOUND");

                Map<String, String> exportNotes = new HashMap<String, String>();
                // add information
                if (!unbankedItems.isEmpty()) {
                    String externalIds = "";
                    for (Item unbankedItem : unbankedItems) {
                        externalIds += unbankedItem.getExternalId() + ", ";
                    }
                    externalIds = externalIds.substring(0,
                            externalIds.length() - 2);
                    exportNotes.put("unbankedItems", externalIds);
                }

                if (!oldVersionItems.isEmpty()) {
                    String externalIds = "";
                    for (Item oldVersionItem : oldVersionItems) {
                        externalIds += oldVersionItem.getExternalId() + ", ";
                    }
                    externalIds = externalIds.substring(0,
                            externalIds.length() - 2);
                    exportNotes.put("oldItems", externalIds);
                }

                // add export notes so user can understand what's goin' on
                jsonResponse.put("exportNotes", exportNotes);
            } catch (JSONException e) {
                LOGGER.log(Level.INFO, e.getMessage(), e);
            }
            return Response.ok(jsonResponse.toString()).build();
        }

        // 2. create export package
        final String serverUrl = ServerConfiguration
                .getProperty(ServerConfiguration.HTTP_SERVER_URL);

        // reconstruct form field for requested {banked} items
        final StringBuilder sb = new StringBuilder();
        for (Item item : bankedItems) {
            sb.append(item.getId()).append("\r\n");
        }

        final String content = sb.toString();

        // remaining banked items -> send to packageSrcCSV service
        Client client = Client.create(CertUtil.getAllTrustingClientConfig());
        FormDataMultiPart form = new FormDataMultiPart().field("content",
                content);

        WebResource webResource = client.resource(serverUrl
                + "/orca-sbac/service/export/packageSrcCSV");

        InputStream inputStream = null;

        // * capture response / errors and log/add to own response
        try {
            inputStream = webResource.accept("application/zip")
                    .type(MediaType.MULTIPART_FORM_DATA_TYPE)
                    .post(InputStream.class, form);
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not generate export: "
                            + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity("Could not generate export: " + e.getMessage())
                    .build();
            throw new WebApplicationException(errorResponse);
        }

        // 3. call test item bank (TIB) service
        final String tibBaseUrl = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);

        // use resulting zip file -> pass to the test item bank
        // * consider should zip be in memory?? could lead to OOME.
        FormDataMultiPart testItemBankUpload = new FormDataMultiPart();
        testItemBankUpload
                .bodyPart(new StreamDataBodyPart("file", inputStream));
        WebResource testItemBank = client.resource(tibBaseUrl + "/uploadFile");
        ClientResponse response = null;

        // process results from test item bank
        try {
            response = testItemBank.accept(MediaType.APPLICATION_JSON_TYPE)
                    .type(MediaType.MULTIPART_FORM_DATA_TYPE)
                    .post(ClientResponse.class, testItemBankUpload);
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Test item bank rejected export: "
                            + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Test item bank rejected export: " + e.getMessage())
                    .build();
            throw new WebApplicationException(errorResponse);
        }

        // log status code
        int tibStatus = response.getStatus();
        LOGGER.info("TIB Status: " + tibStatus);

        // copy the entity
        String entity = response.getEntity(String.class);
        LOGGER.info("TIB Data: " + entity);

        JSONObject jsonResponse = new JSONObject();

        try {
            jsonResponse = new JSONObject(entity);

            Map<String, String> exportNotes = new HashMap<String, String>();

            if (!unbankedItems.isEmpty()) {
                String externalIds = "";
                for (Item unbankedItem : unbankedItems) {
                    externalIds += unbankedItem.getExternalId() + ", ";
                }
                externalIds = externalIds
                        .substring(0, externalIds.length() - 2);
                exportNotes.put("unbankedItems", externalIds);
            }

            if (!oldVersionItems.isEmpty()) {
                String externalIds = "";
                for (Item oldVersionItem : oldVersionItems) {
                    externalIds += oldVersionItem.getExternalId() + ", ";
                }
                externalIds = externalIds
                        .substring(0, externalIds.length() - 2);
                exportNotes.put("oldItems", externalIds);
            }

            jsonResponse.put("exportNotes", exportNotes);
        } catch (JSONException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        }

        // * consider whether want to couple client with AIR data structure...

        // * insert export response

        // return the response
        return Response.ok(jsonResponse.toString()).build();
    }

    @POST
    @Path("testItemBankAll")
    @Produces("application/json")
    public Response exportAllPkgToTestItemBank(
            @FormParam("PROGRAM_ID") final String itemBankId) {
        // * consider spawning separate thread, so this request doesn't get
        // blocked...
        // can update a table which user can monitor from the ui

        // * consider ws authn and encryption for sftp information

        // 1. get list of all banked items (in item bank)

        // * consider how best to limit items to users
        // organization/program/workgroup
        // could be a ui restriction at minimum

        // export banked items, with maximum version, for the selected program
        final Query bankedItemQuery = this.em
                .createQuery("SELECT i FROM Item i JOIN i.devState ds "
                        + "WHERE ds.name = 'Banked' "
                        + "AND i.itemBankId = "
                        + itemBankId
                        + " "
                        + "AND i.version = (SELECT max(ii.version) FROM Item ii WHERE ii.externalId=i.externalId)");

        // Verify all items exist
        @SuppressWarnings("unchecked")
        final List<Item> bankedItems = bankedItemQuery.getResultList();

        LOGGER.info("Number of Banked Items: " + bankedItems.size());

        // * check if items already exist in TIB

        if (bankedItems.isEmpty()) {
            JSONObject jsonResponse = new JSONObject();
            // * change to exportStatus and change UI
            try {
                jsonResponse.put("importStatus", "NO_ITEMS_FOUND");
            } catch (JSONException e) {
                LOGGER.log(Level.INFO, e.getMessage(), e);
            }
            return Response.ok(jsonResponse.toString()).build();
        }

        final StringBuilder sb = new StringBuilder();
        for (Item item : bankedItems) {
            sb.append(item.getId()).append("\r\n");
        }

        final String content = sb.toString();

        // 2. create export package
        final String serverUrl = ServerConfiguration
                .getProperty(ServerConfiguration.HTTP_SERVER_URL);

        FormDataMultiPart form = new FormDataMultiPart().field("content",
                content);
        Client client = Client.create(CertUtil.getAllTrustingClientConfig());
        WebResource webResource = client.resource(serverUrl
                + "/orca-sbac/service/export/packageSrcCSV");

        InputStream inputStream = null;

        try {
            inputStream = webResource.accept("application/zip")
                    .type(MediaType.MULTIPART_FORM_DATA_TYPE)
                    .post(InputStream.class, form);
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not generate export: "
                            + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity("Could not generate export: " + e.getMessage())
                    .build();
            throw new WebApplicationException(errorResponse);
        }

        // * capture response / errors and log/add to own response

        // 3. sftp to predetermined location
        final String exportFileName = Calendar.getInstance().getTimeInMillis()
                + ".zip";
        LOGGER.info("Export File Name: " + exportFileName);

        final String tibSftpHost = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SFTP_HOST);
        final String tibSftpUsr = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SFTP_USER);
        final String tibSftpPass = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SFTP_PASSWD);

        try {
            JSch jsch = new JSch();
            Session session = null;
            session = jsch.getSession(tibSftpUsr, tibSftpHost);
            session.setConfig("StrictHostKeyChecking", "no");
            session.setPassword(tibSftpPass);
            session.connect();
            Channel channel = session.openChannel("sftp");
            channel.connect();
            ChannelSftp sftpChannel = (ChannelSftp) channel;
            sftpChannel.put(inputStream, exportFileName);
            sftpChannel.exit();
            session.disconnect();
        } catch (JSchException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not connect to Test item bank: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (SftpException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not connect to Test item bank: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }
        // * check/log status of sftp and add to own resonse

        // 4. call test item bank (TIB) service
        final String tibBaseUrl = ServerConfiguration
                .getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);

        final String sftpFileImportJSON = "{\"importFiles\":[{\"pathName\":\""
                + exportFileName + "\"}]}";
        WebResource testItemBank = client.resource(tibBaseUrl
                + "/sftpFileImport");
        ClientResponse response = null;

        try {
            response = testItemBank.type(MediaType.APPLICATION_JSON_TYPE)
                    .accept(MediaType.APPLICATION_JSON_TYPE)
                    .post(ClientResponse.class, sftpFileImportJSON);
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Test item bank rejected export: "
                            + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Test item bank rejected export: " + e.getMessage())
                    .build();
            throw new WebApplicationException(errorResponse);
        }

        int tibStatus = response.getStatus();
        LOGGER.info("TIB Status: " + tibStatus);

        String entity = response.getEntity(String.class);
        LOGGER.info("TIB Data: " + entity);

        // * insert export response

        return Response.ok(entity).build();
    }

    @POST
    @Path("validatePkgCSV")
    @Consumes("multipart/form-data")
    @Produces("text/plain")
    public String validatePkgCSV(final @Multipart("content") String title) {
        final Set<Long> items;
        final List<Item> itemData;
        final String remoteContentBase = ServerConfiguration
                .getProperty(ServerConfiguration.PASSAGES_DIRECTORY)
                + '/'
                + ServerConfiguration
                        .getProperty(ServerConfiguration.APPLICATION_NAME)
                + '/';

        APIPItemExporter ex = null;

        try {
            // Validation
            LOGGER.info("Cleaning input data.");
            items = getItemList(title);

            LOGGER.info("Accessing all items requested and verifying they exist in the database.");
            itemData = chkItemsExist(items);

            // setup
            LOGGER.info("Setup and initialization of item exporter");
            File tmpDir = new File(System.getProperty("java.io.tmpdir") + '/'
                    + UUID.randomUUID().toString());
            tmpDir.mkdirs();

            ex = new APIPItemExporter();
            ex.setBaseDir(tmpDir);
            ex.setRemoteContentBase(new File(remoteContentBase));
            ex.setManifestWriter(new APIPManifestWriter());
            ex.setItemParser(new APIPItemParser(true));
            ex.addDefaultManifestMetadata("0", "description", "packageName");
            ex.initialize();

            // process
            LOGGER.info("Creating package");
            InputStream is = ex.export(itemData);
            is.close();

            LOGGER.info("Validating package against IMS package validator.");
            File f = new File(ex.getBaseDir(), "dist/apip.zip");
            return validate(f);
        } catch (NumberFormatException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity("Errors in input data.").build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemNotFoundException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final StringBuilder buf = new StringBuilder();
            buf.append("Errors in input data - following requested items were not found:");
            for (Long i : e.getMissingItems()) {
                buf.append(" " + i);
            }
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(buf.toString()).build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemExportException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;

            Throwable rootCause = e;

            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            LOGGER.info("Root cause:" + rootCause.getClass().getSimpleName());

            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException) rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(e.getMessage()).build();
            }
            throw new WebApplicationException(errorResponse);
        } catch (SAXException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;

            Throwable rootCause = e;

            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            LOGGER.info("Root cause:" + rootCause.getClass().getSimpleName());

            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException) rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST)
                        .entity(e.getMessage()).build();
            }

            throw new WebApplicationException(errorResponse);
        } catch (ParserConfigurationException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (IOException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (InterruptedException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST)
                    .entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } finally {
            destroyAPIPItemExporterObject(ex);
        }
    }

    private void destroyAPIPItemExporterObject(APIPItemExporter ex) {
        // TODO Auto-generated method stub
        if (ex != null) {
            try {
                ex.destroy();
            } catch (ItemExportException e) {
                LOGGER.log(Level.INFO, e.getMessage(), e);
                final Response errorResponse = Response
                        .status(Status.BAD_REQUEST).entity(e.getMessage())
                        .build();
                throw new WebApplicationException(errorResponse);
            }
        }
    }

    /**
     * Clean the input data provided by the user
     * 
     * @param csv
     *            input data from user
     * @return cleaned data in a set to reduce duplicates
     * @throws NumberFormatException
     *             thrown if input data does not contain a valid number (i.e.,
     *             input > 65536)
     */
    private Set<Long> getItemList(String csv) throws NumberFormatException {
        final Set<Long> out = new HashSet<Long>(0);
        if (csv == null) {
            return out;
        }
        final String[] itemList = csv.split("\\r?\\n");
        for (int i = 0; i < itemList.length; i++) {
            itemList[i] = itemList[i].replaceAll("[^\\d]", "");
            if (itemList[i].length() > 0) {
                out.add(new Long(itemList[i]));
            }
        }
        return out;
    }

    /**
     * Verify all items exist in the database
     * 
     * @param want
     *            the items requested by the user
     * @throws ItemNotFoundException
     *             thrown if items are not found. Throws a list of missing
     *             items.
     */
    @SuppressWarnings("boxing")
    private List<Item> chkItemsExist(Set<Long> want)
            throws ItemNotFoundException {
        // Select all item ids
        final Query q = this.em
                .createQuery("select x from Item x where x.id in :list");
        q.setParameter("list", want);

        // Verify all items exist
        @SuppressWarnings("unchecked")
        final List<Item> items = q.getResultList();

        // If item list doesn't match the list of items wanted then throw an
        // error
        if (items.size() != want.size()) {
            List<Long> missing = new ArrayList<Long>();
            for (Item item : items) {
                if (!want.contains(item.getId())) {
                    missing.add(item.getId());
                }
            }
            throw new ItemNotFoundException(
                    "Not all items are available in the system. The following items are missing:"
                            + missing.toArray());
        }
        return items;
    }

    /**
     * Method used to upload a static APIP package from the classpath and verify
     * it through the IMS validation service.
     * 
     * @param pkg
     *            PLACE HOLDER NOT USED
     * @return Results HTML from the IMS global validator site after the package
     *         is uploaded
     * @throws ClientProtocolException
     * @throws IOException
     * @throws InterruptedException
     */
    private static String validate(File file) throws ClientProtocolException,
            IOException, InterruptedException {
        DefaultHttpClient httpclient = new DefaultHttpClient();
        httpclient
                .getParams()
                .setParameter("User-Agent",
                        "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.1.4322)");
        try {
            // Upload the package to the IMS website
            HttpPost httppost = new HttpPost(
                    "http://validator.imsglobal.org/assessment/index.jsp?validate=package");

            FileBody bin = new FileBody(file);
            StringBody comment = new StringBody("Filename: "
                    + "apipv1p0_EntryTest_VE_IP_01.zip");

            MultipartEntity reqEntity = new MultipartEntity();
            reqEntity.addPart("bin", bin);
            reqEntity.addPart("comment", comment);
            httppost.setEntity(reqEntity);

            ResponseHandler<String> responseHandler = new BasicResponseHandler();
            String responseBody = httpclient.execute(httppost, responseHandler);

            // Monitor the validator page until it returns 100% complete
            int cnt = 0;
            while (cnt < 5) {
                responseHandler = new BasicResponseHandler();
                HttpGet httpget = new HttpGet(
                        "http://validator.imsglobal.org/progress.jsp");
                responseBody = httpclient.execute(httpget, responseHandler);
                if (responseBody.contains("100%")) {
                    break;
                }
                Thread.currentThread();
                Thread.sleep(500);
            }

            // Pull the results of the package uplaod
            HttpGet httpget = new HttpGet(
                    "http://validator.imsglobal.org/results");
            responseHandler = new BasicResponseHandler();
            return httpclient.execute(httpget, responseHandler);
        } finally {
            httpclient.getConnectionManager().shutdown();
        }
    }

    public ItemServices getItemService() {
        return itemService;
    }

    public void setItemService(ItemServices itemService) {
        this.itemService = itemService;
    }
}
