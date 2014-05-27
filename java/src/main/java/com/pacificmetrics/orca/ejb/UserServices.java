/**
 * 
 */
package com.pacificmetrics.orca.ejb;

import java.util.logging.Logger;

import javax.annotation.Resource;
import javax.ejb.SessionContext;
import javax.ejb.Stateless;
import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.PersistenceContextType;
import javax.persistence.TypedQuery;

import com.pacificmetrics.orca.ORCAConstants;
import com.pacificmetrics.orca.entities.User;

/**
 * @author maumock
 * 
 */

@Stateless
public class UserServices {
    private static final Logger log = Logger.getLogger(UserServices.class.getName());

    @PersistenceContext(unitName = "cde-unit", type = PersistenceContextType.TRANSACTION)
    private EntityManager em;

    @Resource
    SessionContext context;

    public static final String DEFAULT_USER_NAME = "UNKNOWN";
    public static final String GUEST = "GUEST";

    /**
     * The assumption is all user names are unique in the system. This is an extra precaution to throw errors in the instances of two or more user names.
     * 
     * @param userName
     * @return
     */
    public User getUser(String userName) {
        if (userName == null) {
            return null;
        }
        if ((DEFAULT_USER_NAME.equals(userName) || GUEST.equalsIgnoreCase(userName)) && isDevelopmentMode()) {
            //in development mode, always assume user with user id = 1
            final User u = em.find(User.class, 1);
            return u;
        }
        log.finest("Looking up user:" + userName);
        final TypedQuery<User> q = this.em.createNamedQuery("getUserByUserName", User.class);

        q.setParameter("userName", userName);
        return q.getSingleResult();
    }

    /**
     * Convenience method to retrieve the user from the current session.
     * 
     * @param userName
     * @return
     */
    public User getUser() {
        return getUser(getUserName());
    }

    protected String getUserName() {
        if (this.context.getCallerPrincipal() == null) {
            return DEFAULT_USER_NAME;
        }
        return this.context.getCallerPrincipal().getName();
    }

    /**
     * Tests to verify if the tomcat instance is in development mode or not. 
     * @return true if {@link ORCAConstants#SYSTEM_PROPERTY_DEVELOPMENT} is set to true in the system properties. 
     */
    protected boolean isDevelopmentMode() {
        String development=System.getProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT);
        return development!=null && "true".equalsIgnoreCase(development.trim());
    }
}
