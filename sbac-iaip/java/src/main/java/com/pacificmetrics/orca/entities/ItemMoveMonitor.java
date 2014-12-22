package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.List;

import javax.persistence.Basic;
import javax.persistence.CascadeType;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;

/**
 * 
 * Basic entity class for the item move monitor object.
 * @author arindam.majumdar
 * 
 */

@Entity
@NamedQuery(name="ItemMoveMonitor.deleteById", query="delete from ItemMoveMonitor imm where imm.id = :id")
@Table(name = "item_move_monitor")
public class ItemMoveMonitor implements Serializable {
	
	private static final long serialVersionUID = 1L;
	
	private static final DateFormat DATE_FORMAT = new SimpleDateFormat("MM/dd/yyyy HH:mm");

	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
    @Column(name = "imm_id")
    private long id;

    @Basic
    @Column(name = "imm_src")
    private String source;
    
    @Basic
    @Column(name = "imm_dst")
    private String destination;
    
    @Basic
    @Column(name = "imm_file_name")
    private String fileName;
    
    @Basic
    @Column(name = "imm_timestamp")
    private Timestamp timeOfMove;
    
    @OneToOne
    @JoinColumn(name="ib_id")
    private ItemBank itemBank;
    
    @OneToOne
    @JoinColumn(name="u_id")
    private User user;
    
    @OneToOne
    @JoinColumn(name="imt_id")
    private ItemMoveType itemMoveType;
    
    @OneToOne
    @JoinColumn(name="ims_id")
    private ItemMoveStatus itemMoveStatus;
    
    @OneToMany(fetch = FetchType.EAGER, cascade = CascadeType.REMOVE)
    @JoinColumn(name = "imm_id")
    private List<ItemMoveDetails> itemMoveDetails;
    
    @OneToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ipf_id")
    private ItemPackageFormat itemPackageFormat;
    
    @Basic
    @Column(name = "error_status")
    private String errorStatus;
    
    public String getOrganizationAsString() {
    	if(itemBank != null && itemBank.getOrganization() != null) {
    		return itemBank.getOrganization().getOrgName();
    	}
    	return "";
    }
    
    public String getStatusAsString() {
    	if(itemMoveStatus != null) {
    		return itemMoveStatus.getStatus();
    	}
    	return "";
    }
    
    public String getMoveTypeAsString() {
    	if(itemMoveType != null) {
    		return itemMoveType.getName();
    	}
    	return "";
    }
    
    public String getUserNameAsString() {
    	if ( user != null ) { 
    		return user.getUserName();
    	}
    	return "";
    }
    
    public String getProgramAsString() {
    	if ( itemBank != null ) {
    		return itemBank.getExternalId();
    	}
    	return "";
    }
    
    public String getTimestampAsString() {
		return getTimeOfMove() != null ? DATE_FORMAT.format(getTimeOfMove()) : ""; 
	}
    
	/**
	 * @return the id
	 */
	public long getId() {
		return id;
	}

	/**
	 * @param id the id to set
	 */
	public void setId(long id) {
		this.id = id;
	}

	/**
	 * @return the source
	 */
	public String getSource() {
		return source;
	}

	/**
	 * @param source the source to set
	 */
	public void setSource(String source) {
		this.source = source;
	}

	/**
	 * @return the destination
	 */
	public String getDestination() {
		return destination;
	}

	/**
	 * @param destination the destination to set
	 */
	public void setDestination(String destination) {
		this.destination = destination;
	}

	/**
	 * @return the fileName
	 */
	public String getFileName() {
		return fileName;
	}

	/**
	 * @param fileName the fileName to set
	 */
	public void setFileName(String fileName) {
		this.fileName = fileName;
	}

	/**
	 * @return the timeOfMove
	 */
	public Timestamp getTimeOfMove() {
		return timeOfMove;
	}

	/**
	 * @param timeOfMove the timeOfMove to set
	 */
	public void setTimeOfMove(Timestamp timeOfMove) {
		this.timeOfMove = timeOfMove;
	}

	/**
	 * @return the itemBank
	 */
	public ItemBank getItemBank() {
		return itemBank;
	}

	/**
	 * @param itemBank the itemBank to set
	 */
	public void setItemBank(ItemBank itemBank) {
		this.itemBank = itemBank;
	}

	/**
	 * @return the user
	 */
	public User getUser() {
		return user;
	}

	/**
	 * @param user the user to set
	 */
	public void setUser(User user) {
		this.user = user;
	}

	/**
	 * @return the itemMoveType
	 */
	public ItemMoveType getItemMoveType() {
		return itemMoveType;
	}

	/**
	 * @param itemMoveType the itemMoveType to set
	 */
	public void setItemMoveType(ItemMoveType itemMoveType) {
		this.itemMoveType = itemMoveType;
	}

	/**
	 * @return the itemMoveStatus
	 */
	public ItemMoveStatus getItemMoveStatus() {
		return itemMoveStatus;
	}

	/**
	 * @param itemMoveStatus the itemMoveStatus to set
	 */
	public void setItemMoveStatus(ItemMoveStatus itemMoveStatus) {
		this.itemMoveStatus = itemMoveStatus;
	}

	/**
	 * @return the itemMoveDetails
	 */
	public List<ItemMoveDetails> getItemMoveDetails() {
		return itemMoveDetails;
	}

	/**
	 * @param itemMoveDetails the itemMoveDetails to set
	 */
	public void setItemMoveDetails(List<ItemMoveDetails> itemMoveDetails) {
		this.itemMoveDetails = itemMoveDetails;
	}

	/**
	 * @return the itemPackageFormat
	 */
	public ItemPackageFormat getItemPackageFormat() {
		return itemPackageFormat;
	}

	/**
	 * @param itemPackageFormat the itemPackageFormat to set
	 */
	public void setItemPackageFormat(ItemPackageFormat itemPackageFormat) {
		this.itemPackageFormat = itemPackageFormat;
	}

	public String getErrorStatus() {
		return errorStatus;
	}

	public void setErrorStatus(String errorStatus) {
		this.errorStatus = errorStatus;
	}
	
	
    
}
