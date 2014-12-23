package com.pacificmetrics.orca.ejb;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.TreeMap;
import java.util.List;
import java.util.Map;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import org.apache.commons.lang.StringUtils;



@Stateless
@LocalBean
public class PubHistoryServices {
	@PersistenceContext(unitName="cde-unit", type=PersistenceContextType.TRANSACTION)
	EntityManager entityManager;
	
	public Map<Integer,String> getAdminAndExternalID(String itemId){
		
		String q="SELECT distinct sta.sa_id, itm.i_external_id FROM item as itm,stat_administration as sta,stat_item_value as siv where itm.i_id = siv.i_id and	siv.sa_id = sta.sa_id and itm.i_id = ?";
		Query query = entityManager
				.createNativeQuery(q);
		query.setParameter(1, itemId);
		
		List<Object[]>statList=query.getResultList();
		Map<Integer,String>statMap=new TreeMap<Integer, String>();
		
		for(Object[] row : statList){
		statMap.put((Integer)row[0], row[1].toString());
	
		}
		
      return statMap;
	}

	public Map<String,String> getStatKeyAndValuePair(Integer statvalue, String parameter) {
		

		String q="SELECT itm.i_external_id, sta.sa_id, stk.sk_name, siv_numeric_value FROM item as itm,stat_administration as sta,stat_item_value as siv,stat_key as stk where itm.i_id = siv.i_id and	siv.sa_id = sta.sa_id and siv.sk_id = stk.sk_id and itm.i_id = ? and sta.sa_id = ?";
		Query query = entityManager
				.createNativeQuery(q);
		query.setParameter(1, parameter);
		query.setParameter(2, statvalue);
		
		
		List<Object[]>statList=query.getResultList();
		Map<String,String>statPair=new TreeMap<String, String>();
		List<String> itemFlag=new ArrayList<String>();
		for(Object[] row : statList){
			if(row[2].toString().toLowerCase().startsWith("item_flag_") ){
			itemFlag.add(row[2].toString().toUpperCase().substring(row[2].toString().length()-1, row[2].toString().length()));	
			} else {
				statPair.put(row[2].toString().toLowerCase(), row[3]==null?null:row[3].toString());
			}
			}
		String iFlag=StringUtils.join(itemFlag, ",");
		statPair.put("administration", getAdminKey(statvalue));
		statPair.put("item_flag", iFlag);
		return statPair;
		
	}

	private String getAdminKey(Integer statvalue) {
		String q="SELECT sta.sa_administration FROM stat_administration as sta where sta.sa_id  = ?";
		Query query = entityManager
				.createNativeQuery(q);
		query.setParameter(1, statvalue);
		String adminKey=query.getSingleResult().toString();
		return adminKey;
	}

}
