export type SuperAppRole = 'host' | 'mini';

export type SuperAppDataChangedPayload = {
  key?: string;
  value?: string;
};

export type SuperAppBridgeEventPayload = {
  eventName: string;
  payload?: string;
};

export type SuperAppDataMap = Record<string, string>;
