package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Cacheable;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

import org.apache.openjpa.persistence.DataCache;

/**
 * This entity is for mapping table used to store mapping association for the value 
 * obtained from metadata XML with field with corresponding object table (item/passage) field 
 * or entry in corresponding 'characterization' table; 
 * JXPath is used to specify path in the metadata XML bean  
 * 
 * @author amiliteev
 *
 */
@Entity
@Table(name="metadata_mapping")
@Cacheable(true)
@DataCache(timeout=3600000) 
@NamedQueries({
    @NamedQuery(name="allMetadataMapping", 
            query="select mm from MetadataMapping mm"),               
    @NamedQuery(name="mmByObjectType", 
            query="select mm from MetadataMapping mm where mm.objectType = :mm_object_type")               
})
public class MetadataMapping implements Serializable {

    private static final long serialVersionUID = 1L;
    
    static public final int OT_ITEM = 4;
    static public final int OT_PASSAGE = 7;
    
    @Id
    @Column(name="mm_id")
    private int id;
    
    /**
     * Object type code that determines mapping tables. Currently supported OT_ITEM and OT_PASSAGE
     */
    @Basic
    @Column(name="mm_object_type")
    private int objectType;
    
    /**
     * XPath specifies path to the value(s) in metadata XML  
     */
    @Basic
    @Column(name="mm_xpath")
    private String xPath;
    
    /**
     * If the data is to be persisted in object table itself, this field is used to specify field name
     */
    @Basic
    @Column(name="mm_field_name")
    private String fieldName;
    
    /**
     * If entry must be made in 'characterization' table, this field is used to specify characterization code for the entry (custom codes must start from 100)
     */
    @Basic
    @Column(name="mm_characteristic")
    private int characteristic;
    
    /**
     * If numeric value must be looked up for the value obtained from metadata XML, this field is used to specify database table name
     */
    @Basic
    @Column(name="mm_lookup_table_name")
    private String lookupTableName;
    
    /**
     * If numeric value must be looked up for the value obtained from metadata XML, this field is used to specify optional prefix; 
     * if prefix is specified, the value that will be searched for will contain from prefix and value obtained from metadata XML
     */
    @Basic
    @Column(name="mm_lookup_prefix")
    private String lookupPrefix;
    
    /**
     * If numeric value must be looked up for the value obtained from metadata XML, this field is used to specify field name of the table;
     * This field will be searched for the value obtained from metadata XML
     */
    @Basic
    @Column(name="mm_lookup_by_field")
    private String lookupByField;
    
    /**
     * If numeric value must be looked up for the value obtained from metadata XML, this field is used to specify field name of the table;
     * This field (must be numeric) will be selected to obtain lookup code
     */
    @Basic
    @Column(name="mm_lookup_value_field")
    private String lookupValueField;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getObjectType() {
        return objectType;
    }

    public void setObjectType(int objectType) {
        this.objectType = objectType;
    }

    public String getxPath() {
        return xPath;
    }

    public void setxPath(String xPath) {
        this.xPath = xPath;
    }

    public String getFieldName() {
        return fieldName;
    }

    public void setFieldName(String fieldName) {
        this.fieldName = fieldName;
    }

    public int getCharacteristic() {
        return characteristic;
    }

    public void setCharacteristic(int characteristic) {
        this.characteristic = characteristic;
    }

    public String getLookupTableName() {
        return lookupTableName;
    }

    public void setLookupTableName(String lookupTableName) {
        this.lookupTableName = lookupTableName;
    }

    public String getLookupByField() {
        return lookupByField;
    }

    public void setLookupByField(String lookupByField) {
        this.lookupByField = lookupByField;
    }

    public String getLookupValueField() {
        return lookupValueField;
    }

    public void setLookupValueField(String lookupValueField) {
        this.lookupValueField = lookupValueField;
    }

    public String getLookupPrefix() {
        return lookupPrefix;
    }

    public void setLookupPrefix(String lookupPrefix) {
        this.lookupPrefix = lookupPrefix;
    }

}
