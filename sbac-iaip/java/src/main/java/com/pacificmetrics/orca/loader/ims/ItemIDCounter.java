package com.pacificmetrics.orca.loader.ims;

import java.util.concurrent.atomic.AtomicLong;

import javax.annotation.PostConstruct;
import javax.ejb.EJB;
import javax.ejb.Singleton;

import com.pacificmetrics.orca.ejb.ItemServices;

@Singleton
public class ItemIDCounter {

    @EJB
    private transient ItemServices itemService;

    private AtomicLong counter;

    @PostConstruct
    public void init() {
        counter = new AtomicLong(0L);
        refreshCounter();
    }

    public void refreshCounter() {
        counter.set(itemService.getMaxItemId());
    }

    public long nextItemID() {
        while (true) {
            long current = counter.get();
            long nextID = current + 1;
            if (counter.compareAndSet(current, nextID)) {
                return nextID;
            }
        }

    }

}
