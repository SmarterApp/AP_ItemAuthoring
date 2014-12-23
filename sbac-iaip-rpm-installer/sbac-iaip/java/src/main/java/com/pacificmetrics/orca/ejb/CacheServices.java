package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.sql.Timestamp;
import java.util.List;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.orca.entities.LastModification;

@Stateless
@LocalBean
public class CacheServices implements Serializable {

    private static final long serialVersionUID = 1L;

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;

    public Timestamp getLastModificationTime(String tableName) {
        Query query = entityManager.createNamedQuery("lmByTableName");
        query.setParameter("lm_table_name", tableName);
        List<?> resultList = query.getResultList();
        return resultList != null && !resultList.isEmpty() ? ((LastModification)resultList.get(0)).getTimestamp() : null;
    }

}
