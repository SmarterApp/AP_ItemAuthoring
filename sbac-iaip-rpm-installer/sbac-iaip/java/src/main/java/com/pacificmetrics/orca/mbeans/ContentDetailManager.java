package com.pacificmetrics.orca.mbeans;

import java.io.IOException;
import java.io.OutputStream;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;
import javax.faces.component.UICommand;
import javax.faces.context.FacesContext;
import javax.faces.event.ActionEvent;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.collections.CollectionUtils;
import org.apache.commons.lang.StringUtils;

import com.pacificmetrics.orca.ejb.ContentMoveServices;
import com.pacificmetrics.orca.ejb.ItemBankServices;
import com.pacificmetrics.orca.entities.DetailStatusType;
import com.pacificmetrics.orca.entities.ItemBank;
import com.pacificmetrics.orca.entities.ItemDetailStatus;
import com.pacificmetrics.orca.entities.ItemMoveDetails;
import com.pacificmetrics.orca.entities.ItemMoveMonitor;

@ManagedBean(name = "contentDetail")
@ViewScoped
public class ContentDetailManager extends AbstractManager {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = Logger
            .getLogger(ContentDetailManager.class.getName());

    private static final DateFormat DATE_FORMAT = new SimpleDateFormat(
            "MMddyyyyHHmmss");

    @EJB
    private ContentMoveServices contentMoveService;

    @EJB
    private ItemBankServices itemBankServices;

    private String selectedOrganization;
    private String selectedItemBank;

    private String userName;

    private Integer itemBankId;

    private Map<String, String> statusTypeMap = new HashMap<String, String>();
    private List<ItemMoveDetails> itemMoveDetails;
    private List<ItemMoveDetails> unfilteredItemMoveDetails;

    private List<ItemDetailStatus> itemDetailStatus;
    private List<ItemDetailStatus> unfilteredItemDetailStatus;

    private String itemMoveMonitorId = null;
    private List<DetailStatusType> detailStatusType;

    private List<ItemMoveDetails> dataList;
    private int firstRowIndex;
    private int totalRows;

 // Paging.
    private int firstRow;
    private int rowsPerPage;
    private int totalPages;
    private int pageRange;
    private Integer[] pages;
    private int currentPage;
    
    private String sortColumn;
    private boolean ascending;

    // filter fields
    private String searchedItemNameText;
    private String selectedStatusType;
    private String searchDetailStatusText;
    private String selectedStatusCode;

    // monitor filter fields
    private String searchSourceText;
    private String searchFileText;
    private String searchDestinationText;
    private String selectedMoveType;
    private String selectedUser;
    private String selectedStatus;
    private String selectOrganizationId;
    private String orgName;
    private String itemBankExternalId;

 // Sorting.
    private String sortField;
    private boolean sortAscending;
    
 // Constructors
    // -------------------------------------------------------------------------------

