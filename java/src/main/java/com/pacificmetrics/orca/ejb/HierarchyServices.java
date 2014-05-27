package com.pacificmetrics.orca.ejb;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.orca.entities.Hierarchy;

@Stateless
@LocalBean
public class HierarchyServices {
	
	@PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;

	private Map<Integer, Hierarchy> hierarchyMap = new HashMap<Integer, Hierarchy>();
	
	@SuppressWarnings("unchecked")
    public List<Hierarchy> getAllHierarchies() {
        Query query = entityManager.createNamedQuery("allHierarchies");
        return query.getResultList();
	}
	
	public Hierarchy getHierarchy(int id) {
		Hierarchy result = hierarchyMap.get(id);
		if (result == null) {
			result = entityManager.find(Hierarchy.class, id);
			if (result != null) {
				hierarchyMap.put(id, result);
			}
		}
		return result;
	}
	
	public String getHierarchyAsString(int id) {
		String result = "";
		Hierarchy hierarchy = getHierarchy(id);
		if (hierarchy != null) {
			if (hierarchy.getParentId() != 0) {
				result = getHierarchyAsString(hierarchy.getParentId());
			}
			result += " /" + hierarchy.getName();
		}
		return result;
	}

}
