package com.pacificmetrics.orca.cache;

import java.sql.Timestamp;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Logger;

import com.pacificmetrics.orca.ejb.CacheServices;

public abstract class AbstractCache<K, V> {
    
	private static final Logger LOGGER = Logger.getLogger(AbstractCache.class.getName()); 

    protected Map<K, V> map = new HashMap<K, V>();
    protected Timestamp lastModificationTime;
    /**
     * If this field is false, the validate method will not check for last modification time for the underlying database table,
     * i.e. cache is static and never refreshes
     */
    protected boolean checkModificationTime = false;

    public AbstractCache() {
    }
    
    public AbstractCache(boolean checkModificationTime) {
        this.checkModificationTime = checkModificationTime;
    }
    
    public V get(K key) {
        return map.get(key);
    }
    
    protected abstract void load();
    
    protected abstract String getTableName();
    
    public void validate(CacheServices cacheServices) {
        Timestamp newLastModificationTime = null;
        if (checkModificationTime) {
            newLastModificationTime = cacheServices.getLastModificationTime(getTableName());
            if (newLastModificationTime == null) {
                LOGGER.warning("No last modification time for: " + getTableName());
            }
        } else {
            newLastModificationTime = new Timestamp(System.currentTimeMillis());
        }
        if (lastModificationTime == null || newLastModificationTime == null || newLastModificationTime.after(lastModificationTime)) {
            LOGGER.info("Reloading cache for: " + getTableName());
            load();
        } 
        lastModificationTime = newLastModificationTime;
    }
    
}
