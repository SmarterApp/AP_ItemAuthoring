package com.pacificmetrics.orca.test;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.logging.Logger;

import org.apache.myfaces.extensions.cdi.message.api.Message;
import org.apache.myfaces.extensions.cdi.message.api.MessageContext;
import org.unitils.core.Module;
import org.unitils.core.TestListener;
import org.unitils.core.UnitilsException;
import org.unitils.mock.Mock;
import org.unitils.mock.core.MockObject;
import org.unitils.mock.core.proxy.ProxyInvocation;
import org.unitils.mock.mockbehavior.MockBehavior;
import org.unitils.util.AnnotationUtils;
import org.unitils.util.ReflectionUtils;

import com.pacificmetrics.orca.mbeans.AbstractManager;

public class MBeansModule implements Module {
    
	private static final Logger LOGGER = Logger
			.getLogger(MBeansModule.class.getName());
    private TestListener testListener;
    
    public MBeansModule() {
        initTestListener();
    }

    @Override
    public void init(Properties configuration) {        
        LOGGER.info("mbeans - init");
    }

    @Override
    public void afterInit() {       
        LOGGER.info("mbeans - after ini");
    }

    @Override
    public TestListener getTestListener() {
        return testListener;
    }
    
    protected void initTestListener() {
        testListener = new TestListener() {
            @Override
            public void beforeTestMethod(Object testObject, Method testMethod) {
                processTestedManagers(testObject);
            }
        };
    }
    
    private static void processTestedManagers(Object testObject) {
        Set<Field> fields = AnnotationUtils.getFieldsAnnotatedWith(testObject.getClass(), TestedManager.class);
        for (Field field : fields) {
            Object manager = ReflectionUtils.getFieldValue(testObject, field);
            if (!(manager instanceof AbstractManager)) {
                throw new UnitilsException("TestedManager annotation is applicable only to instances of AbstractManager");
            }
            injectMessageContext((AbstractManager)manager);
            TestParameters testParameters = field.getAnnotation(TestParameters.class);
            if (testParameters != null) {
                assignParameters((AbstractManager)manager, testParameters.value());
            } else {
                TestParameter testParameter = field.getAnnotation(TestParameter.class);
                if (testParameter != null) {
                    assignParameters((AbstractManager)manager, new TestParameter[] {testParameter});
                }
            }
            
        }
    }
    
    private static void assignParameters(AbstractManager manager, TestParameter[] testParameters) {
        Map<String, String> parametersMap = new HashMap<String, String>();
        for (TestParameter testParameter: testParameters) {
            parametersMap.put(testParameter.name(), testParameter.value());
        }
        manager.initializeParameters(parametersMap);
    }

    private static void injectMessageContext(AbstractManager manager) {
        final List<Message> messages = new ArrayList<Message>();
        final Mock<Message> mockMessage = new MockObject<Message>(Message.class, manager);
        Mock<MessageContext> mockMessageContext = new MockObject<MessageContext>(MessageContext.class, manager);
        mockMessageContext.returns(mockMessage).message().text(null).create();
        mockMessageContext.performs(new MockBehavior() {
            @Override
            public Object execute(ProxyInvocation proxyInvocation) throws Throwable {
                messages.add((Message)proxyInvocation.getArguments().get(0));
                return null;
            }
        }).addMessage(null);
        mockMessageContext.performs(new MockBehavior() {
            @Override
            public Object execute(ProxyInvocation proxyInvocation) throws Throwable {
                return messages;
            }
        }).getMessages();
        ReflectionUtils.setFieldValue(manager, ReflectionUtils.getFieldWithName(AbstractManager.class, "messageContext", false), mockMessageContext.getMock());
    }
}
