// 基于 IndexedDB 的 SQLite 二进制文件物理持久化存储
const DB_NAME = 'pomodo_sqlite_storage';
const STORE_NAME = 'database_files';
const DB_KEY = 'pomodo_main.db';

export class DatabaseStorage {
  private static isSupported(): boolean {
    return typeof indexedDB !== 'undefined';
  }

  private static openIDB(): Promise<IDBDatabase> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, 1);
      request.onupgradeneeded = () => {
        const db = request.result;
        if (!db.objectStoreNames.contains(STORE_NAME)) {
          db.createObjectStore(STORE_NAME);
        }
      };
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  }

  /** 从本地持久层加载 SQLite 二进制文件数据 */
  public static async loadBinary(): Promise<Uint8Array | null> {
    if (!this.isSupported()) return null;
    try {
      const idb = await this.openIDB();
      return new Promise((resolve) => {
        const tx = idb.transaction(STORE_NAME, 'readonly');
        const store = tx.objectStore(STORE_NAME);
        const req = store.get(DB_KEY);
        req.onsuccess = () => {
          if (req.result && req.result instanceof Uint8Array) {
            resolve(req.result);
          } else {
            resolve(null);
          }
        };
        req.onerror = () => resolve(null);
      });
    } catch {
      return null;
    }
  }

  /** 保存最新的 SQLite 二进制数据到 IndexedDB */
  public static async saveBinary(binary: Uint8Array): Promise<boolean> {
    if (!this.isSupported()) return false;
    try {
      const idb = await this.openIDB();
      return new Promise((resolve, reject) => {
        const tx = idb.transaction(STORE_NAME, 'readwrite');
        const store = tx.objectStore(STORE_NAME);
        const req = store.put(binary, DB_KEY);
        req.onsuccess = () => resolve(true);
        req.onerror = () => reject(req.error);
      });
    } catch (e) {
      console.error('Failed to persist SQLite binary:', e);
      return false;
    }
  }

  /** 清空本地持久化存储 */
  public static async clear(): Promise<void> {
    if (!this.isSupported()) return;
    try {
      const idb = await this.openIDB();
      const tx = idb.transaction(STORE_NAME, 'readwrite');
      tx.objectStore(STORE_NAME).delete(DB_KEY);
    } catch (e) {
      console.error('Failed to clear storage:', e);
    }
  }
}
