package com.pacificmetrics.orca.entities;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

import javax.persistence.Basic;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.NamedQueries;
import javax.persistence.NamedQuery;
import javax.persistence.OneToMany;
import javax.persistence.OneToOne;
import javax.persistence.Table;

@Entity
@Table(name="user")
@NamedQueries({
    @NamedQuery(name="getUserByUserName", query="select u from User u where u.userName=:userName")
    })  
public class User implements Serializable {

	private static final long serialVersionUID = 1L;

	@Id
	@Column(name="u_id")
	private int id;
	
	@Basic
	@Column(name="u_username")
	private String userName;
	
	@OneToMany(fetch=FetchType.EAGER)
	@JoinColumn(name="u_id")
	private List<UserPermission> userPermissions;
	
	@OneToOne
    @JoinColumn(name="o_id")
    private Organization organization;
	
	public String getUserName() {
		return userName;
	}

	public void setUserName(String userName) {
		this.userName = userName;
	}

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public List<UserPermission> getUserPermissions() {
		return userPermissions;
	}

	public void setUserPermissions(List<UserPermission> userPermissions) {
		this.userPermissions = userPermissions;
	}
	
	public List<UserPermission> findUserPermissions(int type) {
		if (getUserPermissions() == null) {
			return Collections.emptyList();
		}
		List<UserPermission> result = new ArrayList<UserPermission>();
		for (UserPermission permission: getUserPermissions()) {
			if (permission.getType() == type) {
				result.add(permission);
			}
		}
		return result;
		
	}
	
	public String asText() {
		return userName;
	}

	/**
	 * @return the organization
	 */
	public Organization getOrganization() {
		return organization;
	}

	/**
	 * @param organization the organization to set
	 */
	public void setOrganization(Organization organization) {
		this.organization = organization;
	}

}
