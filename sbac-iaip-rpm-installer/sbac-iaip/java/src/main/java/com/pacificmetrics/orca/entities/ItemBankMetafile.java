package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.sql.Timestamp;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.SortedMap;
import java.util.TreeMap;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.IdClass;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

import org.apache.commons.lang.StringUtils;

@Entity
@IdClass(ItemBankMetafilePK.class)
@Table(name="item_bank_metafiles")
@NamedQueries({
	@NamedQuery(name="metafilesByBankIdAndName", 
		    query="select ibm from ItemBankMetafile ibm where ibm.itemBankId = :ib_id and ibm.originalFileName = :file_name"), 
	@NamedQuery(name="metafilesByBankIdLastVersion", 
			query="select ibm from ItemBankMetafile ibm" +
				  "(select ibm2.id, max(version) as max_version from ItemBankMetafile ibm2 group by ibm2.id) ibm3 " +
				  "ON ibm.id = ibm3.id and ibm.version = ibm3.max_version and ibm.itemBankId = :ib_id group by ibm.timestamp desc"), 
	@NamedQuery(name="metafilesByIdOrderByVersionDesc", 
			query="select ibm from ItemBankMetafile ibm where ibm.id = :id order by ibm.version desc"), 
	@NamedQuery(name="maxId", 
			query="select max(ibm.id) from ItemBankMetafile ibm") 
})
public class ItemBankMetafile implements Serializable {

	private static final long serialVersionUID = 1L;
	
	private static final DateFormat DATE_FORMAT = new SimpleDateFormat("MM/dd/yyyy HH:mm");
	
	static public final int TC_ITEM_SPEC = 1;
	static public final int TC_PASSAGE_SPEC = 2;
	static public final int TC_COPYRIGHT_DRM = 3;
	static public final int TC_OTHER = 4;
	
	static public final String[] TYPES_AS_STRING = new String[] {"Item Specification", "Passage Specification", "Copyright/DRM", "Other"};
	static public final SortedMap<Integer, String> TYPES_MAP = new TreeMap<Integer, String>(); 
	
	static {
		synchronized (ItemBankMetafile.class) {
			for (int i = 0; i < TYPES_AS_STRING.length; i++) {
				TYPES_MAP.put(i + 1, TYPES_AS_STRING[i]);
			}
		}
	}
	
	@Id
	@Column(name="ibm_id")
	private int id;
	
	@Id
	@Column(name="ibm_version")
	private int version;
	
	@Basic
	@Column(name="ib_id")
	private int itemBankId;

	@Basic
	@Column(name="ibm_comment")
	private String comment;

	@Basic
	@Column(name="ibm_orig_name")
	private String originalFileName;

	@Basic
	@Column(name="ibm_system_name")
	private String systemName;

	@Basic
	@Column(name="ibm_type")
	private String fileType;

	@Basic
	@Column(name="ibm_timestamp")
	private Timestamp timestamp;
	
	@Basic
	@Column(name="ibm_type_code")
	private int typeCode;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getComment() {
		return comment;
	}

	public void setComment(String comment) {
		this.comment = comment;
	}

	public String getOriginalFileName() {
		return originalFileName;
	}

	public void setOriginalFileName(String originalFileName) {
		this.originalFileName = originalFileName;
	}
	
	@Override
	public String toString() {
		return "" + id;
	}

	public String getSystemName() {
		return systemName;
	}

	public void setSystemName(String systemName) {
		this.systemName = systemName;
	}

	public String getFileType() {
		return fileType;
	}

	public void setFileType(String fileType) {
		this.fileType = StringUtils.left(fileType, 50);
	}

	public int getVersion() {
		return version;
	}

	public void setVersion(int version) {
		this.version = version;
	}

	public Timestamp getTimestamp() {
		return timestamp;
	}

	public void setTimestamp(Timestamp timestamp) {
		this.timestamp = timestamp;
	}

	public int getItemBankId() {
		return itemBankId;
	}

	public void setItemBankId(int itemBankId) {
		this.itemBankId = itemBankId;
	}
	
	public String getTimestampAsString() {
		return getTimestamp() != null ? DATE_FORMAT.format(getTimestamp()) : ""; 
	}

	public int getTypeCode() {
		return typeCode;
	}

	public String getTypeAsString() {
		return getTypeAsString(typeCode);
	}

	public void setTypeCode(int typeCode) {
		this.typeCode = typeCode;
	}
	
	static public String getTypeAsString(int typeCode) {
		return typeCode > 0 ? TYPES_AS_STRING[typeCode - 1] : "";
	}
	
}
