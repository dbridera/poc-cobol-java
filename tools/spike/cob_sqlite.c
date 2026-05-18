/*
 * Tiny SQLite shim callable from GnuCOBOL.
 *
 * Module 1 spike: prove EXEC SQL-equivalent semantics on GnuCOBOL by
 * routing through CALL "cob_sqlite_*" to libsqlite3.
 *
 * Production migration would use a real EXEC SQL preprocessor (GIXSQL).
 * This shim emits the same shape of output the preprocessor would.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sqlite3.h>

static sqlite3 *g_db = NULL;

/* cob_sqlite_open(filename) -> rc (0 ok, 1 err) */
int cob_sqlite_open(const char *filename_padded) {
    char filename[256] = {0};
    int i;
    for (i = 0; i < 255 && filename_padded[i] != ' ' && filename_padded[i] != 0; i++) {
        filename[i] = filename_padded[i];
    }
    filename[i] = 0;
    if (sqlite3_open(filename, &g_db) != SQLITE_OK) {
        fprintf(stderr, "sqlite_open failed: %s\n", sqlite3_errmsg(g_db));
        return 1;
    }
    return 0;
}

/* cob_sqlite_exec(sql_padded) -> rc (0 ok, 1 err) */
int cob_sqlite_exec(const char *sql_padded) {
    char sql[4096] = {0};
    int i, last_non_space = -1;
    for (i = 0; i < 4095 && sql_padded[i] != 0; i++) {
        sql[i] = sql_padded[i];
        if (sql_padded[i] != ' ') last_non_space = i;
    }
    sql[last_non_space + 1] = 0;
    char *err = NULL;
    if (sqlite3_exec(g_db, sql, NULL, NULL, &err) != SQLITE_OK) {
        fprintf(stderr, "sqlite_exec failed: %s\nSQL: %s\n", err, sql);
        sqlite3_free(err);
        return 1;
    }
    return 0;
}

/*
 * cob_sqlite_dump(table_padded, output_path_padded) -> rc (0 ok, 1 err)
 *
 * Writes the table to output_path as: col1|col2|...\n per row,
 * sorted by the first column for deterministic ordering. No header.
 */
int cob_sqlite_dump(const char *table_padded, const char *path_padded) {
    char table[64] = {0}, path[256] = {0};
    int i;
    for (i = 0; i < 63 && table_padded[i] != ' ' && table_padded[i] != 0; i++) table[i] = table_padded[i];
    for (i = 0; i < 255 && path_padded[i] != ' ' && path_padded[i] != 0; i++) path[i] = path_padded[i];

    char sql[256];
    snprintf(sql, sizeof(sql), "SELECT * FROM %s ORDER BY 1", table);

    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(g_db, sql, -1, &stmt, NULL) != SQLITE_OK) {
        fprintf(stderr, "sqlite_dump prepare failed: %s\n", sqlite3_errmsg(g_db));
        return 1;
    }

    FILE *f = fopen(path, "w");
    if (!f) {
        fprintf(stderr, "sqlite_dump fopen failed: %s\n", path);
        sqlite3_finalize(stmt);
        return 1;
    }

    int ncols = sqlite3_column_count(stmt);
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        for (int c = 0; c < ncols; c++) {
            if (c > 0) fputc('|', f);
            const unsigned char *val = sqlite3_column_text(stmt, c);
            if (val) fputs((const char *)val, f);
        }
        fputc('\n', f);
    }
    fclose(f);
    sqlite3_finalize(stmt);
    return 0;
}

/* cob_sqlite_close() -> rc (always 0) */
int cob_sqlite_close(void) {
    if (g_db) {
        sqlite3_close(g_db);
        g_db = NULL;
    }
    return 0;
}
