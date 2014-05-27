package com.pacificmetrics.orca.cache;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import org.apache.commons.lang.StringEscapeUtils;

import com.pacificmetrics.orca.ejb.HierarchyServices;
import com.pacificmetrics.orca.entities.Hierarchy;

public class HierarchyCache extends AbstractCache<Integer, String> {

    static private Logger logger = Logger.getLogger(HierarchyCache.class.getName());
    
    static private final String HIERARCHY_DEFINITION = "hierarchy_definition";
    
    private HierarchyServices hierarchyServices;
    
    public HierarchyCache(HierarchyServices hierarchyServices) {
        this.hierarchyServices = hierarchyServices;
    }

    @Override
    protected void load() {
        load(hierarchyServices.getAllHierarchies());
    }
    
    private void load(List<Hierarchy> list) {
        map.clear();
        Map<Integer, Hierarchy> hierarchyMap = new HashMap<Integer, Hierarchy>();
        for (Hierarchy h: list) {
            hierarchyMap.put(h.getId(), h);
        }
        for (Map.Entry<Integer, Hierarchy> entry: hierarchyMap.entrySet()) {
            map.put(entry.getKey(), getHierarchyAsString(entry.getKey(), hierarchyMap));
        }
    }
    
    static private String getHierarchyAsString(int id, Map<Integer, Hierarchy> hierarchyMap) {
        String result = "";
        Hierarchy hierarchy = hierarchyMap.get(id);
        if (hierarchy != null) {
            if (hierarchy.getParentId() != 0) {
                result = getHierarchyAsString(hierarchy.getParentId(), hierarchyMap);
            }
            result += " /" + StringEscapeUtils.unescapeHtml(hierarchy.getName());
        } else {
            logger.warning("Hierarchy not found for id = " + id);
        }
        return result;
    }

    @Override
    protected String getTableName() {
        return HIERARCHY_DEFINITION;
    }
    
}
