package com.factpro.core.event;

import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;

class EventManagerTest {

    @AfterEach
    void tearDown() {
        EventManager.getInstance().clear();
    }

    @Test
    void shouldReturnSameInstance() {
        EventManager em1 = EventManager.getInstance();
        EventManager em2 = EventManager.getInstance();
        assertSame(em1, em2);
    }

    @Test
    void shouldEmitEventToListeners() {
        EventManager em = EventManager.getInstance();
        List<Object> received = new ArrayList<>();

        em.on("test", (String data) -> received.add(data));
        em.emit("test", "hello");

        assertEquals(1, received.size());
        assertEquals("hello", received.get(0));
    }

    @Test
    void shouldSupportMultipleListeners() {
        EventManager em = EventManager.getInstance();
        AtomicInteger count = new AtomicInteger(0);

        em.on("counter", (Object o) -> count.incrementAndGet());
        em.on("counter", (Object o) -> count.incrementAndGet());
        em.on("counter", (Object o) -> count.incrementAndGet());

        em.emit("counter", null);

        assertEquals(3, count.get());
    }

    @Test
    void shouldHandleEventWithoutData() {
        EventManager em = EventManager.getInstance();
        AtomicInteger count = new AtomicInteger(0);

        em.on("ping", (Object o) -> count.incrementAndGet());
        em.emit("ping");

        assertEquals(1, count.get());
    }

    @Test
    void shouldHandleNoListeners() {
        EventManager em = EventManager.getInstance();
        assertDoesNotThrow(() -> em.emit("nonexistent"));
    }

    @Test
    void shouldHandleListenerException() {
        EventManager em = EventManager.getInstance();
        AtomicInteger count = new AtomicInteger(0);

        em.on("error", (Object o) -> { throw new RuntimeException("Simulated"); });
        em.on("error", (Object o) -> count.incrementAndGet());

        // Should not throw - the exception should be caught internally
        assertDoesNotThrow(() -> em.emit("error", null));
        // Second listener should still execute
        assertEquals(1, count.get());
    }

    @Test
    void shouldRemoveAllListenersForEvent() {
        EventManager em = EventManager.getInstance();
        AtomicInteger count = new AtomicInteger(0);

        em.on("temp", (Object o) -> count.incrementAndGet());
        em.emit("temp", null);
        assertEquals(1, count.get());

        em.off("temp");
        em.emit("temp", null);
        assertEquals(1, count.get()); // no increment
    }

    @Test
    void shouldClearAllListeners() {
        EventManager em = EventManager.getInstance();
        AtomicInteger count = new AtomicInteger(0);

        em.on("evt1", (Object o) -> count.incrementAndGet());
        em.on("evt2", (Object o) -> count.incrementAndGet());

        em.clear();

        em.emit("evt1", null);
        em.emit("evt2", null);
        assertEquals(0, count.get());
    }
}
