package com.pacificmetrics.orca.test;

import org.unitils.mock.core.proxy.ProxyInvocation;
import org.unitils.mock.mockbehavior.impl.DefaultValueReturningMockBehavior;

/**
 * 
 * This class is used to count number of calls to the method during test scenario
 * 
 * @author amiliteev
 *
 */
public class CallCounter extends DefaultValueReturningMockBehavior {
    
    private int count = 0;
    
    @Override
    public Object execute(ProxyInvocation proxyInvocation) {
        count++;
        return super.execute(proxyInvocation);
    }
    
    public int getCount() {
        return count;
    }
    
};
