import {NativeEventEmitter, NativeModules, Platform} from 'react-native';

export type SuperAppBridgeNative = {
  setItem(key: string, value: string): Promise<void>;
  getItem(key: string): Promise<string | null>;
  removeItem(key: string): Promise<boolean>;
  getAllItems(): Promise<Record<string, string>>;
  clear(): Promise<void>;
  setRole(role: string): Promise<void>;
  getRole(): Promise<string | null>;
  emitEvent(eventName: string, payloadJson: string | null): Promise<void>;
  addListener(eventName: string): void;
  removeListeners(count: number): void;
  ROLE_KEY?: string;
};

const SuperAppBridgeModule = NativeModules.SuperAppBridge as
  | SuperAppBridgeNative
  | undefined;

export function getNativeBridge(): SuperAppBridgeNative {
  if (!SuperAppBridgeModule) {
    throw new Error(
      `[super-app-sdk] SuperAppBridge native module is not linked on ${Platform.OS}. ` +
        'Make sure the host shell registers SuperAppBridgePackage / SuperAppBridge.',
    );
  }
  return SuperAppBridgeModule;
}

export function isBridgeAvailable(): boolean {
  return Boolean(SuperAppBridgeModule);
}

export function createEventEmitter(): NativeEventEmitter {
  return new NativeEventEmitter(getNativeBridge());
}

export const ROLE_KEY =
  SuperAppBridgeModule?.ROLE_KEY ?? '__super_app_role__';
