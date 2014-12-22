package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;
import java.util.LinkedList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;


import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ManagedBean;
import javax.faces.bean.ViewScoped;

import com.pacificmetrics.orca.ejb.PubHistoryServices;


/**
 * 
 * 
 * 
 * @author Hemant
 */
@ManagedBean(name = "pubHistory")
@ViewScoped
public class ItemPubHistoryManager extends AbstractManager implements
		Serializable {



	private static final long serialVersionUID = 1L;
	@EJB
	PubHistoryServices pubHitoryServices;
	
	Map<Integer,String> adminMap;
	List<Map<String,String>>statKeyValue=new LinkedList<Map<String,String>>();
	Map<String,String>temp=null;
	
	boolean prevSelect=false;
	boolean nextSelect=false;
	
	
	public boolean isPrevSelect() {
		return prevSelect;
	}


	public void setPrevSelect(boolean prevSelect) {
		this.prevSelect = prevSelect;
	}


	public boolean isNextSelect() {
		return nextSelect;
	}


	public void setNextSelect(boolean nextSelect) {
		this.nextSelect = nextSelect;
	}


	public List<Map<String, String>> getStatKeyValue() {
		return statKeyValue;
	}


	public void setStatKeyValue(List<Map<String, String>> statKeyValue) {
		this.statKeyValue = statKeyValue;
	}


	public Map<String, String> getTemp() {
		return temp;
	}


	public void setTemp(Map<String, String> temp) {
		this.temp = temp;
	}


	public PubHistoryServices getPubHitoryServices() {
		return pubHitoryServices;
	}


	public void setPubHitoryServices(PubHistoryServices pubHitoryServices) {
		this.pubHitoryServices = pubHitoryServices;
	}


	public Map<Integer, String> getAdminMap() {
		return adminMap;
	}


	public void setAdminMap(Map<Integer, String> adminMap) {
		this.adminMap = adminMap;
	}
  

	@PostConstruct
	public void load(){
		
		adminMap=pubHitoryServices.getAdminAndExternalID(getParameter("itemId"));
		
		for(Integer statvalue : adminMap.keySet()){
			
			statKeyValue.add(pubHitoryServices.getStatKeyAndValuePair(statvalue,getParameter("itemId")));
		}
		if(statKeyValue.isEmpty()){
			temp=new HashMap<String, String>();
		} else {
			if(statKeyValue.size()>1){
				nextSelect=true;
			}
			temp=statKeyValue.get(0);
		}
	
	}
	
	int current=0;
	public String prevNavigation(){
	temp=statKeyValue.get(--current);
	
	if(current==0){
		prevSelect=false;
	}else{
		prevSelect=true;
	}
	if(current < statKeyValue.size()-1){
		nextSelect=true;
	}else{
		nextSelect=false;
	}
	return "";
}

public String nextNavigation(){
	
	temp=statKeyValue.get(++current);
	
	if(statKeyValue.size()-1==current){
		nextSelect=false;
	} else {
		nextSelect=true;
	}
	if(current > 0){
		prevSelect=true;
	}else{
		prevSelect=false;
	}
	
	return "";
}
	
}
