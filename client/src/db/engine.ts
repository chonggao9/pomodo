// SQLite 3 核心驱动引擎与 Schema 自动迁移管理
import initSqlJs, { type Database, type SqlJsStatic } from 'sql.js';
import wasmUrl from 'sql.js/dist/sql-wasm.wasm?url';
import { MIGRATIONS } from './migrations';
import { DatabaseStorage } from './storage';

export class SQLiteEngine {
  private static instance: SQLiteEngine | null = null;
  private SQL: SqlJsStatic | null = null;
  private db: Database | null = null;
  private isInitialized = false;

  private constructor() {}

  public static getInstance(): SQLiteEngine {
    if (!SQLiteEngine.instance) {
      SQLiteEngine.instance = new SQLiteEngine();
    }
    return SQLiteEngine.instance;
  }

  /** 初始化 SQLite WebAssembly 运行时并装载数据库 */
  public async init(initialBinary?: Uint8Array): Promise<void> {
    if (this.isInitialized && this.db && !initialBinary) {
      return;
    }

    if (!this.SQL) {
      // 针对浏览器环境与 Node 测试环境的 wasm 加载策略
      const isNode = typeof window === 'undefined';
      if (isNode) {
        this.SQL = await initSqlJs();
      } else {
        this.SQL = await initSqlJs({
          locateFile: () => wasmUrl,
        });
      }
    }

    let binary = initialBinary;
    if (!binary && typeof window !== 'undefined') {
      binary = await DatabaseStorage.loadBinary() ?? undefined;
    }

    if (binary) {
      try {
        this.db = new this.SQL.Database(binary);
      } catch (e) {
        console.warn('Failed to load existing database binary, creating new:', e);
        this.db = new this.SQL.Database();
      }
    } else {
      this.db = new this.SQL.Database();
    }

    // 启用外键约束
    this.db.run('PRAGMA foreign_keys = ON;');

    // 运行 Schema 自动化迁移
    await this.runMigrations();

    this.isInitialized = true;
    await this.persist();
  }

