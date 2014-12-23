package com.pacificmetrics.orca.ejb;

import java.io.Serializable;
import java.util.List;
import java.util.SortedMap;
import java.util.TreeMap;
import java.util.logging.Logger;

import javax.ejb.LocalBean;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.Query;

import com.pacificmetrics.orca.entities.GlossaryLanguage;
import com.pacificmetrics.orca.entities.Language;

@Stateless
@LocalBean
public class MiscServices implements Serializable {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = Logger.getLogger(MiscServices.class
            .getName());

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager entityManager;

    @SuppressWarnings("unchecked")
    public List<Language> getAllLanguages() {
        return entityManager.createNamedQuery("allLanguages").getResultList();
    }

    @SuppressWarnings("unchecked")
    public List<GlossaryLanguage> getAllGlossaryLanaguages() {
        return entityManager.createNamedQuery("allGlossaryLanguages")
                .getResultList();
    }

    /**
     * Returns sorted map of languages where the key is language name and the
     * value is language code
     * 
     * @return
     */
    public SortedMap<String, String> getLanguagesMap() {
        SortedMap<String, String> result = new TreeMap<String, String>();
        for (Language language : getAllLanguages()) {
            result.put(language.getName(), language.getCode());
        }
        return result;
    }

    public SortedMap<String, String> getGlossaryLanguageMap() {
        SortedMap<String, String> result = new TreeMap<String, String>();
        for (GlossaryLanguage language : getAllGlossaryLanaguages()) {
            result.put(language.getDesc(), language.getCode());
        }
        return result;
    }

    /**
     * This method is used to access any database table using native query to
     * retrieve lookup code for the given table name, lookup-value field,
     * lookup-by field, optional lookup prefix and actual value
     * 
     * @param tableName
     *            Database table name which should be queried
     * @param lookupByField
     *            The field for the 'where' clause that must contain given value
     * @param lookupPrefix
     *            Optional prefix for the value (may be null)
     * @param lookupValueField
     *            The selected field (must be numeric) which value will be
     *            returned as the result of this method
     * @param value
     *            The value the database table is searched for
     * @return Integer value of the lookupValueField
     */
    public Integer getLookupCode(String tableName, String lookupByField,
            String lookupPrefix, String lookupValueField, String value) {
        String queryStr = "select " + lookupValueField + " from " + tableName
                + " where " + lookupByField + " = '"
                + (lookupPrefix != null ? lookupPrefix : "") + value + "'";
        Query query = entityManager.createNativeQuery(queryStr);
        List<?> list = query.getResultList();
        Object result = !list.isEmpty() ? list.get(0) : null;
        if (result == null || !(result instanceof Number)) {
            LOGGER.warning(result + ": invalid result for the lookup query ("
                    + queryStr + ")");
            return null;
        } else {
            return ((Number) result).intValue();
        }
    }

}
