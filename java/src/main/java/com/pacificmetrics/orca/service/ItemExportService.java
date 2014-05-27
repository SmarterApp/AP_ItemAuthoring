/**
 * 
 */
package com.pacificmetrics.orca.service;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;

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
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.export.ItemExportException;
import com.pacificmetrics.orca.export.apip.APIPItemExporter;
import com.pacificmetrics.orca.export.apip.APIPItemParser;
import com.pacificmetrics.orca.export.apip.APIPManifestWriter;
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
    private static final Logger log = Logger.getLogger(ItemExportService.class
            .getName());

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager em;

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
    public String getTestItemBankItemStatus(@QueryParam("STATUS_URL") String statusUrl) {
        final String tibBaseUrl = ServerConfiguration.getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);
        
        Client client = Client.create();
        WebResource webResource = client.resource(tibBaseUrl + statusUrl);
        return webResource.get(String.class);
    }

    @POST
    @Path("packageSrcCSV")
    @Consumes("multipart/form-data")
    @Produces("application/zip")
    public Response pkgCSV(final @Multipart("content") String title) {
        final Set<Long> items;
        final List<Item> itemData;
        
        final String remoteContentBase = ServerConfiguration.getProperty(ServerConfiguration.PASSAGES_DIRECTORY) + '/'
                + ServerConfiguration.getProperty(ServerConfiguration.APPLICATION_NAME) + '/';
        
        try {
            // Validation
            log.info("Cleaning input data.");
            items = getItemList(title);
            
            log.info("Accessing all items requested and verifying they exist in the database.");
            itemData = chkItemsExist(items);

            // setup
            log.info("Setup and initialization of item exporter");
            File tmpDir = new File(System.getProperty("java.io.tmpdir") + '/' + UUID.randomUUID().toString());
            tmpDir.mkdirs();
            
            APIPItemExporter ex = new APIPItemExporter();
            ex.setBaseDir(tmpDir);
            ex.setRemoteContentBase(new File(remoteContentBase));
            ex.setManifestWriter(new APIPManifestWriter());
            ex.setItemParser(new APIPItemParser(true));
            ex.addDefaultManifestMetadata("0", "description", "packageName");
            ex.initialize();

            // process
            log.info("Creating package");
            InputStream is = ex.export(itemData);
            ex.destroy();

            // finished
            log.info("Returning zip stream to user");
            return Response.ok(is).header("content-disposition", "attachment; filename = pkg.zip").build();
        } catch (SAXException e) {
            log.log(Level.INFO, e.getMessage(), e);
            
            Response errorResponse = null;
            
            Throwable rootCause = e;
            
            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            log.info("Root cause:" + rootCause.getClass().getSimpleName());
            
            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException)rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST).entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            }
            
            throw new WebApplicationException(errorResponse);
        } catch (ParserConfigurationException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (NumberFormatException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Errors in input data.").build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemNotFoundException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final StringBuilder buf = new StringBuilder();
            buf.append("Errors in input data - following requested items were not found:");
            for (Long i : e.getMissingItems()) {
                buf.append(" " + i);
            }
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(buf.toString()).build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemExportException e) {
            log.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;
            
            Throwable rootCause = e;
            
            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            log.info("Root cause:" + rootCause.getClass().getSimpleName());
            
            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException)rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST).entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            }
            throw new WebApplicationException(errorResponse);
        }
    }

    @POST
    @Path("testItemBank")
    @Consumes("multipart/form-data")
    @Produces("application/json")
    public Response exportPkgToTestItemBank(final @Multipart("content") String itemIds) {
        // 1. process requested items:
        // a. validate requested items exist
        // * b. validate user has permissions to requested items
        // for items not available to user -> add warning to results and log
        // may not be possible to ascertain since web service is executed as
        // ws-user and not as user
        // c. validate items in banked (60) development state.
        // * for items not banked -> add info to results

        log.info("Requested Item Ids: " + itemIds);

        List<String> requestedItemIdList = Arrays.asList(itemIds.split("\\r?\\n"));
        
        log.info("Number of Requested Items: " + requestedItemIdList.size());
        final Query itemQuery = 
                this.em.createQuery(
                        "SELECT i FROM Item i JOIN i.devState ds " +
                                "WHERE ds.name = 'Banked' " +
                                    "AND i.version = (SELECT max(ii.version) FROM Item ii WHERE ii.externalId=i.externalId) " +
                                    "AND i.id IN :requestedIds");
        
        itemQuery.setParameter("requestedIds", requestedItemIdList);

        @SuppressWarnings("unchecked")
        final List<Item> bankedItems = itemQuery.getResultList();
        log.info("Number of Banked Items: " + bankedItems.size());
        
        final List<Item> unbankedItems = new ArrayList<Item>();
        final List<Item> oldVersionItems = new ArrayList<Item>();

        // * check if items already exist in TIB

        if (requestedItemIdList.size() != bankedItems.size()) {
            // track which items aren't banked, wrong program, or are not max version
            List<String> missingItemIdList = new ArrayList<String>();
            missingItemIdList.addAll(requestedItemIdList);
            
            // remove items found
            for (Item bankedItem : bankedItems) {
                missingItemIdList.remove(String.valueOf(bankedItem.getId()));
            }
            
            // search for missing items
            Query q = this.em.createQuery("SELECT i FROM Item i WHERE i.id IN :missingIds");
            q.setParameter("missingIds", missingItemIdList);
            @SuppressWarnings("unchecked")
            final List<Item> missingItems = q.getResultList();
            log.info("Number of missing items: " + missingItems.size());
            // try to determine why item was excluded
            for (Item missingItem : missingItems) {
                // FIXME could be both
                if (!missingItem.getDevState().getName().equalsIgnoreCase("Banked")) {
                    unbankedItems.add(missingItem);
                } else {
                    // FIXME query will only select items that were in query 
                    // (that means if someone did not select max version item as well than wouldn't know without yet another query) 
                    /*
                    Item maxVersionItem = null;
                    
                    String missingExternalId = missingItem.getExternalId();
                    log.info("missing external id : " + missingExternalId);
                    for (Item bankedItem : bankedItems) {
                        log.info("banked external id : " + bankedItem.getExternalId());
                        if (bankedItem.getExternalId().equals(missingExternalId)) {
                            maxVersionItem = bankedItem;
                            break;
                        }
                    }
                    log.info("max version id external id " + maxVersionItem.getExternalId());
                    if (maxVersionItem != null) {
                        log.info("missing version : " + missingItem.getVersion());
                        log.info("max version : " + maxVersionItem.getVersion());
                        if (maxVersionItem.getVersion() > missingItem.getVersion()) {
                            oldVersionItems.add(missingItem);
                        }
                    }
                    */
                    // XXX based on query can assume that if banked than it's an old item 
                    oldVersionItems.add(missingItem);
                }
            }
            log.info("Number of unbanked items: " + unbankedItems.size());
            log.info("Number of old items: " + oldVersionItems.size());
        }
        
        if (bankedItems.size() == 0) {
            JSONObject jsonResponse = new JSONObject();
            try {
                // overload response.importStatus as provided by TIB response for our own purposes
                jsonResponse.put("importStatus", "NO_ITEMS_FOUND");
                
                Map<String, String> exportNotes = new HashMap<String, String>();
                // add information
                if (unbankedItems.size() > 0) {
                    String externalIds = "";
                    for (Item unbankedItem : unbankedItems) {
                        externalIds += unbankedItem.getExternalId() + ", ";
                    }
                    externalIds = externalIds.substring(0, externalIds.length()-2);
                    exportNotes.put("unbankedItems", externalIds);
                }
                
                if (oldVersionItems.size() > 0) {
                    String externalIds = "";
                    for (Item oldVersionItem : oldVersionItems) {
                        externalIds += oldVersionItem.getExternalId() + ", ";
                    }
                    externalIds = externalIds.substring(0, externalIds.length()-2);
                    exportNotes.put("oldItems", externalIds);
                }
                
                // add export notes so user can understand what's goin' on
                jsonResponse.put("exportNotes", exportNotes);
            } catch (JSONException e) {
                log.log(Level.INFO,e.getMessage(), e);
            }
            return Response.ok(jsonResponse.toString()).build();
        }

        // 2. create export package
        final String serverUrl = ServerConfiguration.getProperty(ServerConfiguration.HTTP_SERVER_URL);

        // reconstruct form field for requested {banked} items
        final StringBuilder sb = new StringBuilder();
        for (Item item : bankedItems) {
            sb.append(item.getId()).append("\r\n");
        }

        final String content = sb.toString();

        // remaining banked items -> send to packageSrcCSV service
        Client client = Client.create();
        FormDataMultiPart form = new FormDataMultiPart().field("content", content);

        WebResource webResource = client.resource(serverUrl + "/orca-sbac/service/export/packageSrcCSV");
        
        InputStream inputStream = null;
        
        // * capture response / errors and log/add to own response
        try {
            inputStream = webResource.accept("application/zip").type(MediaType.MULTIPART_FORM_DATA_TYPE)
                    .post(InputStream.class, form);
        } catch (UniformInterfaceException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not generate export: " + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not generate export: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }

        // 3. call test item bank (TIB) service
        final String tibBaseUrl = ServerConfiguration.getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);

        // use resulting zip file -> pass to the test item bank
        // * consider should zip be in memory?? could lead to OOME.
        FormDataMultiPart testItemBankUpload = new FormDataMultiPart();
        testItemBankUpload.bodyPart(new StreamDataBodyPart("file", inputStream));
        WebResource testItemBank = client.resource(tibBaseUrl + "/uploadFile");
        ClientResponse response = null;
        
        // process results from test item bank
        try {
            response = testItemBank.accept(MediaType.APPLICATION_JSON_TYPE).type(MediaType.MULTIPART_FORM_DATA_TYPE)
                .post(ClientResponse.class, testItemBankUpload);
        } catch (UniformInterfaceException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Test item bank rejected export: " + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Test item bank rejected export: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }

        // log status code
        int tibStatus = response.getStatus();
        log.info("TIB Status: " + tibStatus);

        // copy the entity
        String entity = response.getEntity(String.class);
        log.info("TIB Data: " + entity);
        
        JSONObject jsonResponse = new JSONObject();
        
        try {
            jsonResponse = new JSONObject(entity);
            
            Map<String, String> exportNotes = new HashMap<String, String>();
            
            if (unbankedItems.size() > 0) {
                String externalIds = "";
                for (Item unbankedItem : unbankedItems) {
                    externalIds += unbankedItem.getExternalId() + ", ";
                }
                externalIds = externalIds.substring(0, externalIds.length()-2);
                exportNotes.put("unbankedItems", externalIds);
            }
        
            if (oldVersionItems.size() > 0) {
                String externalIds = "";
                for (Item oldVersionItem : oldVersionItems) {
                    externalIds += oldVersionItem.getExternalId() + ", ";
                }
                externalIds = externalIds.substring(0, externalIds.length()-2);
                exportNotes.put("oldItems", externalIds);
            }
            
            jsonResponse.put("exportNotes", exportNotes);
        } catch (JSONException e) {
            log.log(Level.INFO,e.getMessage(), e);
        }

        // * consider whether want to couple client with AIR data structure...

        // * insert export response

        // return the response
        return Response.ok(jsonResponse.toString()).build();
    }

    @POST
    @Path("testItemBankAll")
    @Produces("application/json")
    public Response exportAllPkgToTestItemBank(@FormParam("PROGRAM_ID") final String ib_id) {
        // * consider spawning separate thread, so this request doesn't get
        // blocked...
        // can update a table which user can monitor from the ui

        // * consider ws authn and encryption for sftp information

        // 1. get list of all banked items (in item bank)

        // * consider how best to limit items to users
        // organization/program/workgroup
        // could be a ui restriction at minimum

        // export banked items, with maximum version, for the selected program
        final Query bankedItemQuery = 
                this.em.createQuery(
                        "SELECT i FROM Item i JOIN i.devState ds " +
                            "WHERE ds.name = 'Banked' " +
                                "AND i.itemBankId = " + ib_id + " " +
                                "AND i.version = (SELECT max(ii.version) FROM Item ii WHERE ii.externalId=i.externalId)");

        // Verify all items exist
        @SuppressWarnings("unchecked")
        final List<Item> bankedItems = bankedItemQuery.getResultList();

        log.info("Number of Banked Items: " + bankedItems.size());

        // * check if items already exist in TIB

        if (bankedItems.size() == 0) {
            JSONObject jsonResponse = new JSONObject();
            // * change to exportStatus and change UI
            try {
                jsonResponse.put("importStatus", "NO_ITEMS_FOUND");
            } catch (JSONException e) {
                log.log(Level.INFO,e.getMessage(), e);
            }
            return Response.ok(jsonResponse.toString()).build();
        }

        final StringBuilder sb = new StringBuilder();
        for (Item item : bankedItems) {
            sb.append(item.getId()).append("\r\n");
        }

        final String content = sb.toString();

        // 2. create export package
        final String serverUrl = ServerConfiguration.getProperty(ServerConfiguration.HTTP_SERVER_URL);

        FormDataMultiPart form = new FormDataMultiPart().field("content", content);
        Client client = Client.create();
        WebResource webResource = client.resource(serverUrl + "/orca-sbac/service/export/packageSrcCSV");
        
        InputStream inputStream = null;
        
        try {
            inputStream = webResource.accept("application/zip").type(MediaType.MULTIPART_FORM_DATA_TYPE)
                .post(InputStream.class, form);
        } catch (UniformInterfaceException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not generate export: " + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not generate export: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }

        // * capture response / errors and log/add to own response

        // 3. sftp to predetermined location
        final String exportFileName = Calendar.getInstance().getTimeInMillis() + ".zip";
        log.info("Export File Name: " + exportFileName);

        final String tibSftpHost = ServerConfiguration.getProperty(ServerConfiguration.TIB_SFTP_HOST);
        final String tibSftpUsr = ServerConfiguration.getProperty(ServerConfiguration.TIB_SFTP_USER);
        final String tibSftpPass = ServerConfiguration.getProperty(ServerConfiguration.TIB_SFTP_PASSWD);

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
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not connect to Test item bank: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (SftpException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Could not connect to Test item bank: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }
        // * check/log status of sftp and add to own resonse

        // 4. call test item bank (TIB) service
        final String tibBaseUrl = ServerConfiguration.getProperty(ServerConfiguration.TIB_SERVICE_BASE_URL);

        final String sftpFileImportJSON = "{\"importFiles\":[{\"pathName\":\""+ exportFileName + "\"}]}";
        WebResource testItemBank = client.resource(tibBaseUrl+ "/sftpFileImport");
        ClientResponse response = null;
        
        try {
            response = testItemBank.type(MediaType.APPLICATION_JSON_TYPE).accept(MediaType.APPLICATION_JSON_TYPE)
                .post(ClientResponse.class, sftpFileImportJSON);
        } catch (UniformInterfaceException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Test item bank rejected export: " + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Test item bank rejected export: " + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }

        int tibStatus = response.getStatus();
        log.info("TIB Status: " + tibStatus);

        String entity = response.getEntity(String.class);
        log.info("TIB Data: " + entity);

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
        final String remoteContentBase = ServerConfiguration.getProperty(ServerConfiguration.PASSAGES_DIRECTORY) + '/'
                + ServerConfiguration.getProperty(ServerConfiguration.APPLICATION_NAME) + '/';
        
        APIPItemExporter ex = null;
        
        try {
            // Validation
            log.info("Cleaning input data.");
            items = getItemList(title);
            
            log.info("Accessing all items requested and verifying they exist in the database.");
            itemData = chkItemsExist(items);

            // setup
            log.info("Setup and initialization of item exporter");
            File tmpDir = new File(System.getProperty("java.io.tmpdir") + '/' + UUID.randomUUID().toString());
            tmpDir.mkdirs();
            
            ex = new APIPItemExporter();
            ex.setBaseDir(tmpDir);
            ex.setRemoteContentBase(new File(remoteContentBase));
            ex.setManifestWriter(new APIPManifestWriter());
            ex.setItemParser(new APIPItemParser(true));
            ex.addDefaultManifestMetadata("0", "description", "packageName");
            ex.initialize();

            // process
            log.info("Creating package");
            InputStream is = ex.export(itemData);
            is.close();

            log.info("Validating package against IMS package validator.");
            File f = new File(ex.getBaseDir(), "dist/apip.zip");
            return validate(f);
        } catch (NumberFormatException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity("Errors in input data.").build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemNotFoundException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final StringBuilder buf = new StringBuilder();
            buf.append("Errors in input data - following requested items were not found:");
            for (Long i : e.getMissingItems()) {
                buf.append(" " + i);
            }
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(buf.toString()).build();
            throw new WebApplicationException(errorResponse);
        } catch (ItemExportException e) {
            log.log(Level.INFO, e.getMessage(), e);

            Response errorResponse = null;
            
            Throwable rootCause = e;
            
            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            log.info("Root cause:" + rootCause.getClass().getSimpleName());
            
            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException)rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST).entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            }
            throw new WebApplicationException(errorResponse);
        } catch (SAXException e) {
            log.log(Level.INFO, e.getMessage(), e);
            
            Response errorResponse = null;
            
            Throwable rootCause = e;
            
            while (rootCause.getCause() != null) {
                rootCause = rootCause.getCause();
            }
            log.info("Root cause:" + rootCause.getClass().getSimpleName());
            
            if (rootCause instanceof SAXParseException) {
                SAXParseException parseException = (SAXParseException)rootCause;
                errorResponse = Response.status(Status.BAD_REQUEST).entity(parseException.getMessage()).build();
            } else {
                errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            }
            
            throw new WebApplicationException(errorResponse);
        } catch (ParserConfigurationException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (IOException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (InterruptedException e) {
            log.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } finally {
            if (ex != null) {
                try {
                    ex.destroy();
                } catch (ItemExportException e) {
                    log.log(Level.INFO, e.getMessage(), e);
                    final Response errorResponse = Response.status(Status.BAD_REQUEST).entity(e.getMessage()).build();
                    throw new WebApplicationException(errorResponse);
                }
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
}
