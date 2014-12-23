package com.pacificmetrics.orca.entities;

import java.io.Serializable;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.Id;
import javax.persistence.IdClass;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.Table;

@Entity
@IdClass(UserPermissionPK.class)
@Table(name="user_permission")
@NamedQueries({
	@NamedQuery(name="permissionByUserId", 
		    query="select up from UserPermission up where up.userId = :user_id")
})

public class UserPermission implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="u_id")
	private int userId;
	
	@Id
	@Column(name="up_type")
	private int type;
	
	@Id
	@Column(name="up_value")
	private int value;
	
	public int getUserId() {
		return userId;
	}

	public void setUserId(int userId) {
		this.userId = userId;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int getValue() {
		return value;
	}

	public void setValue(int value) {
		this.value = value;
	}

}