  /** 自动化版本迁移核心引擎 */
  public async runMigrations(): Promise<number> {
    if (!this.db) throw new Error('Database not initialized');

    // 1. 确保迁移控制表已建立
    this.db.run(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        version INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        applied_at DATETIME NOT NULL
      );
    `);

    // 2. 查询已应用的迁移版本
    const appliedVersions = new Set<number>();
    try {
      const res = this.db.exec('SELECT version FROM schema_migrations ORDER BY version ASC;');
      if (res.length > 0 && res[0].values) {
        for (const row of res[0].values) {
          appliedVersions.add(Number(row[0]));
        }
      }
    } catch (e) {
      console.error('Error checking applied migrations:', e);
    }

    let appliedCount = 0;
    const sortedMigrations = [...MIGRATIONS].sort((a, b) => a.version - b.version);

    for (const migration of sortedMigrations) {
      if (!appliedVersions.has(migration.version)) {
        console.info(`[SQLite Migration] Applying v${migration.version}: ${migration.name}...`);
        
        try {
          this.db.run('BEGIN TRANSACTION;');
          // 执行迁移脚本
          this.db.run(migration.sql);
          
          // 记录迁移日志
          const nowIso = new Date().toISOString();
          this.db.run(
            'INSERT INTO schema_migrations (version, name, applied_at) VALUES (?, ?, ?);',
            [migration.version, migration.name, nowIso]
          );
          this.db.run('COMMIT;');
          appliedCount++;
          console.info(`[SQLite Migration] Applied v${migration.version} successfully.`);
        } catch (migrationError) {
          this.db.run('ROLLBACK;');
          console.error(`[SQLite Migration] FAILED v${migration.version}:`, migrationError);
          throw migrationError;
        }
      }
    }

    return appliedCount;
  }

  /** 获取已应用的全部迁移版本列表 */
  public getAppliedMigrations(): Array<{ version: number; name: string; applied_at: string }> {
    if (!this.db) return [];
    const res = this.db.exec('SELECT version, name, applied_at FROM schema_migrations ORDER BY version ASC;');
    if (res.length === 0 || !res[0].values) return [];
    return res[0].values.map(row => ({
      version: Number(row[0]),
      name: String(row[1]),
      applied_at: String(row[2]),
    }));
  }

  /** 确保外键约束始终开启 (sql.js 在 export 序列化后会重置临时 PRAGMA) */
  private ensureForeignKeys(): void {
    if (this.db) {
      this.db.run('PRAGMA foreign_keys = ON;');
    }
  }

  /** 执行写操作（INSERT / UPDATE / DELETE）并自动持久化 */
  public run(sql: string, params: (string | number | null | undefined)[] = []): void {
    if (!this.db) throw new Error('Database not initialized');
    this.ensureForeignKeys();
    this.db.run(sql, params as (string | number | null)[]);
    this.persist();
  }

  /** 执行只读查询，返回对象数组 */
  public query<T = Record<string, unknown>>(sql: string, params: (string | number | null | undefined)[] = []): T[] {
    if (!this.db) throw new Error('Database not initialized');
    const stmt = this.db.prepare(sql);
    try {
      if (params.length > 0) {
        stmt.bind(params as (string | number | null)[]);
      }
      const results: T[] = [];
      while (stmt.step()) {
        results.push(stmt.getAsObject() as unknown as T);
      }
      return results;
    } finally {
      stmt.free();
    }
  }

  /** 执行只读查询，返回单行结果 */
  public queryOne<T = Record<string, unknown>>(sql: string, params: (string | number | null | undefined)[] = []): T | null {
    const list = this.query<T>(sql, params);
    return list.length > 0 ? list[0] : null;
  }

  /** 持久化当前 SQLite 数据库至本地 IndexedDB */
  public async persist(): Promise<void> {
    if (!this.db) return;
    try {
      const binary = this.db.export();
      this.ensureForeignKeys();
      await DatabaseStorage.saveBinary(binary);
    } catch (e) {
      console.warn('Failed to persist database:', e);
    }
  }

  /** 导出标准 SQLite 3 物理二进制流 (.db) */
  public exportBinary(): Uint8Array {
    if (!this.db) throw new Error('Database not initialized');
    const binary = this.db.export();
    this.ensureForeignKeys();
    return binary;
  }

  /** 获取数据库深度指标与健康度数据 (字节大小、表行数、Schema 版本、完整性校验) */
  public getDatabaseMetrics(): DatabaseMetrics {
    if (!this.db) {
      return {
        fileSizeBytes: 0,
        fileSizeFormatted: '0 B',
        taskCount: 0,
        pendingTaskCount: 0,
        completedTaskCount: 0,
        subtaskCount: 0,
        sessionCount: 0,
        categoryCount: 0,
        integrityStatus: 'unknown',
        schemaVersion: 0,
        schemaAppliedAt: '-',
      };
    }

    const binary = this.exportBinary();
    const bytes = binary.byteLength;
    const formattedSize = bytes < 1024
      ? `${bytes} B`
      : bytes < 1024 * 1024
        ? `${(bytes / 1024).toFixed(1)} KB`
        : `${(bytes / (1024 * 1024)).toFixed(2)} MB`;

    // 统计各核心表行数
    let totalTasks = 0;
    let pendingTasks = 0;
    let completedTasks = 0;
    let subtasks = 0;
    let sessions = 0;
    let categories = 0;
    let integrity = 'ok';

    try {
      const taskRow = this.queryOne<{ total: number; pending: number; completed: number }>(`
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending,
          SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed
        FROM tasks;
      `);
      if (taskRow) {
        totalTasks = Number(taskRow.total || 0);
        pendingTasks = Number(taskRow.pending || 0);
        completedTasks = Number(taskRow.completed || 0);
      }
    } catch {
      // 表可能尚未建立
    }

    try {
      const subRow = this.queryOne<{ cnt: number }>('SELECT COUNT(*) as cnt FROM subtasks;');
      if (subRow) subtasks = Number(subRow.cnt || 0);
    } catch {}

    try {
      const sessRow = this.queryOne<{ cnt: number }>('SELECT COUNT(*) as cnt FROM pomodoro_sessions;');
      if (sessRow) sessions = Number(sessRow.cnt || 0);
    } catch {}

    try {
      const catRow = this.queryOne<{ cnt: number }>('SELECT COUNT(*) as cnt FROM categories;');
      if (catRow) categories = Number(catRow.cnt || 0);
    } catch {}

    try {
      const checkRow = this.queryOne<{ integrity_check: string }>('PRAGMA integrity_check;');
      if (checkRow && checkRow.integrity_check) {
        integrity = String(checkRow.integrity_check);
      }
    } catch {
      integrity = 'error';
    }

    const migrations = this.getAppliedMigrations();
    const latestMigration = migrations.length > 0 ? migrations[migrations.length - 1] : null;

    return {
      fileSizeBytes: bytes,
      fileSizeFormatted: formattedSize,
      taskCount: totalTasks,
      pendingTaskCount: pendingTasks,
      completedTaskCount: completedTasks,
      subtaskCount: subtasks,
      sessionCount: sessions,
      categoryCount: categories,
      integrityStatus: integrity,
      schemaVersion: latestMigration ? latestMigration.version : 0,
      schemaAppliedAt: latestMigration ? latestMigration.applied_at : '-',
    };
  }

  /** 清空重置本地所有业务数据（保留表结构）并立即持久化 */
  public async wipeAndResetDatabase(): Promise<void> {
    if (!this.db) throw new Error('Database not initialized');
    this.ensureForeignKeys();
    this.db.run('BEGIN TRANSACTION;');
    try {
      this.db.run('DELETE FROM pomodoro_sessions;');
      this.db.run('DELETE FROM subtasks;');
      this.db.run('DELETE FROM tasks;');
      // 清空自增序列计数（如存在）
      try {
        this.db.run("DELETE FROM sqlite_sequence WHERE name IN ('tasks', 'subtasks', 'pomodoro_sessions');");
      } catch {}
      this.db.run('COMMIT;');
    } catch (e) {
      this.db.run('ROLLBACK;');
      throw e;
    }
    await this.persist();
  }

  /** 导入外部 .db 物理数据库并重新初始化运行 */
  public async importBinary(binary: Uint8Array): Promise<void> {
    // 验证 SQLite 头部魔数 (SQLite format 3\0)
    const header = new TextDecoder().decode(binary.slice(0, 16));
    if (!header.startsWith('SQLite format 3')) {
      throw new Error('Invalid SQLite 3 database file header');
    }
    await this.init(binary);
    await this.persist();
  }

  /** 触发浏览器一键下载 .db 数据库文件 */
  public downloadDatabaseFile(filename = 'pomodo_backup.db'): void {
    const binary = this.exportBinary();
    const blob = new Blob([binary.buffer as ArrayBuffer], { type: 'application/x-sqlite3' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }
}

export interface DatabaseMetrics {
  fileSizeBytes: number;
  fileSizeFormatted: string;
  taskCount: number;
  pendingTaskCount: number;
  completedTaskCount: number;
  subtaskCount: number;
  sessionCount: number;
  categoryCount: number;
  integrityStatus: string;
  schemaVersion: number;
  schemaAppliedAt: string;
}