    public ContentDetailManager() {
        // Set default values somehow (properties files?).
        // Default rows per page (max amount of rows to be
        // displayed at once).
        rowsPerPage = 15;
        // Default page range (max amount of page links to be
        // displayed at once).
        pageRange = 15;

        // Default sort field.
        sortField = "name";
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
    
    private void loadDataList() {

    	 // Load list and totalCount.
        if (!StringUtils.isEmpty(selectedItemBank)
                && contentMoveService != null) {
        	unfilteredItemMoveDetails = dataList = contentMoveService
                    .findItemMoveDetailsByItemMoveMonitorId(Long
                            .parseLong(itemMoveMonitorId));
            totalRows = dataList.size();
        } /*else if (StringUtils.isEmpty(selectedItemBank)) {
        	unfilteredItemMoveDetails = dataList = contentMoveService
                    .findAllItemMoveMonitors();
            totalRows = dataList.size();
        }*/

        if (dataList != null) {
            filter();
            sort();
        }
        dataList = dataList != null ? dataList : Collections
                .<ItemMoveDetails> emptyList();

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
        itemBankId = Integer.parseInt(getParameter("itembankid"));
        itemMoveMonitorId = getParameter("itemmoveid");
        readFilterParameters();
        if (itemBankId != null) {
            ItemBank itemBank = itemBankServices.findItemBank(itemBankId);
            orgName = itemBank.getOrganization().getOrgName();
            itemBankExternalId = itemBank.getExternalId();
        }
        detailStatusType = contentMoveService.findAllItemDetailStatusTypes();
        if (CollectionUtils.isNotEmpty(detailStatusType)) {
            for (DetailStatusType detailStatus : detailStatusType) {
                statusTypeMap.put(detailStatus.getType(),
                        detailStatus.getType());
            }
        }
    }

    private void readFilterParameters() {
        selectOrganizationId = getParameter("org");
        selectedItemBank = getParameter("item");
        searchSourceText = getParameter("source");
        searchDestinationText = getParameter("dest");
        searchFileText = getParameter("file");
        selectedMoveType = getParameter("mtype");
        selectedStatus = getParameter("status");
        selectedUser = getParameter("user");
        userName = getParameter("userName");
    }

    public String redirectToMonitor() {
        StringBuilder sbRedirectString = new StringBuilder(
                "ContentMonitor.jsf?faces-redirect=true");
        sbRedirectString.append("&userName=").append(this.userName);
        sbRedirectString.append("&org=").append(this.selectedOrganization);
        sbRedirectString.append("&item=").append(this.selectedItemBank);
        sbRedirectString.append("&mtype=").append(this.selectedMoveType);
        sbRedirectString.append("&user=").append(this.selectedUser);
        sbRedirectString.append("&status=").append(this.selectedStatus);
        sbRedirectString.append("&dest=").append(this.searchDestinationText);
        sbRedirectString.append("&source=").append(this.searchSourceText);
        sbRedirectString.append("&file=").append(this.searchFileText);

        return sbRedirectString.toString();

    }

    public List<ItemMoveDetails> getItemMoveDetails() {
        if (StringUtils.isNotEmpty(itemMoveMonitorId)) {
            unfilteredItemMoveDetails = itemMoveDetails = contentMoveService
                    .findItemMoveDetailsByItemMoveMonitorId(Long
                            .parseLong(itemMoveMonitorId));
        }
        if (CollectionUtils.isNotEmpty(itemMoveDetails)) {
            filter();
            sort();
        }
        return itemMoveDetails != null ? itemMoveDetails : Collections
                .<ItemMoveDetails> emptyList();
    }

    public List<ItemDetailStatus> getAllItemDetailStatus() {
        if (StringUtils.isNotEmpty(itemMoveMonitorId)) {
            itemMoveDetails = contentMoveService
                    .findItemMoveDetailsByItemMoveMonitorId(Long
                            .parseLong(itemMoveMonitorId));
            if (CollectionUtils.isNotEmpty(itemMoveDetails)) {
                itemDetailStatus = new ArrayList<ItemDetailStatus>();
                for (ItemMoveDetails itemMoveDetail : itemMoveDetails) {
                    if (CollectionUtils.isNotEmpty(itemMoveDetail
                            .getItemDetailStatus())) {
                        for (ItemDetailStatus detailStatus : itemMoveDetail
                                .getItemDetailStatus()) {
                            detailStatus.setExternalId(itemMoveDetail
                                    .getItemNameAsString());
                            itemDetailStatus.add(detailStatus);
                        }
                    }
                }
            }
        }
        if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
            unfilteredItemDetailStatus = itemDetailStatus;
            filter();
            sort();
            totalRows = itemDetailStatus.size();
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
        
        return itemDetailStatus != null ? itemDetailStatus : Collections
                .<ItemDetailStatus> emptyList();
    }

    private void filter() {
        if (StringUtils.isEmpty(searchedItemNameText)
                && StringUtils.isEmpty(selectedStatusType)
                && StringUtils.isEmpty(searchDetailStatusText)
                && StringUtils.isEmpty(selectedStatusCode)) {
            clearFilter();
            return;
        }
        if (StringUtils.isNotEmpty(searchedItemNameText)
                || StringUtils.isNotEmpty(selectedStatusType)
                || StringUtils.isNotEmpty(searchDetailStatusText)
                || StringUtils.isNotEmpty(selectedStatusCode)) {
            List<ItemDetailStatus> filteredItemDetailStatus = new ArrayList<ItemDetailStatus>();
            if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
                for (ItemDetailStatus detailStatus : itemDetailStatus) {
                    boolean detailEligible = true;
                    if (StringUtils.isNotEmpty(searchedItemNameText)
                            && !StringUtils.containsIgnoreCase(
                                    detailStatus.getExternalId(),
                                    searchedItemNameText)) {
                        detailEligible = false;
                        continue;
                    }
                    if (StringUtils.isNotEmpty(selectedStatusType)
                            && !StringUtils.containsIgnoreCase(
                                    detailStatus.getStatusTypeAsString(),
                                    selectedStatusType)) {
                        detailEligible = false;
                    }
                    if (StringUtils.isNotEmpty(searchDetailStatusText)
                            && !StringUtils.containsIgnoreCase(
                                    detailStatus.getStatusDetail(),
                                    searchDetailStatusText)) {
                        detailEligible = false;
                    }
                    if (StringUtils.isNotEmpty(selectedStatusCode)
                            && !StringUtils.equalsIgnoreCase(
                                    detailStatus.getStatusCodeAsString(),
                                    selectedStatusCode)) {
                        detailEligible = false;
                    }
                    if (detailEligible) {
                        filteredItemDetailStatus.add(detailStatus);
                    }
                }
            }
            itemDetailStatus = filteredItemDetailStatus;
        }
    }

