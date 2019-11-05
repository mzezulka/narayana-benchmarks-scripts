package com.arjuna.ats.arjuna.logging;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Timestamp;
import java.util.Date;
import java.util.UUID;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import java.util.concurrent.atomic.AtomicInteger;

public final class BenchmarkLogger {
    private static final Logger LOGGER = Logger.getLogger("MyLog");
    private static final int MAX_NUM_WRITES = 100;
    private static final AtomicInteger NUM_WRITES = new AtomicInteger();
    private static final String FILE_PATH = "/tmp/narayana-benchmark-" + new Timestamp(new Date().getTime()).getTime();
    private static final String MSG = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed"
            + " do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
            + "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";

    static {
        try {
            LOGGER.setLevel(Level.ALL);
            FileHandler fh;
            fh = new FileHandler(FILE_PATH);
            fh.setLevel(Level.ALL);
            LOGGER.addHandler(fh);
            SimpleFormatter formatter = new SimpleFormatter();
            fh.setFormatter(formatter);
        } catch (SecurityException | IOException e) {
            throw new RuntimeException(e);
        }
    }

    public static void logMessage() {
        LOGGER.info(UUID.randomUUID() + MSG + " ");
        if(NUM_WRITES.getAndIncrement() >= MAX_NUM_WRITES) {
            NUM_WRITES.set(0);
            // truncate to zero
            try(PrintWriter p = new PrintWriter(FILE_PATH)) {
            } catch(IOException ie) {
                throw new RuntimeException(ie);
            }
        }
    }
}
