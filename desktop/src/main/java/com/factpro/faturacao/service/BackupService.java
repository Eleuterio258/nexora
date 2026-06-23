package com.factpro.faturacao.service;

import com.factpro.config.AppConfig;
import com.factpro.core.database.DatabaseManager;
import com.factpro.core.util.DateFormatter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Service for creating and managing database backups.
 */
public class BackupService {

    private static final Logger logger = LoggerFactory.getLogger(BackupService.class);

    /**
     * Creates a backup of the current database.
     *
     * @return the backup file, or null if backup is not supported for current DB type
     */
    public File createBackup() {
        String timestamp = DateFormatter.formatForFile(LocalDateTime.now());
        String backupDir = AppConfig.getInstance().getBackupPath();

        try {
            Files.createDirectories(Path.of(backupDir));
        } catch (Exception e) {
            logger.error("Erro ao criar diretório de backup: {}", backupDir, e);
            return null;
        }

        if (DatabaseManager.getInstance().getType() == AppConfig.DatabaseType.SQLITE) {
            File dbFile = new File(AppConfig.getInstance().getSqlitePath());
            File backupFile = new File(backupDir, "factpro_" + timestamp + ".db");
            try {
                Files.copy(dbFile.toPath(), backupFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
                logger.info("Backup criado: {}", backupFile.getAbsolutePath());
                return backupFile;
            } catch (Exception e) {
                logger.error("Erro ao criar backup do SQLite", e);
                return null;
            }
        } else {
            // For MySQL/PG, create SQL dump (placeholder)
            logger.warn("Backup para servidor BD não implementado. Use pg_dump/mysqldump.");
            return null;
        }
    }

    /**
     * Lists all existing backup files.
     *
     * @return list of backup files, sorted by name descending
     */
    public List<File> listBackups() {
        File dir = new File(AppConfig.getInstance().getBackupPath());
        if (!dir.exists()) {
            return Collections.emptyList();
        }
        File[] files = dir.listFiles((d, n) -> n.startsWith("factpro_") && n.endsWith(".db"));
        if (files == null) {
            return Collections.emptyList();
        }
        Arrays.sort(files, (a, b) -> b.getName().compareTo(a.getName()));
        return Arrays.asList(files);
    }

    /**
     * Removes backup files older than the configured retention period.
     */
    public void cleanupOldBackups() {
        int retentionDays = AppConfig.getInstance().getBackupRetentionDays();
        File dir = new File(AppConfig.getInstance().getBackupPath());
        if (!dir.exists()) {
            return;
        }

        File[] files = dir.listFiles((d, n) -> n.endsWith(".db"));
        if (files == null) {
            return;
        }

        long cutoff = System.currentTimeMillis() - (retentionDays * 24L * 60 * 60 * 1000);
        for (File f : files) {
            if (f.lastModified() < cutoff) {
                boolean deleted = f.delete();
                if (deleted) {
                    logger.info("Backup antigo eliminado: {}", f.getName());
                }
            }
        }
    }
}
