// File System Access API: pick a root folder, persist the handle in IndexedDB,
// write recordings into nested subdirs <project>/<training>/<date>/<exercise>/.

const DB_NAME = "way2train";
const STORE_NAME = "handles";
const KEY = "rootFolder";

const openDB = (): Promise<IDBDatabase> =>
  new Promise((resolve, reject) => {
    const req = indexedDB.open(DB_NAME, 1);
    req.onupgradeneeded = () => req.result.createObjectStore(STORE_NAME);
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });

const idbGet = async <T>(key: string): Promise<T | null> => {
  const db = await openDB();
  return new Promise((res, rej) => {
    const tx = db.transaction(STORE_NAME, "readonly");
    const req = tx.objectStore(STORE_NAME).get(key);
    req.onsuccess = () => res((req.result as T) ?? null);
    req.onerror = () => rej(req.error);
  });
};

const idbSet = async (key: string, value: unknown): Promise<void> => {
  const db = await openDB();
  return new Promise((res, rej) => {
    const tx = db.transaction(STORE_NAME, "readwrite");
    tx.objectStore(STORE_NAME).put(value, key);
    tx.oncomplete = () => res();
    tx.onerror = () => rej(tx.error);
  });
};

export const isFsApiSupported = (): boolean =>
  typeof (window as any).showDirectoryPicker === "function";

/** Prompt user to pick the root save folder; persist handle for next session. */
export const pickRootFolder = async (): Promise<FileSystemDirectoryHandle> => {
  const handle = await (window as any).showDirectoryPicker({ mode: "readwrite" });
  await idbSet(KEY, handle);
  return handle;
};

/** Returns the previously-picked handle if still authorized, else null. */
export const restoreRootFolder = async (): Promise<FileSystemDirectoryHandle | null> => {
  const handle = (await idbGet<FileSystemDirectoryHandle>(KEY)) ?? null;
  if (!handle) return null;
  const perm = await (handle as any).queryPermission({ mode: "readwrite" });
  if (perm === "granted") return handle;
  // Need a user gesture to re-prompt; caller will do that.
  return handle;
};

/** Re-request permission on a stored handle (must be called from a user gesture). */
export const ensurePermission = async (handle: FileSystemDirectoryHandle): Promise<boolean> => {
  const opts = { mode: "readwrite" } as const;
  if ((await (handle as any).queryPermission(opts)) === "granted") return true;
  return (await (handle as any).requestPermission(opts)) === "granted";
};

const slug = (s: string): string =>
  s.trim().toLowerCase().replace(/[^a-z0-9-]+/g, "-").replace(/^-|-$/g, "") || "untitled";

export interface SavePathParts {
  training: string;
  date: string;        // YYYY-MM-DD
  exercise: string;
  fileName: string;    // e.g. "18-04-32.webm"
}

/** Walks <root>/<training>/<date>/<exercise>/, writes the blob, returns full pseudo-path. */
export const saveRecording = async (
  root: FileSystemDirectoryHandle,
  parts: SavePathParts,
  blob: Blob,
): Promise<string> => {
  const trainDir = await root.getDirectoryHandle(slug(parts.training), { create: true });
  const dateDir = await trainDir.getDirectoryHandle(parts.date, { create: true });
  const exDir = await dateDir.getDirectoryHandle(slug(parts.exercise), { create: true });
  const fileHandle = await exDir.getFileHandle(parts.fileName, { create: true });
  const w = await fileHandle.createWritable();
  await w.write(blob);
  await w.close();
  return `${root.name}/${slug(parts.training)}/${parts.date}/${slug(parts.exercise)}/${parts.fileName}`;
};
