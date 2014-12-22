package com.pacificmetrics.orca.mbeans;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Serializable;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.application.FacesMessage;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.context.ExternalContext;
import javax.faces.context.FacesContext;
import javax.net.ssl.HttpsURLConnection;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;
import javax.ws.rs.core.Response.Status;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;
import org.apache.commons.lang.StringUtils;
import org.apache.myfaces.custom.fileupload.UploadedFile;
import org.codehaus.jettison.json.JSONException;
import org.codehaus.jettison.json.JSONObject;

import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.ItemServices;
import com.pacificmetrics.orca.ejb.UserServices;
import com.pacificmetrics.orca.entities.Item;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.ItemMoveDetails;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.entities.ItemPackageFormat;
import com.pacificmetrics.orca.entities.PublicationStatus;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.utils.CertUtil;
import com.sun.jersey.api.client.Client;
import com.sun.jersey.api.client.ClientHandlerException;
import com.sun.jersey.api.client.ClientResponse;
import com.sun.jersey.api.client.UniformInterfaceException;
import com.sun.jersey.api.client.WebResource;
import com.sun.jersey.core.util.MultivaluedMapImpl;
import com.sun.jersey.multipart.FormDataBodyPart;
import com.sun.jersey.multipart.FormDataMultiPart;

@ManagedBean(name = "contentMoves")
@ViewScoped
public class ContentMovesManager extends AbstractManager implements
        Serializable {
    private static final Logger LOGGER = Logger
            .getLogger(ContentMovesManager.class.getName());

    @EJB
    private ItemServices itemServices;

    @EJB
    private transient ItemBankServices itemBankServices;

    @EJB
    private transient UserServices userServices;

    private static final long serialVersionUID = 1L;

    private List<ItemBank> itemBankList;
    private String selectedMoveoption;
    private UploadedFile uploadedFile;
    private UploadedFile searchFile;
    private Integer selectedProgram;
    private Integer selectedExportProgram;
    private String selectedOrganization;
    private String user;
    private String userName;
    private Map<String, Integer> orgNamesMap;
    //
    private String selectedDestination;
    private List<ItemPackageFormat> itemPackageFormat;
    private List<PublicationStatus> publicationStatus;
    private List<Item> searchedItems;
    private String name;
    private int pubStatus;
    private String selectedFormat;
    private String selectedImportFormat;

    private String sortColumn;
    private boolean ascending;
    private int firstRow;
    private boolean executed;
    private String popMessage = "hi";

    // sorting
    private String sortField;
    private boolean sortAscending;

    public String getSortField() {
        return sortField;
    }

    public void setSortField(String sortField) {
        this.sortField = sortField;
    }

    public boolean isSortAscending() {
        return sortAscending;
    }

    public void setSortAscending(boolean sortAscending) {
        this.sortAscending = sortAscending;
    }

    public String getPopMessage() {
        return popMessage;
    }

    public void setPopMessage(String popMessage) {
        this.popMessage = popMessage;
    }

    public boolean isExecuted() {
        return executed;
    }

    public void setExecuted(boolean executed) {
        this.executed = executed;
    }

    private Map<String, Boolean> checked = new HashMap<String, Boolean>();

    public Map<String, Boolean> getChecked() {
        return checked;
    }

    public void setChecked(Map<String, Boolean> checked) {
        this.checked = checked;
    }

    public List<Item> getSearchedItems() {
        if (CollectionUtils.isNotEmpty(searchedItems)) {
            sort();
        }
        return searchedItems;
    }

    public void setSearchedItems(List<Item> searchedItems) {
        this.searchedItems = searchedItems;
    }

    public String getSelectedDestination() {
        return selectedDestination;
    }

    public void setSelectedDestination(String selectedDestination) {
        this.selectedDestination = selectedDestination;
    }

    public String getSelectedFormat() {
        return selectedFormat;
    }

    public void setSelectedFormat(String selectedFormat) {
        this.selectedFormat = selectedFormat;
    }

    /**
     * @return the selectedImportFormat
     */
    public String getSelectedImportFormat() {
        return selectedImportFormat;
    }

    /**
     * @param selectedImportFormat
     *            the selectedImportFormat to set
     */
    public void setSelectedImportFormat(String selectedImportFormat) {
        this.selectedImportFormat = selectedImportFormat;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getPubStatus() {
        return pubStatus;
    }

    public void setPubStatus(int pubStatus) {
        this.pubStatus = pubStatus;
    }

    public String getSortColumn() {
        return sortColumn;
    }

    public void setSortColumn(String sortColumn) {
        this.sortColumn = sortColumn;
    }

    public boolean isAscending() {
        return ascending;
    }

    public void setAscending(boolean ascending) {
        this.ascending = ascending;
    }

    public int getFirstRow() {
        return firstRow;
    }

    public void setFirstRow(int firstRow) {
        this.firstRow = firstRow;
    }

    /**
     * @return the itemPackageFormat
     */
    public List<ItemPackageFormat> getItemPackageFormat() {
        return itemPackageFormat;
    }

    /**
     * @param itemPackageFormat
     *            the itemPackageFormat to set
     */
    public void setItemPackageFormat(List<ItemPackageFormat> itemPackageFormat) {
        this.itemPackageFormat = itemPackageFormat;
    }

    public Map<String, Integer> getSelectPubStatus() {
        Map<String, Integer> result = new TreeMap<String, Integer>();
        for (PublicationStatus pubStatus : publicationStatus) {
            result.put(pubStatus.getName(), pubStatus.getId());
        }
        return result;
    }

    public Map<String, Long> getSelectedExportFormat() {
        Map<String, Long> result = new TreeMap<String, Long>();
        for (ItemPackageFormat itemPackage : itemPackageFormat) {
            result.put(itemPackage.getName(), itemPackage.getId());
        }
        return result;
    }

    private String readParameter(String param) {
        return "null".equalsIgnoreCase(getParameter(param)) ? null
                : getParameter(param);
    }

    public String getSelectedOrganization() {
        return selectedOrganization;
    }

    public void setSelectedOrganization(String selectedOrganization) {
        this.selectedOrganization = selectedOrganization;
    }

    public Integer getSelectedProgram() {
        return selectedProgram;
    }

    public void setSelectedProgram(Integer selectedProgram) {
        this.selectedProgram = selectedProgram;
    }

    public Map<String, Integer> getItemBankNamesMap() {
        Map<String, Integer> result = new TreeMap<String, Integer>();
        for (ItemBank itemBank : itemBankList) {
            result.put(itemBank.getExternalId(), itemBank.getId());
        }
        return result;
    }

    public Map<String, Integer> getOrgNamesMap() {
        return this.orgNamesMap;
    }

    public UploadedFile getUploadedFile() {
        return uploadedFile;
    }

    public void setUploadedFile(UploadedFile uploadedFile) {
        this.uploadedFile = uploadedFile;
    }

    public String getSelectedMoveoption() {
        return selectedMoveoption;
    }

    public void setSelectedMoveoption(String selectedMoveoption) {
        this.selectedMoveoption = selectedMoveoption;
    }

    public String getUser() {
        return user;
    }

    public void setUser(String user) {
        this.user = user;
    }

    /**
     * @return the userName
     */
    public String getUserName() {
        return userName;
    }

    /**
     * @param userName
     *            the userName to set
     */
    public void setUserName(String userName) {
        this.userName = userName;
    }

    @PostConstruct
    public void load() {
        this.userName = readParameter("userName");
        User usr = userServices.getUser(userName);

        itemPackageFormat = itemServices.getExportedFormat();
        publicationStatus = itemServices.getPublishedStatus();

        orgNamesMap = new TreeMap<String, Integer>();
        orgNamesMap.put(usr.getOrganization().getOrgName(), usr
                .getOrganization().getId());

        itemBankList = itemBankServices.getItemBanksForUser(usr);
        LOGGER.info("Item banks loaded. Count = " + itemBankList.size());

        searchedItems = new ArrayList<Item>();
        firstRow = 0;
        this.setUser(String.valueOf(usr.getId()));
    }

    public String importItemPkg() {
        try {

            if (!validateImportRequest()) {
                return "";
            }

            final String serverUrl = ServerConfiguration
                    .getProperty(ServerConfiguration.HTTP_SERVER_URL);
            String webServiceUrl = serverUrl
                    + "/orca-sbac/service/import/importItmPkg";
            FormDataMultiPart form = new FormDataMultiPart();

            form.bodyPart(new FormDataBodyPart("program", this
                    .getSelectedProgram() != null ? getSelectedProgram()
                    .toString() : "0"));
            form.bodyPart(new FormDataBodyPart("user", this.getUser()));
            form.bodyPart(new FormDataBodyPart("moveType", "1"));
            form.bodyPart(new FormDataBodyPart("fileName", this
                    .getUploadedFile().getName()));
            form.bodyPart(new FormDataBodyPart("itemPkgFormat", this
                    .getSelectedImportFormat()));

            FormDataBodyPart formDataBodyPart = new FormDataBodyPart(
                    "file",
                    new ByteArrayInputStream(this.getUploadedFile().getBytes()),
                    MediaType.APPLICATION_OCTET_STREAM_TYPE);
            form.bodyPart(formDataBodyPart);

            WebResource resource = Client.create(
                    CertUtil.getAllTrustingClientConfig()).resource(
                    webServiceUrl);
            String response = resource.type(MediaType.MULTIPART_FORM_DATA)
                    .post(String.class, form);

            JSONObject jsonResponse = new JSONObject(response);
            String responseCode = jsonResponse.getString("importStatusCode");
            if (!"0".equals(responseCode)) {
                FacesContext context = FacesContext.getCurrentInstance();
                context.addMessage(
                        null,
                        new FacesMessage(jsonResponse
                                .getString("importStatusMsg")));
                return null;
            }

            LOGGER.info("response" + response);
        } catch (UniformInterfaceException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not generate importItemPkg: "
                            + e.getResponse().getEntity(String.class)).build();
            throw new WebApplicationException(errorResponse);
        } catch (ClientHandlerException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not generate importItemPkg: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        } catch (Exception e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
            final Response errorResponse = Response
                    .status(Status.BAD_REQUEST)
                    .entity("Could not generate importItemPkg: "
                            + e.getMessage()).build();
            throw new WebApplicationException(errorResponse);
        }
        String fileName = this.getUploadedFile().getName();
        String fileSeparatorLinux = "/";
        String fileSeparatorWindows = "\\";
        String modifiedFileName = fileName.lastIndexOf(fileSeparatorLinux) >= 0 ? fileName
                .substring(fileName.lastIndexOf(fileSeparatorLinux) + 1)
                : (fileName.lastIndexOf(fileSeparatorWindows) >= 0 ? fileName
                        .substring(fileName.lastIndexOf(fileSeparatorWindows) + 1)
                        : fileName);
        return "ContentMonitor.jsf?faces-redirect=true&file="
                + modifiedFileName + "&item=" + this.getSelectedProgram()
                + "&userName=" + this.getUserName();
    }

    private boolean validateImportRequest() {
        boolean validate = true;
        if (StringUtils.isBlank(selectedOrganization)) {
            errorMsg("Organization not selected");
            validate = false;
        }
        if (selectedProgram == null || selectedProgram <= 0) {
            errorMsg("Program not selected");
            validate = false;
        }
        if (StringUtils.isBlank(selectedImportFormat)) {
            errorMsg("Format not selected");
            validate = false;
        }
        if (uploadedFile == null
                || (uploadedFile != null && StringUtils.isBlank(uploadedFile
                        .getName()))) {
            errorMsg("File not chosen");
            validate = false;
        } else if (uploadedFile != null
                && !StringUtils.endsWithIgnoreCase(
                        FilenameUtils.getName(uploadedFile.getName()), ".zip")) {
            errorMsg("Only zip file can be imported");
            validate = false;
        }
        return validate;
    }

    public void invokeImportItemService(Long itemMonitorId, String packageName) {
        try {
            final String serverUrl = ServerConfiguration
                    .getProperty(ServerConfiguration.HTTP_SERVER_URL);
            String webServiceUrl = serverUrl
                    + "/orca-sbac/service/import/importItmPkg";
            URL url = new URL(webServiceUrl + "/" + itemMonitorId + "/"
                    + packageName);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            ((HttpsURLConnection) conn).setHostnameVerifier(CertUtil
                    .getHostnameVerifier());
            ((HttpsURLConnection) conn).setSSLSocketFactory(CertUtil
                    .getSSLSocketFactory());

            conn.setRequestMethod("POST");
            conn.setRequestProperty("Accept", "application/json");

            if (conn.getResponseCode() != 200) {
                throw new RuntimeException("Failed : HTTP error code : "
                        + conn.getResponseCode());
            }
            conn.disconnect();

        } catch (MalformedURLException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        }
    }

    public String searchItemPkg() {
        executed = false;
        searchedItems = null;
        firstRow = 0;

        String externalIds = null;
        if (StringUtils.isNotBlank(name)) {
            externalIds = name.trim();
        }

        if (selectedExportProgram != 0) {

            searchedItems = itemServices
                    .findItemsByExternalIdAndPublicationStatus(externalIds,
                            selectedExportProgram, pubStatus);

        } else {
            FacesContext context = FacesContext.getCurrentInstance();
            context.addMessage(null, new FacesMessage(
                    "Error: Please Select program value"));
        }

        if (CollectionUtils.isNotEmpty(searchedItems)) {
            sort();
        }
        return "";
    }

    // method for item export
    public String exportItemPkg() {

        executed = false;
        Boolean validated = Boolean.TRUE;
        if (selectedExportProgram == null || selectedExportProgram == 0) {
            errorMsg("Please select Program to continue.");
            validated = Boolean.FALSE;
        }
        if (StringUtils.isBlank(selectedFormat)) {
            errorMsg("Please select Export Format to continue.");
            validated = Boolean.FALSE;
        }
        if (StringUtils.isBlank(selectedDestination)) {
            errorMsg("Please select Export Destination to continue.");
            validated = Boolean.FALSE;
        }

        if (validated) {
            if ("EXFile".equals(selectedDestination)) {
                // checked items key in map
                if ((checked.values().contains(true) && selectedExportProgram != 0)
                        || (searchFile != null && searchFile.getSize() > 0 && searchFile
                                .getName().endsWith(".csv"))) {

                    // get all selected item key
                    List<String> checkedItemId = new ArrayList<String>();
                    if (checked.values().contains(true)) {
                        for (String key : checked.keySet()) {
                            if (checked.get(key)) {
                                checkedItemId.add(key);
                            }
                        }
                    } else {
                        try {
                            ByteArrayInputStream inputStream = new ByteArrayInputStream(
                                    searchFile.getBytes());
                            InputStreamReader ireader = new InputStreamReader(
                                    inputStream);
                            BufferedReader breader = new BufferedReader(ireader);
                            String line = null;
                            int skip = 0;
                            while ((line = breader.readLine()) != null) {
                                if (skip == 0) {
                                    skip++;
                                    continue;
                                }
                                if (StringUtils.isNotEmpty(line.trim())) {
                                    checkedItemId.add(line);
                                }
                            }
                            searchedItems.clear();
                        } catch (IOException e) {
                            LOGGER.log(Level.INFO, e.getMessage(), e);
                        }
                    }

                    // get all item from select key
                    List<Item> checkedItem = getAllCheckedItem(checkedItemId);
                    if (CollectionUtils.isEmpty(checkedItem)) {
                        errorMsg("Error: All Item ID in CSV File is not Valid");
                        return "";
                    }
                    // banked and unbanked item list
                    List<String> bankedListId = new ArrayList<String>();
                    List<String> unbankedListId = new ArrayList<String>();
                    for (Item i : checkedItem) {
                        if ("Banked".equalsIgnoreCase(i.getDevState().getName()
                                .trim())) {
                            bankedListId.add(i.getExternalId());
                        } else {
                            unbankedListId.add(i.getExternalId());
                        }
                    }
                    if (CollectionUtils.isEmpty(unbankedListId)) {
                        if (!checkItemsSelected(bankedListId, selectedFormat)) {
                            return "";
                        }
                        List<String> sbaifCheck = checkIPF(bankedListId,
                                selectedFormat);
                        if (!sbaifCheck.isEmpty()) {
                            if ("1".equalsIgnoreCase(selectedFormat)) {
                                errorMsg("Error: Item(s) "
                                        + StringUtils.join(sbaifCheck, ",")
                                        + " are not in IMS format");
                                return "";
                            } else {
                                errorMsg("Error: Item(s) "
                                        + StringUtils.join(sbaifCheck, ",")
                                        + " are not in SBAIF format");
                                return "";
                            }
                        }

                        StringBuilder expItemListlocal = new StringBuilder();
                        for (String s : bankedListId) {
                            expItemListlocal.append(s).append(",");
                        }
                        // call method for download item

                        final String serverUrl = ServerConfiguration
                                .getProperty(ServerConfiguration.HTTP_SERVER_URL);
                        String webServiceUrl = serverUrl
                                + "/orca-sbac/service/export/items";
                        WebResource resource = Client.create(
                                CertUtil.getAllTrustingClientConfig())
                                .resource(webServiceUrl);

                        MultivaluedMap<String, String> formData = new MultivaluedMapImpl();
                        formData.add(
                                "itemIds",
                                (expItemListlocal.toString().trim().isEmpty()) ? expItemListlocal
                                        .toString() : expItemListlocal
                                        .toString().substring(0,
                                                expItemListlocal.length() - 1));
                        formData.add("itemBankId",
                                Integer.toString(selectedExportProgram));
                        formData.add("userId", user);
                        formData.add("packageType", selectedFormat);
                        formData.add("destinationType", "External File");
                        formData.add("publicationStatus",
                                Integer.toString(pubStatus));
                        formData.add("itemPkgFormat", this.getSelectedFormat());
                        ClientResponse response = resource
                                .queryParams(formData)
                                .accept("application/zip")
                                .type(MediaType.APPLICATION_FORM_URLENCODED)
                                .post(ClientResponse.class);

                        try {
                            if (response.getStatus() == 200) {
                                List<String> contentDisposition = response
                                        .getHeaders()
                                        .get("content-disposition");
                                String headerValue = contentDisposition.get(0)
                                        .split(";")[1];
                                LOGGER.info(headerValue.split("=")[1]);
                                String fileName = headerValue.split("=")[1]
                                        .trim();
                                InputStream is = response
                                        .getEntity(InputStream.class);
                                FacesContext fc = FacesContext
                                        .getCurrentInstance();
                                ExternalContext ec = fc.getExternalContext();
                                ec.setResponseHeader("Content-Disposition",
                                        "attachment; filename=\"" + fileName
                                                + "\"");
                                ec.setResponseContentType("application/zip");
                                OutputStream output = ec
                                        .getResponseOutputStream();
                                IOUtils.copy(is, output);
                                fc.responseComplete();

                            } else {
                                LOGGER.info("Status " + response.getStatus());
                                errorMsg("Error: Unable to download export zip. Please try again");
                            }
                        } catch (Exception e) {
                            LOGGER.log(
                                    Level.SEVERE,
                                    "Error in downloading zip file "
                                            + e.getMessage(), e);
                            errorMsg("Error: Unable to download export zip. Please try again");
                        }
                    } else {
                        executed = true;
                        popMessage = StringUtils.join(unbankedListId, ",");
                        unbankedListId.clear();
                    }
                } else {
                    if (searchFile != null
                            && !(searchFile.getName().endsWith(".csv"))) {
                        errorMsg("Error: Please select CSV format file only");
                    } else {
                        errorMsg("Error: Please select at least one item to Export");
                    }
                }
            } else {
                if ("TIB".equals(selectedDestination)) {
                    // checked items key in map
                    if ((checked.values().contains(true) && selectedExportProgram != 0)
                            || (searchFile != null && searchFile.getSize() > 0 && searchFile
                                    .getName().endsWith(".csv"))) {

                        // get all selected item key
                        List<String> checkedItemId = new ArrayList<String>();
                        if (checked.values().contains(true)) {
                            for (String key : checked.keySet()) {
                                if (checked.get(key)) {
                                    checkedItemId.add(key);
                                }
                            }
                        } else {
                            try {
                                ByteArrayInputStream inputStream = new ByteArrayInputStream(
                                        searchFile.getBytes());
                                InputStreamReader ireader = new InputStreamReader(
                                        inputStream);
                                BufferedReader breader = new BufferedReader(
                                        ireader);
                                String line = null;
                                int skip = 0;
                                while ((line = breader.readLine()) != null) {
                                    if (skip == 0) {
                                        skip++;
                                        continue;
                                    }
                                    if (StringUtils.isNotEmpty(line.trim())) {
                                        checkedItemId.add(line);
                                    }
                                }
                                searchedItems.clear();
                            } catch (IOException e) {
                                LOGGER.log(Level.INFO, e.getMessage(), e);
                            }
                        }

                        // get all item from select key
                        List<Item> checkedItem = getAllCheckedItem(checkedItemId);
                        if (CollectionUtils.isEmpty(checkedItem)) {
                            errorMsg("Error: All Item ID in CSV File is not Valid");
                            return "";
                        }

                        // banked and unbanked item list
                        List<String> bankedListId = new ArrayList<String>();
                        List<String> unbankedListId = new ArrayList<String>();
                        for (Item i : checkedItem) {
                            if ("Banked".equalsIgnoreCase(i.getDevState()
                                    .getName().trim())) {
                                bankedListId.add(i.getExternalId());
                            } else {
                                unbankedListId.add(i.getExternalId());
                            }
                        }
                        if (CollectionUtils.isEmpty(unbankedListId)) {
                            if (!checkItemsSelected(bankedListId,
                                    selectedFormat)) {
                                return "";
                            }

                            List<String> sbaifCheck = checkIPF(bankedListId,
                                    selectedFormat);
                            if (!sbaifCheck.isEmpty()) {
                                if ("1".equalsIgnoreCase(selectedFormat)) {
                                    errorMsg("Error: Item(s) "
                                            + StringUtils.join(sbaifCheck, ",")
                                            + " are not in IMS format");
                                    return "";
                                } else {
                                    errorMsg("Error: Item(s) "
                                            + StringUtils.join(sbaifCheck, ",")
                                            + " are not in SBAIF format");
                                    return "";
                                }
                            }

                            StringBuilder expItemListlocal = new StringBuilder();
                            for (String s : bankedListId) {
                                expItemListlocal.append(s).append(",");
                            }
                            // call method for export items to tib
                            final String serverUrl = ServerConfiguration
                                    .getProperty(ServerConfiguration.HTTP_SERVER_URL);
                            String webServiceUrl = serverUrl
                                    + "/orca-sbac/service/export/items/tib";
                            WebResource resource = Client.create(
                                    CertUtil.getAllTrustingClientConfig())
                                    .resource(webServiceUrl);
                            MultivaluedMap<String, String> formData = new MultivaluedMapImpl();
                            formData.add(
                                    "itemIds",
                                    (expItemListlocal.toString().trim()
                                            .isEmpty()) ? expItemListlocal
                                            .toString()
                                            : expItemListlocal
                                                    .toString()
                                                    .substring(
                                                            0,
                                                            expItemListlocal
                                                                    .length() - 1));
                            formData.add("itemBankId",
                                    Integer.toString(selectedExportProgram));
                            formData.add("userId", user);
                            formData.add("packageType", selectedFormat);
                            formData.add("destinationType", "Text Item Bank");
                            formData.add("publicationStatus",
                                    Integer.toString(pubStatus));
                            formData.add("itemPkgFormat",
                                    this.getSelectedFormat());
                            ClientResponse response = resource
                                    .queryParams(formData)
                                    .accept(MediaType.APPLICATION_JSON)
                                    .type(MediaType.APPLICATION_FORM_URLENCODED)
                                    .post(ClientResponse.class);

                            try {
                                if (response.getStatus() == 200
                                        && response
                                                .getType()
                                                .isCompatible(
                                                        MediaType.APPLICATION_JSON_TYPE)) {
                                    String fileName = getTIBresponseFileName(response
                                            .getEntity(String.class));
                                    if (StringUtils.isNotBlank(fileName)) {
                                        return "ContentMonitor.jsf?faces-redirect=true&file="
                                                + fileName
                                                + "&item="
                                                + this.getSelectedExportProgram()
                                                + "&userName="
                                                + this.getUserName();
                                    }
                                } else {
                                    LOGGER.info("Status "
                                            + response.getStatus());
                                    errorMsg("Error: Unable to export item(s) to Test Item Bank. Please try again");
                                }
                            } catch (Exception e) {
                                LOGGER.log(Level.SEVERE,
                                        "Error in export item(s) to Test Item Bank "
                                                + e.getMessage(), e);
                                errorMsg("Error: Unable to export item(s) to Test Item Bank. Please try again");
                            }

                        } else {
                            executed = true;
                            popMessage = StringUtils.join(unbankedListId, ",");
                            unbankedListId.clear();
                        }
                    } else {
                        if (searchFile != null
                                && !(searchFile.getName().endsWith(".csv"))) {
                            errorMsg("Error: Please select CSV format file only");
                        } else {
                            errorMsg("Error: Please select at least one item to Export");
                        }
                    }
                }
            }
        }

        checked.clear();
        return "";
    }

    private boolean checkItemsSelected(List<String> itemIds,
            String selectedFormat) {
        boolean validated = true;
        List<String> itemNames = new ArrayList<String>();
        List<Item> items = itemServices
                .findItemsByExternalIdsAndPublicationStatus(itemIds, 0, 0);
        if (CollectionUtils.isNotEmpty(items)) {
            for (Item item : items) {
                if ("Performance Task".equalsIgnoreCase(item
                        .getItemFormatName())
                        || "Activity Based".equalsIgnoreCase(item
                                .getItemFormatName())) {
                    itemNames.add(item.getExternalId());
                }
            }
        }
        if (CollectionUtils.isNotEmpty(itemNames)) {
            errorMsg("Error: Item(s) " + StringUtils.join(itemNames, ",")
                    + " formats are not supported for export");
            validated = false;
        }
        return validated;
    }

    private String getTIBresponseFileName(String jsonResponse) {
        String fileName = "";

        try {
            if (StringUtils.isNotBlank(jsonResponse)) {
                JSONObject responseObject = new JSONObject(jsonResponse);
                if (responseObject != null
                        && "0".equalsIgnoreCase(responseObject
                                .getString("exportStatusCode"))) {
                    fileName = responseObject.getString("exportFileName");
                }
            }
        } catch (JSONException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in parsing Item Export to TIB service response "
                            + e.getMessage(), e);
        } catch (Exception e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Error in parsing Item Export to TIB service response "
                            + e.getMessage(), e);
        }
        return fileName;
    }

    private List<String> checkIPF(List<String> bankedListId,
            String selectedFormat) {
        List<String> externalIdList = new ArrayList<String>();
        for (Item item : searchedItems) {
            if (bankedListId.contains(item.getExternalId())) {
                externalIdList.add(item.getExternalId());
            }
        }
        List<String> imsList = new ArrayList<String>();
        List<ItemMoveMonitor> immList = itemServices.getIMD(externalIdList);
        if (immList.isEmpty()) {
            return imsList;
        }
        if ("1".equalsIgnoreCase(selectedFormat)) {
            for (ItemMoveMonitor imm : immList) {
                if ("IMS"
                        .equalsIgnoreCase(imm.getItemPackageFormat().getName())) {
                    continue;
                } else {
                    List<ItemMoveDetails> j = imm.getItemMoveDetails();
                    for (ItemMoveDetails k : j) {
                        imsList.add(k.getExternalId());
                    }
                }
            }
        } else {
            for (ItemMoveMonitor imm : immList) {
                if ("SBAIF".equalsIgnoreCase(imm.getItemPackageFormat()
                        .getName())) {
                    continue;
                } else {
                    List<ItemMoveDetails> j = imm.getItemMoveDetails();
                    for (ItemMoveDetails k : j) {
                        imsList.add(k.getExternalId());
                    }
                }
            }

        }
        return imsList;
    }

    private List<Item> getAllCheckedItem(List<String> checkedItemId) {

        List<Item> selectedItem = new ArrayList<Item>();
        Iterator<Item> it = searchedItems.iterator();
        while (it.hasNext()) {
            Item i = it.next();
            if (checkedItemId.contains(i.getExternalId())) {
                selectedItem.add(i);
            }
        }
        if (selectedItem.isEmpty()) {
            selectedItem = itemServices
                    .findItemsByExternalIdsAndPublicationStatus(checkedItemId,
                            0, 0);
            if (selectedItem.size() != checkedItemId.size()
                    || selectedItem.isEmpty()) {
                return Collections.<Item> emptyList();
            }
        }

        return selectedItem;
    }

    public void clearExecuted() {
        executed = false;
    }

    public void sort() {
        Comparator<Item> comparator = new Comparator<Item>() {
            @Override
            public int compare(Item row1, Item row2) {
                if (sortField == null) {
                    return 0;
                }
                if ("organization".equals(sortField)) {
                    return sortAscending ? row1
                            .getItemBank()
                            .getOrganization()
                            .getOrgName()
                            .compareTo(
                                    row2.getItemBank().getOrganization()
                                            .getOrgName()) : row2
                            .getItemBank()
                            .getOrganization()
                            .getOrgName()
                            .compareTo(
                                    row1.getItemBank().getOrganization()
                                            .getOrgName());
                }
                if ("name".equals(sortField)) {
                    if (row1.getExternalId() == null
                            || row2.getExternalId() == null) {
                        return 0;
                    }
                    return sortAscending ? row1.getExternalId().compareTo(
                            row2.getExternalId()) : row2.getExternalId()
                            .compareTo(row1.getExternalId());
                }
                if ("program".equals(sortField)) {
                    return sortAscending ? row1.getItemBank().getDescription()
                            .compareTo(row2.getItemBank().getDescription())
                            : row2.getItemBank()
                                    .getDescription()
                                    .compareTo(
                                            row1.getItemBank().getDescription());
                }
                if ("status".equals(sortField)) {
                    return sortAscending ? row1.getPublicationStatus()
                            .compareTo(row2.getPublicationStatus()) : row2
                            .getPublicationStatus().compareTo(
                                    row1.getPublicationStatus());
                }
                if ("iformat".equals(sortField)) {
                    return sortAscending ? row1.getItemFormatName().compareTo(
                            row2.getItemFormatName()) : row2
                            .getItemFormatName().compareTo(
                                    row1.getItemFormatName());
                }
                if ("ipformat".equals(sortField)) {
                    return sortAscending ? row1.getPackageFormatName()
                            .compareTo(row2.getPackageFormatName()) : row2
                            .getPackageFormatName().compareTo(
                                    row1.getPackageFormatName());
                }
                return 0;
            }
        };
        List<Item> moveItems = new ArrayList<Item>();
        if (CollectionUtils.isNotEmpty(searchedItems)) {
            for (Item item : searchedItems) {
                moveItems.add(item);
            }
            Collections.sort(moveItems, comparator);
            searchedItems = moveItems;
        }
    }

    public Integer getSelectedExportProgram() {
        return selectedExportProgram;
    }

    public void setSelectedExportProgram(Integer selectedExportProgram) {
        this.selectedExportProgram = selectedExportProgram;
    }

    public UploadedFile getSearchFile() {
        return searchFile;
    }

    public void setSearchFile(UploadedFile searchFile) {
        this.searchFile = searchFile;
    }
}
