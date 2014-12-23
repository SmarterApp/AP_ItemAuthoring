package com.pacificmetrics.orca.cache;

import java.util.HashMap;
import java.util.Map;

import com.pacificmetrics.orca.ejb.MiscServices;

/**
 * This class is used to retrieve lookup code from the database table and cache it for future use. 
 *  
 * @author amiliteev
 *
 */
public class LookupCache {
    
    private Map<String, Integer> map = new HashMap<String, Integer>();
    
    private MiscServices miscServices;

    public LookupCache(MiscServices miscServices) {
        this.miscServices = miscServices;
    }
    
    /**
     * This method is used to obtain the numeric value retrieved from given field of the given database table,
     * Lookup must be performed using given field and its value (with optional prefix)
     * If the value doesn't exist in cache, the call to MiscServices is made to retrieve the value and store it in cache
     * Method is synchronized to avoid multiple threads simultaneously modifying underlying map
     * 
     * @param tableName
     * @param lookupByField
     * @param lookupPrefix
     * @param lookupValueField
     * @param value
     * @return
     */
    public synchronized Integer getLookupCode(String tableName, String lookupByField, String lookupPrefix, String lookupValueField, String value) {
        String key = tableName + ":" + lookupByField + ":" + (lookupPrefix != null ? lookupPrefix : "") + lookupValueField + ":" + value;
        Integer result = map.get(key);
        if (result == null) {
            result = miscServices.getLookupCode(tableName, lookupByField, lookupPrefix, lookupValueField, value);
            if (result == null) {
                //If the lookup code not found, we'll store Integer.MIN_VALUE in the map to avoid same query repeated multiple times 
                result = Integer.MIN_VALUE;
            }
            map.put(key, result);
        }
        //If Integer.MIN_VALUE is associated with the key, this method returns null
        return result != Integer.MIN_VALUE ? result : null;
    }
    
}
