/**
 * 
 */
package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

/**
 * Basic entity class for the detail status type object.
 * 
 * @author arindam.majumdar
 * 
 */

@Entity
@NamedQueries({
        @NamedQuery(name = "DetailStatusType.dataByName", query = "SELECT dst FROM DetailStatusType dst where dst.value = :value"),
        @NamedQuery(name = "DetailStatusType.maxId", query = "select max(dst.id) from DetailStatusType dst") })
@Table(name = "detail_status_type")
public class DetailStatusType implements Serializable {

    private static final long serialVersionUID = 1L;

    public DetailStatusType(long id, int code, String type, String value) {
        this.id = id;
        this.code = code;
        this.type = type;
        this.value = value;
    }

    public DetailStatusType() {
		// TODO Auto-generated constructor stub
	}

	@Id
    @Column(name = "dst_id")
    private long id;

    @Basic
    @Column(name = "dst_code")
    private int code;

    @Basic
    @Column(name = "dst_type")
    private String type;

    @Basic
    @Column(name = "dst_value")
    private String value;

    /**
     * @return the id
     */
    public long getId() {
        return id;
    }

    /**
     * @param id
     *            the id to set
     */
    public void setId(long id) {
        this.id = id;
    }

    /**
     * @return the code
     */
    public int getCode() {
        return code;
    }

    /**
     * @param code
     *            the code to set
     */
    public void setCode(int code) {
        this.code = code;
    }

    /**
     * @return the type
     */
    public String getType() {
        return type;
    }

    /**
     * @param type
     *            the type to set
     */
    public void setType(String type) {
        this.type = type;
    }

    /**
     * @return the value
     */
    public String getValue() {
        return value;
    }

    /**
     * @param value
     *            the value to set
     */
    public void setValue(String value) {
        this.value = value;
    }
}
