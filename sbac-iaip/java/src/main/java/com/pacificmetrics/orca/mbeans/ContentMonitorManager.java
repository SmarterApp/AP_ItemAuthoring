package com.pacificmetrics.orca.mbeans;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Serializable;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
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
import javax.faces.component.UICommand;
import javax.faces.component.UIInput;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.faces.event.FacesEvent;
import javax.faces.event.ValueChangeEvent;
import javax.net.ssl.HttpsURLConnection;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;
import org.json.JSONException;
import org.json.JSONObject;

import com.pacificmetrics.orca.ServerConfiguration;
import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.ejb.UserServices;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;
import com.pacificmetrics.orca.entities.ItemMoveStatus;
import com.pacificmetrics.orca.entities.ItemMoveType;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.utils.CertUtil;

@ManagedBean(name = "contentMonitor")
@ViewScoped
public class ContentMonitorManager extends AbstractManager implements
        Serializable {
    private static final Logger LOGGER = Logger
            .getLogger(ContentMonitorManager.class.getName());

    private static final long serialVersionUID = 1L;

    @EJB
    private transient ItemBankServices itemBankServices;

    @EJB
    private transient ContentMoveServices contentMoveServices;

    @EJB
    private transient UserServices userServices;

    private String itemAction;
    private List<ItemBank> itemBankList;

    private Map<Long, ItemMoveStatus> itemMoveStatusMap;
    private Map<Long, ItemMoveType> itemMoveTypeMap;
    private Map<Integer, String> organizationMap;
    private Map<Integer, String> userMap;

    private Long itemMonitorId;
    private Integer itemBankId;

    private int firstRowIndex;

    private String sortColumn;
    private boolean ascending;
    private String userName;

    // filter fields
    private String searchSourceText;
    private String searchFileText;
    private String searchDestinationText;

    private String selectedMoveType;
    private String selectedOrganization;
    private String selectedUser;
    private String selectedStatus;
    private String selectedItemBank;

    private List<ItemMoveMonitor> itemMoveMonitors;
    private List<ItemMoveMonitor> unfilteredItemMoveMonitors;

    // ###########################################
    private List<ItemMoveMonitor> dataList;
    private int totalRows;

    // Paging.
    private int firstRow;
    private int rowsPerPage;
    private int totalPages;
    private int pageRange;
    private Integer[] pages;
    private int currentPage;

    // Sorting.
    private String sortField;
    private boolean sortAscending;

    // Constructors
    // -------------------------------------------------------------------------------

    public ContentMonitorManager() {
        // Set default values somehow (properties files?).
        // Default rows per page (max amount of rows to be
        // displayed at once).
        rowsPerPage = 15;
        // Default page range (max amount of page links to be
        // displayed at once).
        pageRange = 15;

        // Default sort field.
        sortField = "source";
        // Default sort direction.
        sortAscending = true;
    }

    // Paging actions
    // -----------------------------------------------------------------------------

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

    public void pageFirst() {
        page(0);
    }

    public void pageNext() {
        page(firstRow + rowsPerPage);
    }

    public void pagePrevious() {
        page(firstRow - rowsPerPage);
    }

    public void pageLast() {
        page(totalRows
                - ((totalRows % rowsPerPage != 0) ? totalRows % rowsPerPage
                        : rowsPerPage));
    }

    public void page(ActionEvent event) {
        page(((Integer) ((UICommand) event.getComponent()).getValue() - 1)
                * rowsPerPage);
    }

    private void page(int firstRow) {
        this.firstRow = firstRow;
        // Load requested page.
        loadDataList();
    }

    // Loaders
    // ------------------------------------------------------------------------------------

    private void loadDataList() {

        // Load list and totalCount.
        if (!StringUtils.isEmpty(selectedItemBank)
                && contentMoveServices != null) {
            unfilteredItemMoveMonitors = dataList = contentMoveServices
                    .findItemMoveMonitorsByItemBankId(Long
                            .parseLong(selectedItemBank));
            totalRows = dataList.size();
        } else if (StringUtils.isEmpty(selectedItemBank)) {
            unfilteredItemMoveMonitors = dataList = contentMoveServices
                    .findAllItemMoveMonitors();
            totalRows = dataList.size();
        }

        if (dataList != null) {
            filter();
            sort();
        }
        dataList = dataList != null ? dataList : Collections
                .<ItemMoveMonitor> emptyList();

        // Set currentPage, totalPages and pages.
        currentPage = (totalRows / rowsPerPage)
                - ((totalRows - firstRow) / rowsPerPage) + 1;
        totalPages = (totalRows / rowsPerPage)
                + ((totalRows % rowsPerPage != 0) ? 1 : 0);
        int pagesLength = Math.min(pageRange, totalPages);
        pages = new Integer[pagesLength];

        // firstPage must be greater than 0 and lesser than
        // totalPages-pageLength.
        int firstPage = Math.min(Math.max(0, currentPage - (pageRange / 2)),
                totalPages - pagesLength);

        // Create pages (page numbers for page links).
        for (int i = 0; i < pagesLength; i++) {
            pages[i] = ++firstPage;
        }
    }

    @PostConstruct
    public void load() {
        readFilterParameters();
        this.userName = readParameter("userName");
        String userNameLocal = this.userName;
        User usr = userServices.getUser(userNameLocal);

        organizationMap = new TreeMap<Integer, String>();
        organizationMap.put(usr.getOrganization().getId(), usr
                .getOrganization().getOrgName());

        itemBankList = itemBankServices.getItemBanksForUser(usr);
        LOGGER.info("Item banks loaded. Count = " + itemBankList.size());

        itemMoveStatusMap = contentMoveServices.getItemMoveStatusMap();
        itemMoveTypeMap = contentMoveServices.getItemMoveTypeMap();

        userMap = userServices.getUserMap();
    }

    private void readFilterParameters() {
        selectedOrganization = readParameter("org");
        selectedItemBank = readParameter("item");
        searchSourceText = readParameter("source");
        searchDestinationText = readParameter("dest");
        searchFileText = readParameter("file");
        selectedMoveType = readParameter("mtype");
        selectedStatus = readParameter("status");
        selectedUser = readParameter("user");
    }

    private String readParameter(String param) {
        return "null".equalsIgnoreCase(getParameter(param)) ? null
                : getParameter(param);
    }

    public Map<String, Integer> getItemBankNamesMap() {
        Map<String, Integer> result = new TreeMap<String, Integer>();
        for (ItemBank itemBank : itemBankList) {
            result.put(itemBank.getExternalId(), itemBank.getId());
        }
        return result;
    }

    public void doFilter() {
        filter();
        sort();
    }

    public List<ItemMoveMonitor> getAllItemMoveMonitors() {
        if (!StringUtils.isEmpty(selectedItemBank)
                && contentMoveServices != null) {
            unfilteredItemMoveMonitors = itemMoveMonitors = contentMoveServices
                    .findItemMoveMonitorsByItemBankId(Long
                            .parseLong(selectedItemBank));
        } else if (StringUtils.isEmpty(selectedItemBank)) {
            unfilteredItemMoveMonitors = itemMoveMonitors = contentMoveServices
                    .findAllItemMoveMonitors();
        }
        if (itemMoveMonitors != null) {
            filter();
            sort();
            totalRows = itemMoveMonitors.size();
        }

        // Set currentPage, totalPages and pages.
        currentPage = (totalRows / rowsPerPage)
                - ((totalRows - firstRow) / rowsPerPage) + 1;
        totalPages = (totalRows / rowsPerPage)
                + ((totalRows % rowsPerPage != 0) ? 1 : 0);
        int pagesLength = Math.min(pageRange, totalPages);
        pages = new Integer[pagesLength];

        // firstPage must be greater than 0 and lesser than
        // totalPages-pageLength.
        int firstPage = Math.min(Math.max(0, currentPage - (pageRange / 2)),
                totalPages - pagesLength);

        // Create pages (page numbers for page links).
        for (int i = 0; i < pagesLength; i++) {
            pages[i] = ++firstPage;
        }

        return itemMoveMonitors != null ? itemMoveMonitors : Collections
                .<ItemMoveMonitor> emptyList();
    }

    public void sort() {
        Comparator<ItemMoveMonitor> comparator = new Comparator<ItemMoveMonitor>() {

            @Override
            public int compare(ItemMoveMonitor row1, ItemMoveMonitor row2) {
                if (sortField == null) {
                    return 0;
                }
                if ("source".equals(sortField)) {
                    if (sortAscending) {
                        if (StringUtils.isEmpty(row1.getSource())) {
                            if (StringUtils.isEmpty(row2.getSource())) {
                                return 0;
                            }
                            return 1;
                        }
                        if (StringUtils.isEmpty(row2.getSource())) {
                            return -1;
                        }
                    } else {
                        if (StringUtils.isEmpty(row2.getSource())) {
                            if (StringUtils.isEmpty(row1.getSource())) {
                                return 0;
                            }
                            return 1;
                        }
                        if (StringUtils.isEmpty(row1.getSource())) {
                            return -1;
                        }
                    }
                    return sortAscending ? row1.getSource().compareTo(
                            row2.getSource()) : row2.getSource().compareTo(
                            row1.getSource());
                }
                if ("destination".equals(sortField)) {
                    if (sortAscending) {
                        if (StringUtils.isEmpty(row1.getDestination())) {
                            if (StringUtils.isEmpty(row2.getDestination())) {
                                return 0;
                            }
                            return 1;
                        }
                        if (StringUtils.isEmpty(row2.getDestination())) {
                            return -1;
                        }
                    } else {
                        if (StringUtils.isEmpty(row2.getDestination())) {
                            if (StringUtils.isEmpty(row1.getDestination())) {
                                return 0;
                            }
                            return 1;
                        }
                        if (StringUtils.isEmpty(row1.getDestination())) {
                            return -1;
                        }
                    }
                    return sortAscending ? row1.getDestination().compareTo(
                            row2.getDestination()) : row2.getDestination()
                            .compareTo(row1.getDestination());
                }
                if ("moveTypeAsString".equals(sortField)) {
                    return sortAscending ? row1.getMoveTypeAsString()
                            .compareTo(row2.getMoveTypeAsString()) : row2
                            .getMoveTypeAsString().compareTo(
                                    row1.getMoveTypeAsString());
                }
                if ("timestampAsString".equals(sortField)) {
                    return sortAscending ? row1.getTimeOfMove().compareTo(
                            row2.getTimeOfMove()) : row2.getTimeOfMove()
                            .compareTo(row1.getTimeOfMove());
                }
                if ("organizationAsString".equals(sortField)) {
                    return sortAscending ? row1.getOrganizationAsString()
                            .compareTo(row2.getOrganizationAsString()) : row2
                            .getOrganizationAsString().compareTo(
                                    row1.getOrganizationAsString());
                }
                if ("programAsString".equals(sortField)) {
                    return sortAscending ? row1.getProgramAsString().compareTo(
                            row2.getProgramAsString()) : row2
                            .getProgramAsString().compareTo(
                                    row1.getProgramAsString());
                }
                if ("fileName".equals(sortField)) {
                    return sortAscending ? row1.getFileName().compareTo(
                            row2.getFileName()) : row2.getFileName().compareTo(
                            row1.getFileName());
                }
                if ("userNameAsString".equals(sortField)) {
                    return sortAscending ? row1.getUserNameAsString()
                            .compareTo(row2.getUserNameAsString()) : row2
                            .getUserNameAsString().compareTo(
                                    row1.getUserNameAsString());
                }
                if ("status".equals(sortField)) {
                    return sortAscending ? row1.getStatusAsString().compareTo(
                            row2.getStatusAsString()) : row2
                            .getStatusAsString().compareTo(
                                    row1.getStatusAsString());
                }
                return 0;
            }

        };
        List<ItemMoveMonitor> moveMonitors = new ArrayList<ItemMoveMonitor>();
        if (CollectionUtils.isNotEmpty(itemMoveMonitors)) {
            for (ItemMoveMonitor itemMoveMonitor : itemMoveMonitors) {
                moveMonitors.add(itemMoveMonitor);
            }
            Collections.sort(moveMonitors, comparator);
            itemMoveMonitors = moveMonitors;
        }

    }

    public void filter() {
        if (StringUtils.isEmpty(selectedOrganization)
                && StringUtils.isEmpty(selectedItemBank)
                && StringUtils.isEmpty(selectedMoveType)
                && StringUtils.isEmpty(searchDestinationText)
                && StringUtils.isEmpty(selectedUser)
                && StringUtils.isEmpty(selectedStatus)
                && StringUtils.isEmpty(searchSourceText)
                && StringUtils.isEmpty(searchFileText)) {
            clearFilter();
            return;
        }
        if (StringUtils.isNotEmpty(selectedOrganization)
                || StringUtils.isNotEmpty(selectedItemBank)
                || StringUtils.isNotEmpty(selectedMoveType)
                || StringUtils.isNotEmpty(searchDestinationText)
                || StringUtils.isNotEmpty(selectedUser)
                || StringUtils.isNotEmpty(selectedStatus)
                || StringUtils.isNotEmpty(searchSourceText)
                || StringUtils.isNotEmpty(searchFileText)) {
            List<ItemMoveMonitor> filteredItemMoveMonitors = new ArrayList<ItemMoveMonitor>();
            for (ItemMoveMonitor itemMoveMonitor : unfilteredItemMoveMonitors) {
                boolean eligible = true;
                if (StringUtils.isNotEmpty(selectedOrganization)
                        && !organizationMap.get(
                                Integer.parseInt(selectedOrganization))
                                .equalsIgnoreCase(
                                        itemMoveMonitor
                                                .getOrganizationAsString())) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(selectedItemBank)
                        && itemMoveMonitor.getItemBank() != null
                        && selectedItemBank.equals(itemMoveMonitor
                                .getItemBank().getExternalId())) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(selectedMoveType)
                        && !itemMoveTypeMap
                                .get(Long.parseLong(selectedMoveType))
                                .getName()
                                .equalsIgnoreCase(
                                        itemMoveMonitor.getMoveTypeAsString())) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(searchDestinationText)
                        && !StringUtils.containsIgnoreCase(
                                itemMoveMonitor.getDestination(),
                                searchDestinationText)) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(selectedUser)
                        && !userMap.get(Integer.parseInt(selectedUser))
                                .equalsIgnoreCase(
                                        itemMoveMonitor.getUserNameAsString())) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(selectedStatus)
                        && !itemMoveStatusMap
                                .get(Long.parseLong(selectedStatus))
                                .getStatus()
                                .equalsIgnoreCase(
                                        itemMoveMonitor.getStatusAsString())) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(searchFileText)
                        && !StringUtils.containsIgnoreCase(
                                itemMoveMonitor.getFileName(), searchFileText)) {
                    eligible = false;
                }
                if (StringUtils.isNotEmpty(searchSourceText)
                        && !StringUtils.containsIgnoreCase(
                                itemMoveMonitor.getSource(), searchSourceText)) {
                    eligible = false;
                }
                if (eligible) {
                    filteredItemMoveMonitors.add(itemMoveMonitor);
                }
            }
            itemMoveMonitors = filteredItemMoveMonitors;
        }
    }

    public void onChange(ValueChangeEvent event) {
        itemAction = (String) event.getNewValue();

        itemMonitorId = (Long) getInputAttribute(event, "itemMonitorId");
        itemBankId = (Integer) getInputAttribute(event, "itemBankId");
        String packageName = (String) getInputAttribute(event, "packageName");

        if (StringUtils.isNotEmpty(itemAction)
                && "Detail".equalsIgnoreCase(itemAction)
                && itemMonitorId != null && itemBankId != null) {
            StringBuilder sbRedirectString = new StringBuilder(
                    "ContentDetail.jsf?");
            sbRedirectString.append("itemmoveid=").append(this.itemMonitorId);
            sbRedirectString.append("&itembankid=").append(this.itemBankId);
            sbRedirectString.append("&userName=").append(this.userName);
            sbRedirectString.append("&org=").append(this.selectedOrganization);
            sbRedirectString.append("&item=").append(this.selectedItemBank);
            sbRedirectString.append("&mtype=").append(this.selectedMoveType);
            sbRedirectString.append("&user=").append(this.selectedUser);
            sbRedirectString.append("&status=").append(this.selectedStatus);
            sbRedirectString.append("&dest=")
                    .append(this.searchDestinationText);
            sbRedirectString.append("&source=").append(this.searchSourceText);
            sbRedirectString.append("&file=").append(this.searchFileText);

            redirect(sbRedirectString.toString());
        }
        if (StringUtils.isNotEmpty(itemAction)
                && "Rollback".equalsIgnoreCase(itemAction)
                && itemMonitorId != null && StringUtils.isNotEmpty(packageName)) {
            invokeRollbackService(itemMonitorId, packageName);

            StringBuilder sbRedirectString = new StringBuilder(
                    "ContentMonitor.jsf?faces-redirect=true");
            sbRedirectString.append("&userName=").append(this.userName);
            sbRedirectString.append("&org=").append(this.selectedOrganization);
            sbRedirectString.append("&item=").append(this.selectedItemBank);
            sbRedirectString.append("&mtype=").append(this.selectedMoveType);
            sbRedirectString.append("&user=").append(this.selectedUser);
            sbRedirectString.append("&status=").append(this.selectedStatus);
            sbRedirectString.append("&dest=")
                    .append(this.searchDestinationText);
            sbRedirectString.append("&source=").append(this.searchSourceText);
            sbRedirectString.append("&file=").append(this.searchFileText);

            redirect(sbRedirectString.toString());
        }
    }

    public void invokeRollbackService(Long itemMonitorId, String packageName) {
        try {
            final String serverUrl = ServerConfiguration
                    .getProperty(ServerConfiguration.HTTP_SERVER_URL);
            String webServiceUrl = serverUrl
                    + "/orca-sbac/service/import/rollbackItmPkg";
            String fileSeparatorLinux = "/";
            String fileSeparatorWindows = "\\";
            String packageNameLocal = packageName;
            packageNameLocal = (packageName.lastIndexOf(fileSeparatorLinux) >= 0 ? packageName
                    .substring(packageName.lastIndexOf(fileSeparatorLinux) + 1)
                    : packageName.lastIndexOf(fileSeparatorWindows) >= 0 ? packageName
                            .substring(packageName
                                    .lastIndexOf(fileSeparatorWindows) + 1)
                            : packageName);
            URL url = new URL(webServiceUrl + "/" + itemMonitorId + "/"
                    + packageNameLocal);
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();

            ((HttpsURLConnection) conn).setHostnameVerifier(CertUtil
                    .getHostnameVerifier());
            ((HttpsURLConnection) conn).setSSLSocketFactory(CertUtil
                    .getSSLSocketFactory());

            conn.setRequestMethod("GET");
            conn.setRequestProperty("Accept", "application/json");

            if (conn.getResponseCode() != 200) {
                throw new RuntimeException("Failed : HTTP error code : "
                        + conn.getResponseCode());
            }

            BufferedReader br = new BufferedReader(new InputStreamReader(
                    conn.getInputStream()));

            String output;
            while ((output = br.readLine()) != null) {
                LOGGER.log(Level.INFO, output, output);
                JSONObject jsonObj = new JSONObject(output);
                FacesMessage fm = new FacesMessage(
                        jsonObj.getString("rollbackStatusMsg"));
                FacesContext.getCurrentInstance().addMessage("Field is Empty",
                        fm);
            }

            conn.disconnect();

        } catch (MalformedURLException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        } catch (IOException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        } catch (JSONException e) {
            LOGGER.log(Level.INFO, e.getMessage(), e);
        }
    }

    public void scrollerAction() {
        // Do nothing because of X and Y.
    }

    private void clear() {
        searchSourceText = null;
        searchFileText = null;
        selectedItemBank = null;
        selectedStatus = null;
        selectedUser = null;
        selectedMoveType = null;
        selectedOrganization = null;
        searchDestinationText = null;
        itemAction = null;
    }

    public void clearFilter() {
        clear();
        itemMoveMonitors = unfilteredItemMoveMonitors;
        setFirstRowIndex(0);
    }

    public Object getInputAttribute(FacesEvent event, String attributeName) {
        return ((UIInput) event.getSource()).getAttributes().get(attributeName);
    }

    public int getFirstRowIndex() {
        return firstRowIndex;
    }

    public void setFirstRowIndex(int firstRowIndex) {
        this.firstRowIndex = firstRowIndex;
    }

    public ItemBankServices getItemBankServices() {
        return itemBankServices;
    }

    public void setItemBankServices(ItemBankServices itemBankServices) {
        this.itemBankServices = itemBankServices;
    }

    public ContentMoveServices getContentMoveServices() {
        return contentMoveServices;
    }

    public void setContentMoveServices(ContentMoveServices contentMoveServices) {
        this.contentMoveServices = contentMoveServices;
    }

    public UserServices getUserServices() {
        return userServices;
    }

    public void setUserServices(UserServices userServices) {
        this.userServices = userServices;
    }

    public String getItemAction() {
        return itemAction;
    }

    public void setItemAction(String itemAction) {
        this.itemAction = itemAction;
    }

    public List<ItemBank> getItemBankList() {
        return itemBankList;
    }

    public void setItemBankList(List<ItemBank> itemBankList) {
        this.itemBankList = itemBankList;
    }

    public List<ItemMoveMonitor> getItemMoveMonitors() {
        return itemMoveMonitors;
    }

    public void setItemMoveMonitors(List<ItemMoveMonitor> itemMoveMonitors) {
        this.itemMoveMonitors = itemMoveMonitors;
    }

    public List<ItemMoveMonitor> getUnfilteredItemMoveMonitors() {
        return unfilteredItemMoveMonitors;
    }

    public void setUnfilteredItemMoveMonitors(
            List<ItemMoveMonitor> unfilteredItemMoveMonitors) {
        this.unfilteredItemMoveMonitors = unfilteredItemMoveMonitors;
    }

    public String getSelectedMoveType() {
        return selectedMoveType;
    }

    public void setSelectedMoveType(String selectedMoveType) {
        this.selectedMoveType = selectedMoveType;
    }

    public String getSelectedOrganization() {
        return selectedOrganization;
    }

    public void setSelectedOrganization(String selectedOrganization) {
        this.selectedOrganization = selectedOrganization;
    }

    public String getSelectedUser() {
        return selectedUser;
    }

    public void setSelectedUser(String selectedUser) {
        this.selectedUser = selectedUser;
    }

    public String getSelectedStatus() {
        return selectedStatus;
    }

    public void setSelectedStatus(String selectedStatus) {
        this.selectedStatus = selectedStatus;
    }

    public Map<Long, ItemMoveStatus> getItemMoveStatusMap() {
        return itemMoveStatusMap;
    }

    public void setItemMoveStatusMap(Map<Long, ItemMoveStatus> itemMoveStatusMap) {
        this.itemMoveStatusMap = itemMoveStatusMap;
    }

    public Map<Long, ItemMoveType> getItemMoveTypeMap() {
        return itemMoveTypeMap;
    }

    public void setItemMoveTypeMap(Map<Long, ItemMoveType> itemMoveTypeMap) {
        this.itemMoveTypeMap = itemMoveTypeMap;
    }

    public Map<Integer, String> getOrganizationMap() {
        return organizationMap;
    }

    public void setOrganizationMap(Map<Integer, String> organizationMap) {
        this.organizationMap = organizationMap;
    }

    public Map<Integer, String> getUserMap() {
        return userMap;
    }

    public void setUserMap(Map<Integer, String> userMap) {
        this.userMap = userMap;
    }

    public String getSearchFileText() {
        return searchFileText;
    }

    public void setSearchFileText(String searchFileText) {
        this.searchFileText = searchFileText;
    }

    public String getSearchSourceText() {
        return searchSourceText;
    }

    public void setSearchSourceText(String searchSourceText) {
        this.searchSourceText = searchSourceText;
    }

    public String getSearchDestinationText() {
        return searchDestinationText;
    }

    public void setSearchDestinationText(String searchDestinationText) {
        this.searchDestinationText = searchDestinationText;
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

    public Long getItemMonitorId() {
        return itemMonitorId;
    }

    public void setItemMonitorId(Long itemMonitorId) {
        this.itemMonitorId = itemMonitorId;
    }

    public Integer getItemBankId() {
        return itemBankId;
    }

    public void setItemBankId(Integer itemBankId) {
        this.itemBankId = itemBankId;
    }

    public String getSelectedItemBank() {
        return selectedItemBank;
    }

    public void setSelectedItemBank(String selectedItemBank) {
        this.selectedItemBank = selectedItemBank;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    // Getters
    // ------------------------------------------------------------------------------------

    public List<ItemMoveMonitor> getDataList() {
        if (dataList == null) {
            // Preload page for the 1st view.
            loadDataList();
        }
        return dataList;
    }

    public int getTotalRows() {
        return totalRows;
    }

    public int getFirstRow() {
        return firstRow;
    }

    public int getRowsPerPage() {
        return rowsPerPage;
    }

    public Integer[] getPages() {
        return pages;
    }

    public int getCurrentPage() {
        return currentPage;
    }

    public int getTotalPages() {
        return totalPages;
    }

    // Setters
    // ------------------------------------------------------------------------------------

    public int getPageRange() {
        return pageRange;
    }

    public void setPageRange(int pageRange) {
        this.pageRange = pageRange;
    }

    public void setDataList(List<ItemMoveMonitor> dataList) {
        this.dataList = dataList;
    }

    public void setTotalRows(int totalRows) {
        this.totalRows = totalRows;
    }

    public void setFirstRow(int firstRow) {
        this.firstRow = firstRow;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }

    public void setPages(Integer[] pages) {
        this.pages = pages;
    }

    public void setCurrentPage(int currentPage) {
        this.currentPage = currentPage;
    }

    public void setRowsPerPage(int rowsPerPage) {
        this.rowsPerPage = rowsPerPage;
    }
}
