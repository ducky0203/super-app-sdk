# super-app-sdk

Thư viện chia sẻ **dữ liệu** và **sự kiện** giữa **host app** (super app shell) và **mini app** chạy nhúng cùng process — mỗi bên một React Native runtime.

Package đã bundle sẵn **JS + native module `SuperAppBridge`** (Android Kotlin + iOS Obj-C). Host shell chỉ cần cài SDK, React Native autolinking sẽ tự đăng ký native module — không phải copy file `.kt` / `.mm` thủ công.

> Mini app chỉ cần import phần JS để gọi API. Bundle mini app **không** bao gồm native vì nó chạy trong cùng process với host đã đăng ký bridge.

---

## Mục lục

- [Khái niệm cơ bản](#khái-niệm-cơ-bản)
- [Cài đặt](#cài-đặt)
- [Khởi động nhanh](#khởi-động-nhanh)
  - [Phía Host](#phía-host)
  - [Phía Mini app](#phía-mini-app)
- [API tham chiếu](#api-tham-chiếu)
  - [Khởi tạo & kiểm tra](#khởi-tạo--kiểm-tra)
  - [Lưu trữ key/value](#lưu-trữ-keyvalue)
  - [Quản lý role](#quản-lý-role)
  - [Vòng đời mini app](#vòng-đời-mini-app)
  - [Sự kiện](#sự-kiện)
- [Native module](#native-module)
- [Build (tuỳ chọn)](#build-tuỳ-chọn)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Khái niệm cơ bản

- **Host app**: app vỏ (shell) chứa native module `SuperAppBridge` và load mini app bundle.
- **Mini app**: bundle JS chạy trong cùng process của host, đọc/ghi cùng một kho dữ liệu in-memory với host.
- **Bridge**: native module Android + iOS lưu data dạng `Map<String, String>` in-memory và phát event tới mọi React runtime đang attach.
- **Role**: mỗi side khai báo mình là `'host'` hoặc `'mini'` để side còn lại biết context.

Mọi giá trị lưu qua `set()` được **JSON.stringify** trước khi đẩy xuống native, và `JSON.parse` ở chiều ngược lại — nên bạn có thể truyền object lồng nhau thoải mái.

---

## Cài đặt

### 1. Thêm dependency

SDK đang dùng nội bộ (private), trỏ qua **local path** hoặc git URL:

```bash
# Trong root project tiêu thụ (host hoặc mini app)
yarn add file:../super-app-sdk
# hoặc
npm install file:../super-app-sdk
```

`package.json` sau khi cài:

```json
{
  "dependencies": {
    "super-app-sdk": "file:../super-app-sdk"
  }
}
```

### 2. Peer dependencies

| Package | Phiên bản tối thiểu |
| --- | --- |
| `react` | `>= 18.0.0` |
| `react-native` | `>= 0.71.0` |

### 3. Link native (chỉ host shell)

Sau khi cài, chạy lại pod install / build lại Android để autolinking pick up native module:

```bash
# iOS
cd ios && pod install && cd ..

# Android: chỉ cần rebuild
yarn android
```

> Không cần chỉnh `MainApplication.kt` hay `AppDelegate.mm` — `SuperAppBridgePackage` (Android) và `SuperAppBridge` module (iOS) được autolink dựa trên `react-native.config.js` và `super-app-sdk.podspec` trong package.

### 4. Mini app

Mini app bundle **chỉ cần** thêm `super-app-sdk` vào `dependencies` rồi `import` — không cần pod install / gradle sync vì native đã có sẵn trong host.

---

## Khởi động nhanh

### Phía Host

```ts
import SuperAppSDK from 'super-app-sdk';

async function openMiniApp() {
  // 1. (Tuỳ chọn) kiểm tra bridge có sẵn
  if (!SuperAppSDK.isAvailable()) {
    console.warn('SuperAppBridge chưa được link!');
    return;
  }

  // 2. Đánh dấu role + đẩy data cho mini đọc
  await SuperAppSDK.prepareMiniLaunch({
    user: {id: 'u1', name: 'Office Host', token: 'jwt...'},
    theme: 'dark',
    locale: 'vi-VN',
  });

  // 3. Lắng nghe khi mini đóng
  const sub = SuperAppSDK.onMiniAppClosed(({moduleName}) => {
    console.log('Mini đã đóng:', moduleName);
    sub.remove();
    SuperAppSDK.onMiniClosed(); // reset role về 'host'
  });

  // 4. Mở mini app bundle (cách mở tuỳ project — vd react-native-navigation, Activity, …)
}

// Lắng nghe event mini gửi lên
SuperAppSDK.onEvent(({eventName, payload}) => {
  if (eventName === 'payment.done') {
    const data = payload ? JSON.parse(payload) : null;
    console.log('Mini báo thanh toán xong:', data);
  }
});
```

### Phía Mini app

```ts
import SuperAppSDK from 'super-app-sdk';

async function bootstrap() {
  const role = await SuperAppSDK.getRole();        // → 'mini'
  const user = await SuperAppSDK.get<{
    id: string;
    name: string;
    token: string;
  }>('user');

  console.log(`[mini] role=${role}, user=`, user);
}

// Lắng nghe data host cập nhật runtime
const dataSub = SuperAppSDK.onDataChanged(({key, value}) => {
  console.log(`[mini] data thay đổi: ${key} =`, value);
});

// Phát event ngược về host
await SuperAppSDK.emitEvent('payment.done', {orderId: 'o1', amount: 50_000});

// Đừng quên dọn dẹp khi unmount
// dataSub.remove();
```

---

## API tham chiếu

Tất cả method bất đồng bộ trả về `Promise`. Import như sau:

```ts
import SuperAppSDK from 'super-app-sdk';
// hoặc named:
import {SuperAppSDK, MINI_APP_CLOSED_EVENT} from 'super-app-sdk';
```

### Khởi tạo & kiểm tra

| Method | Mô tả |
| --- | --- |
| `isAvailable(): boolean` | `true` nếu native module đã link (đang chạy trong host shell). Dùng để guard trước khi gọi các API khác. |
| `ROLE_KEY: string` | Hằng key dùng để lưu role trong store, expose để debug. |

### Lưu trữ key/value

| Method | Mô tả |
| --- | --- |
| `set<T>(key: string, value: T): Promise<void>` | Ghi giá trị. Object/array sẽ được `JSON.stringify`; string ghi nguyên. |
| `get<T>(key: string): Promise<T \| null>` | Đọc và `JSON.parse`. Nếu parse fail trả về raw string. Key không tồn tại → `null`. |
| `remove(key: string): Promise<boolean>` | Xoá 1 key. Trả về `true` nếu key tồn tại. |
| `getAll(): Promise<Record<string, string>>` | Lấy toàn bộ store dạng map raw string. |
| `clear(): Promise<void>` | Xoá tất cả data. |

### Quản lý role

| Method | Mô tả |
| --- | --- |
| `setRole(role: 'host' \| 'mini'): Promise<void>` | Ghi role hiện tại. |
| `getRole(): Promise<'host' \| 'mini' \| null>` | Đọc role. |
| `isHost(): Promise<boolean>` | Helper, tương đương `(await getRole()) === 'host'`. |
| `isMini(): Promise<boolean>` | Helper, tương đương `(await getRole()) === 'mini'`. |

### Vòng đời mini app

| Method | Mô tả |
| --- | --- |
| `prepareMiniLaunch(data: Record<string, unknown>): Promise<void>` | Host gọi **trước khi** mở mini: `setRole('mini')` + bulk `set` toàn bộ entries trong `data`. |
| `onMiniClosed(): Promise<void>` | Host gọi **sau khi** mini đóng: `setRole('host')`. (Không phải listener — đây là setter.) |
| `emitMiniAppClosed(moduleName?: string): Promise<void>` | Phát event `miniapp.closed` (thường được gọi từ native, có thể gọi từ JS để test). |
| `onMiniAppClosed(cb): EmitterSubscription` | Host subscribe khi mini đóng. Trả về subscription, nhớ `.remove()`. |

### Sự kiện

| Method | Mô tả |
| --- | --- |
| `onDataChanged(cb: ({key, value}) => void): EmitterSubscription` | Lắng nghe khi data thay đổi (cả 2 side). |
| `onEvent(cb: ({eventName, payload}) => void): EmitterSubscription` | Lắng nghe event cross-runtime. `payload` là JSON string (hoặc `null`). |
| `emitEvent(name: string, payload?: unknown): Promise<void>` | Phát event cross-runtime. `payload` được `JSON.stringify`. |

**Lưu ý dọn dẹp**: mọi `on*` đều trả `EmitterSubscription` — gọi `.remove()` khi component unmount để tránh leak:

```ts
useEffect(() => {
  const sub = SuperAppSDK.onEvent(handler);
  return () => sub.remove();
}, []);
```

---

## Native module

SDK đã bundle sẵn native code, autolink tự chạy:

- **Android**: `android/src/main/java/vn/tng/superappsdk/SuperAppBridgePackage.kt` (+ `SuperAppBridgeModule`, `SuperAppDataStore`).
- **iOS**: `ios/SuperAppBridge.mm` + `ios/SuperAppDataStore.{h,m}` — đăng ký qua `super-app-sdk.podspec`.

Host shell **không cần** sửa `MainApplication`, `AppDelegate`, hay khai báo `ReactPackage`. Nếu trước đây bạn đã copy thủ công các file `SuperAppBridge*` / `SuperAppDataStore*` vào project (vd: trong `com.officeapp.superapp` hay `ios/OfficeApp/`), **xoá hết** để tránh trùng native module — React Native sẽ throw `Native module SuperAppBridge tried to override...` nếu còn cả hai.

Mini app bundle chỉ cần import `super-app-sdk` là dùng được — không cần link native riêng vì host đã có.

---

## Build (tuỳ chọn)

Mặc định package export TS source trực tiếp (`src/index.ts`) — Metro / `babel-plugin-module-resolver` xử lý ngon.

Nếu muốn build ra JS thuần (vd publish npm registry):

```bash
yarn install
yarn build      # output: lib/
```

Type check không emit:

```bash
yarn typecheck
```

---

## Cấu trúc thư mục

```
super-app-sdk/
├── src/                            # JS / TS
│   ├── index.ts                    # API chính (SuperAppSDK)
│   ├── native.ts                   # Wrapper NativeModules.SuperAppBridge
│   ├── types.ts                    # Type definitions
│   └── examples/miniAppUsage.ts
├── android/                        # Native Android (autolink)
│   ├── build.gradle
│   └── src/main/java/vn/tng/superappsdk/
│       ├── SuperAppBridgeModule.kt
│       ├── SuperAppBridgePackage.kt
│       └── SuperAppDataStore.kt
├── ios/                            # Native iOS (autolink qua podspec)
│   ├── SuperAppBridge.mm
│   ├── SuperAppDataStore.h
│   └── SuperAppDataStore.m
├── super-app-sdk.podspec           # Pod cho iOS
└── react-native.config.js          # Hint cho RN autolink
```

---

## Troubleshooting

### `SuperAppBridge native module is not linked on ios|android`

Bridge chưa autolink xong. Checklist:

1. Đã chạy `pod install` (iOS) hoặc rebuild Android sau khi `yarn add`?
2. Mini app bundle có **đang chạy bên trong host shell** không? Nếu chạy standalone (vd `npx react-native run-ios` trên project mini), bridge sẽ không tồn tại.
3. Dùng `SuperAppSDK.isAvailable()` để guard logic trước khi gọi API.

### `Native module SuperAppBridge tried to override existing module of the same name`

Bạn vừa cài SDK mới **vừa** còn giữ file `SuperAppBridge*` copy thủ công trong project host. Xoá bản copy cũ, clean build:

```bash
# Android
cd android && ./gradlew clean && cd ..

# iOS
cd ios && rm -rf Pods build && pod install && cd ..
```

### Event listener không bắn

- Đảm bảo bạn dùng cùng một instance `SuperAppSDK` từ package `super-app-sdk` (không phải copy file).
- `onEvent` chỉ nhận event được phát qua `emitEvent` (cross-runtime). Event nội bộ runtime của bạn không đi qua bridge.
- Nhớ giữ `subscription` (vd lưu trong ref) để không bị GC.

### Data ghi xong nhưng side kia đọc `null`

- Host có gọi `prepareMiniLaunch` / `set` **trước khi** mini app mount không?
- Nếu mini đã mount rồi mới ghi, dùng `onDataChanged` để nghe update thay vì gọi `get` một lần.

---

## FAQ

**Hỏi**: Data có persist sau khi kill app không?

**Đáp**: Không. Store là in-memory (`Map<String, String>` trong native module), reset mỗi lần process tái khởi tạo. Nếu cần persist, host tự đồng bộ vào `AsyncStorage` / `MMKV`.

**Hỏi**: Có thể truyền function / class instance qua bridge không?

**Đáp**: Không. Chỉ truyền được dữ liệu JSON-serializable. Function, `Date`, `Map`, `Set`, … sẽ mất kiểu khi qua `JSON.stringify`.

**Hỏi**: Nhiều mini app chạy song song có dùng cùng store không?

**Đáp**: Có — tất cả runtime cùng process share một native store. Đặt tên key có prefix theo mini (vd `wallet.balance`) để tránh collision.

**Hỏi**: Có hỗ trợ New Architecture (Fabric/TurboModules) không?

**Đáp**: Hiện đang dùng bridge cũ (RCTBridgeModule / ReactPackage). Đã chạy ổn trên RN ≥ 0.71 với cả bridgeless config qua interop layer.
