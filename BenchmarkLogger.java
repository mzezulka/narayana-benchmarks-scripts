package com.arjuna.ats.arjuna.logging;

import java.io.IOException;
import java.io.PrintWriter;
import java.io.FileNotFoundException;
import java.util.UUID;
import java.util.logging.FileHandler;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.logging.SimpleFormatter;
import java.util.concurrent.atomic.AtomicInteger;

public final class BenchmarkLogger {
    private static final Logger LOGGER = Logger.getLogger("MyLog");
    private static final AtomicInteger NUM_WRITES = new AtomicInteger();
    private static final String FILE_PATH = "/tmp/narayana-benchmark.txt";
    private static FileHandler FH;
    private static final int DUMP_LOG_SIZE_BYTES = 100_000_000;
    private static final String MSG = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed"
            + " do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim "
            + "veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";
    private static final int MAX_NUM_WRITES = DUMP_LOG_SIZE_BYTES / MSG.length();

    static {
        try {
            LOGGER.setUseParentHandlers(false);
            LOGGER.setLevel(Level.ALL);
            FH = new FileHandler(FILE_PATH, DUMP_LOG_SIZE_BYTES, 1);
            FH.setLevel(Level.ALL);
            LOGGER.addHandler(FH);
            SimpleFormatter formatter = new SimpleFormatter();
            FH.setFormatter(formatter);
        } catch (SecurityException | IOException e) {
            throw new RuntimeException(e);
        }
    }

    public static void logMessage() {
        LOGGER.info(UUID.randomUUID() + " " + MSG);
        if(NUM_WRITES.getAndIncrement() >= MAX_NUM_WRITES) {
            LOGGER.info("Emptying log file...");
            NUM_WRITES.set(0);
            try {
                new PrintWriter(FILE_PATH).close();
            } catch(FileNotFoundException fnfe) {
                throw new RuntimeException(fnfe);
            }
        }
    }
}
