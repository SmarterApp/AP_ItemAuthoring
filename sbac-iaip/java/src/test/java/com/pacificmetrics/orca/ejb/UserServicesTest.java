/**
 * 
 */
package com.pacificmetrics.orca.ejb;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.security.Principal;

import javax.ejb.SessionContext;
import javax.persistence.NoResultException;

import org.junit.Test;
import org.unitils.UnitilsJUnit4;
import org.unitils.dbunit.annotation.DataSet;
import org.unitils.inject.annotation.TestedObject;
import org.unitils.mock.Mock;
import org.unitils.orm.jpa.annotation.JpaEntityManagerFactory;

import com.pacificmetrics.orca.ORCAConstants;
import com.pacificmetrics.orca.entities.User;
import com.pacificmetrics.orca.test.InjectIntoByTypeExt;

/**
 * @author maumock
 * 
 */

@SuppressWarnings("static-method")
@DataSet("UserServicesTest.xml")
@JpaEntityManagerFactory(persistenceUnit = "test-cde-unit", configFile = "META-INF/persistence-test.xml")
public class UserServicesTest extends UnitilsJUnit4 {

    @TestedObject
    private static UserServices us;

    @InjectIntoByTypeExt
    private Mock<SessionContext> context;

    static String[] names = { "john", "jingleheimer", "schmidt" };

    private static Principal p = new Principal() {
        @Override
        public String getName() {
            return names[0];
        }
    };

    /**
     * Test method for
     * {@link com.pacificmetrics.orca.ejb.UserServices#getUser(java.lang.String)}
     * .
     */
    @Test
    public final void testGetUserString() {
        for (int i = 1; i < names.length; i++) {
            validateUser(names[i], i + 1, us.getUser(names[i]));
        }
        userDoesntExist(UserServices.DEFAULT_USER_NAME);
    }

    /**
     * Test method for
     * {@link com.pacificmetrics.orca.ejb.UserServices#getUser()}.
     */
    @Test
    public final void testGetUser() {
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT, "true");
        validateDefaultUser(us.getUser());
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT, "false");
        userDoesntExist(UserServices.DEFAULT_USER_NAME);

        this.context.returns(p).getCallerPrincipal();
        validateUser("john", 1, us.getUser());
    }

    /**
     * Test method for
     * {@link com.pacificmetrics.orca.ejb.UserServices#getUserName()}.
     */
    @Test
    public final void testGetUserName() {
        assertNotNull(us.getUserName());
        assertEquals(UserServices.DEFAULT_USER_NAME, us.getUserName());

        this.context.returns(p).getCallerPrincipal();
        assertEquals(names[0], us.getUserName());
    }

    /**
     * Test method for
     * {@link com.pacificmetrics.orca.ejb.UserServices#isDevelopmentMode()}.
     */
    @Test
    public final void testIsDevelopmentMode() {
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT, "true");
        validateDefaultUser(us.getUser());
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT, "false");
        userDoesntExist(UserServices.DEFAULT_USER_NAME);
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT,
                " TrUE   ");
        validateDefaultUser(us.getUser());
        System.setProperty(ORCAConstants.SYSTEM_PROPERTY_DEVELOPMENT,
                "  FaLSe ");
        userDoesntExist(UserServices.DEFAULT_USER_NAME);
    }

    /**
     * Validate a user has the correct information. Please look in the
     * supporting XML data for these values.
     * 
     * @param name
     * @param id
     * @param user
     */
    private static void validateUser(String name, int id, User user) {
        assertNotNull(name);
        assertNotNull(user);
        assertEquals(id, user.getId());
        assertEquals(name, user.getUserName());
        assertNotNull(user.getUserPermissions());
        assertEquals(1, user.getUserPermissions().size());
        assertEquals(id, user.getUserPermissions().get(0).getType());
        assertEquals(id, user.getUserPermissions().get(0).getValue());
    }

    /**
     * A default user only has id and user name set. Validate this is true.
     * 
     * @param user
     */
    private static void validateDefaultUser(User user) {
        assertNotNull(user);
        assertEquals(1, user.getId());
        assertEquals("john", user.getUserName());
    }

    /**
     * Validate there isn't a user for a specific user name.
     * 
     * @param userName
     */
    private static void userDoesntExist(String userName) {

        try {
            us.getUser(userName);
            fail("An exception should be thrown on this one.");
        } catch (NoResultException e) {
            assertTrue(e.getMessage().contains("no result"));
        }
    }
}
