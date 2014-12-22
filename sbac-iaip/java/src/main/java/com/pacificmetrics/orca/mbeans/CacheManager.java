package com.pacificmetrics.orca.mbeans;

import java.io.Serializable;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.faces.bean.ApplicationScoped;
import javax.faces.bean.ManagedBean;

import com.pacificmetrics.orca.cache.HierarchyCache;
import com.pacificmetrics.orca.cache.LookupCache;
import com.pacificmetrics.orca.ejb.CacheServices;
import com.pacificmetrics.orca.ejb.HierarchyServices;
import com.pacificmetrics.orca.ejb.MiscServices;

/**
 * Application-scoped managed bean, pre-loaded at app's startup to keep
 * references to cache objects used throughout the application
 * 
 * @author amiliteev
 * 
 */

@ManagedBean(name = "cache", eager = true)
@ApplicationScoped
public class CacheManager implements Serializable {

    private static final long serialVersionUID = 1L;

    @EJB
    private CacheServices cacheServices;

    @EJB
    private HierarchyServices hierarchyServices;

    @EJB
    private MiscServices miscServices;

    private HierarchyCache hierarchyCache;
    private LookupCache lookupCache;

    public CacheManager() {
    }

    /**
     * In this method all cache objects should be instantiated
     * 
     */
    @PostConstruct
    public void load() {
        hierarchyCache = new HierarchyCache(hierarchyServices);
        lookupCache = new LookupCache(miscServices);
    }

    public synchronized HierarchyCache getHierarchyCache() {
        hierarchyCache.validate(cacheServices);
        return hierarchyCache;
    }

    public LookupCache getLookupCache() {
        return lookupCache;
    }

}
