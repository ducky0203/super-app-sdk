import type {EmitterSubscription} from 'react-native';
import {
  createEventEmitter,
  getNativeBridge,
  isBridgeAvailable,
  ROLE_KEY,
} from './native';
import {
  type SuperAppBridgeEventPayload,
  type SuperAppDataChangedPayload,
  type SuperAppDataMap,
  type SuperAppRole,
} from './types';

const EVENT_DATA_CHANGED = 'SuperAppDataChanged';
const EVENT_BRIDGE = 'SuperAppEvent';

function serialize(value: unknown): string {
  return JSON.stringify(value);
}

function deserialize<T>(raw: string | null | undefined): T | null {
  if (raw == null || raw === '') {
    return null;
  }
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

/**
 * SDK chia sẻ dữ liệu giữa host app và mini app (cùng process, 2 React Native runtime).
 *
 * Dữ liệu lưu native in-memory; mini app bundle cần import SDK này và chạy trong
 * shell host đã đăng ký `SuperAppBridge` native module.
 */
export const SuperAppSDK = {
  ROLE_KEY,

  /** Trả về `true` nếu native bridge đã được link (đang chạy trong host shell). */
  isAvailable(): boolean {
    return isBridgeAvailable();
  },

  /** Ghi object/string/number — lưu dạng JSON string */
  async set<T>(key: string, value: T): Promise<void> {
    const encoded = typeof value === 'string' ? value : serialize(value);
    await getNativeBridge().setItem(key, encoded);
  },

  async get<T>(key: string): Promise<T | null> {
    const raw = await getNativeBridge().getItem(key);
    if (raw == null) {
      return null;
    }
    const parsed = deserialize<T>(raw);
    return parsed ?? (raw as T);
  },

  async remove(key: string): Promise<boolean> {
    return getNativeBridge().removeItem(key);
  },

  async getAll(): Promise<SuperAppDataMap> {
    return getNativeBridge().getAllItems();
  },

  async clear(): Promise<void> {
    await getNativeBridge().clear();
  },

  async setRole(role: SuperAppRole): Promise<void> {
    await getNativeBridge().setRole(role);
  },

  async getRole(): Promise<SuperAppRole | null> {
    const role = await getNativeBridge().getRole();
    if (role === 'host' || role === 'mini') {
      return role;
    }
    return null;
  },

  async isHost(): Promise<boolean> {
    return (await this.getRole()) === 'host';
  },

  async isMini(): Promise<boolean> {
    return (await this.getRole()) === 'mini';
  },

  /**
   * Host gọi trước khi mở mini app: set role + merge data cho mini đọc.
   */
  async prepareMiniLaunch(data: Record<string, unknown>): Promise<void> {
    await this.setRole('mini');
    await Promise.all(
      Object.entries(data).map(([key, value]) => this.set(key, value)),
    );
  },

  onDataChanged(
    listener: (payload: SuperAppDataChangedPayload) => void,
  ): EmitterSubscription {
    const emitter = createEventEmitter();
    return emitter.addListener(EVENT_DATA_CHANGED, listener);
  },

  onEvent(
    listener: (payload: SuperAppBridgeEventPayload) => void,
  ): EmitterSubscription {
    const emitter = createEventEmitter();
    return emitter.addListener(EVENT_BRIDGE, listener);
  },

  async emitEvent(eventName: string, payload?: unknown): Promise<void> {
    const json = payload === undefined ? null : serialize(payload);
    await getNativeBridge().emitEvent(eventName, json);
  },

};

export default SuperAppSDK;

export type {
  SuperAppBridgeEventPayload,
  SuperAppDataChangedPayload,
  SuperAppDataMap,
  SuperAppRole,
} from './types';

export {getNativeBridge, isBridgeAvailable, ROLE_KEY} from './native';
export type {SuperAppBridgeNative} from './native';