    private void sort() {
        Comparator<ItemDetailStatus> comparator = new Comparator<ItemDetailStatus>() {

            @Override
            public int compare(ItemDetailStatus row1, ItemDetailStatus row2) {
                if (sortField == null) {
                    return 0;
                }
                if ("name".equals(sortField)) {
                    return sortAscending ? row1.getExternalId().compareTo(
                            row2.getExternalId()) : row2.getExternalId()
                            .compareTo(row1.getExternalId());
                }
                if ("type".equals(sortField)) {
                    return sortAscending ? row1.getStatusTypeAsString().compareTo(
                            row2.getStatusTypeAsString()) : row2
                            .getStatusTypeAsString().compareTo(
                                    row1.getStatusTypeAsString());
                }
                if ("code".equals(sortField)) {
                    return sortAscending ? row1.getStatusCodeAsString().compareTo(
                            row2.getStatusCodeAsString()) : row2
                            .getStatusCodeAsString().compareTo(
                                    row1.getStatusCodeAsString());
                }
                if ("status".equals(sortField)) {
                    return sortAscending ? row1.getStatusDetail().compareTo(
                            row2.getStatusDetail()) : row2.getStatusDetail()
                            .compareTo(row1.getStatusDetail());
                }
                return 0;
            }
        };
        List<ItemDetailStatus> statusDetails = new ArrayList<ItemDetailStatus>();
        if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
            for (ItemDetailStatus detailStatus : itemDetailStatus) {
                statusDetails.add(detailStatus);
            }
            Collections.sort(statusDetails, comparator);
            itemDetailStatus = statusDetails;
        }
    }

    public void scrollerAction() {
        // Do nothing because of X and Y.
    }

    private void clear() {
        searchedItemNameText = null;
        selectedStatusType = null;
        searchDetailStatusText = null;
        selectedStatusCode = null;
    }

    public void clearFilter() {
        clear();
        itemDetailStatus = unfilteredItemDetailStatus;
        setFirstRowIndex(0);
    }

    public void doFilter() {
        filter();
    }

    public void exportToCSV() {
        try {
            FacesContext context = FacesContext.getCurrentInstance();

            HttpServletResponse response = (HttpServletResponse) context
                    .getExternalContext().getResponse();

            String fileName = orgName + "-" + itemBankExternalId + "-"
                    + DATE_FORMAT.format(new Date()) + ".csv";
            response.reset();
            response.setHeader("Content-Type", "plain/text");
            response.setHeader("Content-Disposition", "attachment; filename="
                    + fileName);

            OutputStream outputStream = response.getOutputStream();

            StringBuilder csvBuffer = new StringBuilder();
            if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
                csvBuffer.append("Affected Item ID");
                csvBuffer.append(toCSVString());
            }
            outputStream.write(csvBuffer.toString().getBytes());
            outputStream.flush();
            outputStream.close();
            context.responseComplete();

        } catch (IOException e) {
            LOGGER.log(
                    Level.SEVERE,
                    "Unable to complete output stream for the csv file of ContentMonitor ",
                    e);
        } catch (Exception e) {
            LOGGER.log(Level.SEVERE,
                    "Unable to produce the csv file of ContentMonitor ", e);
        }
    }

    private String toCSVString() {
        StringBuilder csvBuffer = new StringBuilder();
        Set<String> externalIds = new HashSet<String>();
        if (CollectionUtils.isNotEmpty(itemDetailStatus)) {
            for (ItemDetailStatus detailStatus : itemDetailStatus) {
                if (!externalIds.contains(detailStatus.getExternalId())) {
                    csvBuffer.append(System.getProperty("line.separator"));
                    csvBuffer.append(detailStatus.getExternalId());
                    externalIds.add(detailStatus.getExternalId());
                }
            }
        }
        return csvBuffer.toString();
    }

    public ContentMoveServices getContentMoveService() {
        return contentMoveService;
    }

    public void setContentMoveService(ContentMoveServices contentMoveService) {
        this.contentMoveService = contentMoveService;
    }

    public String getItemMoveMonitorId() {
        return itemMoveMonitorId;
    }

    public void setItemMoveMonitorId(String itemMoveMonitorId) {
        this.itemMoveMonitorId = itemMoveMonitorId;
    }

    public String getSelectedOrganization() {
        return selectedOrganization;
    }

    public void setSelectedOrganization(String selectedOrganization) {
        this.selectedOrganization = selectedOrganization;
    }

    public String getSelectedItemBank() {
        return selectedItemBank;
    }

    public void setSelectedItemBank(String selectedItemBank) {
        this.selectedItemBank = selectedItemBank;
    }

    public void setItemMoveDetails(List<ItemMoveDetails> itemMoveDetails) {
        this.itemMoveDetails = itemMoveDetails;
    }

    public ItemBankServices getItemBankServices() {
        return itemBankServices;
    }

    public void setItemBankServices(ItemBankServices itemBankServices) {
        this.itemBankServices = itemBankServices;
    }

    public Integer getItemBankId() {
        return itemBankId;
    }

    public void setItemBankId(Integer itemBankId) {
        this.itemBankId = itemBankId;
    }

    public int getFirstRowIndex() {
        return firstRowIndex;
    }

    public void setFirstRowIndex(int firstRowIndex) {
        this.firstRowIndex = firstRowIndex;
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

    public List<DetailStatusType> getDetailStatusType() {
        return detailStatusType;
    }

    public void setDetailStatusType(List<DetailStatusType> detailStatusType) {
        this.detailStatusType = detailStatusType;
    }

    public String getSearchedItemNameText() {
        return searchedItemNameText;
    }

    public void setSearchedItemNameText(String searchedItemNameText) {
        this.searchedItemNameText = searchedItemNameText;
    }

    public String getSelectedStatusType() {
        return selectedStatusType;
    }

    public void setSelectedStatusType(String selectedStatusType) {
        this.selectedStatusType = selectedStatusType;
    }

    public String getSearchDetailStatusText() {
        return searchDetailStatusText;
    }

    public void setSearchDetailStatusText(String searchDetailStatusText) {
        this.searchDetailStatusText = searchDetailStatusText;
    }

    public String getSelectedStatusCode() {
        return selectedStatusCode;
    }

    public void setSelectedStatusCode(String selectedStatusCode) {
        this.selectedStatusCode = selectedStatusCode;
    }

    public List<ItemMoveDetails> getUnfilteredItemMoveDetails() {
        return unfilteredItemMoveDetails;
    }

    public void setUnfilteredItemMoveDetails(
            List<ItemMoveDetails> unfilteredItemMoveDetails) {
        this.unfilteredItemMoveDetails = unfilteredItemMoveDetails;
    }

    public String getSearchSourceText() {
        return searchSourceText;
    }

    public void setSearchSourceText(String searchSourceText) {
        this.searchSourceText = searchSourceText;
    }

    public String getSearchFileText() {
        return searchFileText;
    }

    public void setSearchFileText(String searchFileText) {
        this.searchFileText = searchFileText;
    }

    public String getSearchDestinationText() {
        return searchDestinationText;
    }

    public void setSearchDestinationText(String searchDestinationText) {
        this.searchDestinationText = searchDestinationText;
    }

    public String getSelectedMoveType() {
        return selectedMoveType;
    }

    public void setSelectedMoveType(String selectedMoveType) {
        this.selectedMoveType = selectedMoveType;
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

    public String getSelectOrganizationId() {
        return selectOrganizationId;
    }

    public void setSelectOrganizationId(String selectOrganizationId) {
        this.selectOrganizationId = selectOrganizationId;
    }

    public List<ItemDetailStatus> getItemDetailStatus() {
        return itemDetailStatus;
    }

    public void setItemDetailStatus(List<ItemDetailStatus> itemDetailStatus) {
        this.itemDetailStatus = itemDetailStatus;
    }

    public List<ItemDetailStatus> getUnfilteredItemDetailStatus() {
        return unfilteredItemDetailStatus;
    }

    public void setUnfilteredItemDetailStatus(
            List<ItemDetailStatus> unfilteredItemDetailStatus) {
        this.unfilteredItemDetailStatus = unfilteredItemDetailStatus;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public Map<String, String> getStatusTypeMap() {
        return statusTypeMap;
    }

    public void setStatusTypeList(Map<String, String> statusTypeMap) {
        this.statusTypeMap = statusTypeMap;
    }

	/**
	 * @return the firstRow
	 */
	public int getFirstRow() {
		return firstRow;
	}

	/**
	 * @param firstRow the firstRow to set
	 */
	public void setFirstRow(int firstRow) {
		this.firstRow = firstRow;
	}

	/**
	 * @return the rowsPerPage
	 */
	public int getRowsPerPage() {
		return rowsPerPage;
	}

	/**
	 * @param rowsPerPage the rowsPerPage to set
	 */
	public void setRowsPerPage(int rowsPerPage) {
		this.rowsPerPage = rowsPerPage;
	}

	/**
	 * @return the totalPages
	 */
	public int getTotalPages() {
		return totalPages;
	}

	/**
	 * @param totalPages the totalPages to set
	 */
	public void setTotalPages(int totalPages) {
		this.totalPages = totalPages;
	}

	/**
	 * @return the pageRange
	 */
	public int getPageRange() {
		return pageRange;
	}

	/**
	 * @param pageRange the pageRange to set
	 */
	public void setPageRange(int pageRange) {
		this.pageRange = pageRange;
	}

	/**
	 * @return the pages
	 */
	public Integer[] getPages() {
		return pages;
	}

	/**
	 * @param pages the pages to set
	 */
	public void setPages(Integer[] pages) {
		this.pages = pages;
	}

	/**
	 * @return the currentPage
	 */
	public int getCurrentPage() {
		return currentPage;
	}

	/**
	 * @param currentPage the currentPage to set
	 */
	public void setCurrentPage(int currentPage) {
		this.currentPage = currentPage;
	}

	/**
	 * @return the totalRows
	 */
	public int getTotalRows() {
		return totalRows;
	}

	/**
	 * @param totalRows the totalRows to set
	 */
	public void setTotalRows(int totalRows) {
		this.totalRows = totalRows;
	}
    
    

}
