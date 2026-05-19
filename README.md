# super-app-sdk

Thư viện chia sẻ dữ liệu / sự kiện giữa **host app** (super app shell) và **mini app** chạy nhúng cùng process, mỗi bên một React Native runtime.

Library bundle sẵn **JS + native module `SuperAppBridge`** (Android Kotlin + iOS Obj-C). Host shell chỉ cần cài SDK, React Native autolinking sẽ tự đăng ký native module — không phải copy file `.kt` / `.mm` thủ công.

> Mini app chỉ cần import phần JS để gọi API; bundle mini app không cần bao gồm native vì nó chạy trong cùng process với host đã đăng ký bridge.

## Cài đặt

Hiện đang dùng nội bộ (private), trỏ qua local path:

```bash
# Trong root project tiêu thụ (host hoặc mini app)
npm install file:../super-app-sdk
# hoặc
yarn add file:../super-app-sdk
```

`package.json`:

```json
{
  "dependencies": {
    "super-app-sdk": "file:../super-app-sdk"
  }
}
```

Yêu cầu peer:

- `react >= 18.0.0`
- `react-native >= 0.71.0`

Sau khi cài, chạy lại pod install / gradle sync để autolinking pick up native module:

```bash
# iOS
cd ios && pod install && cd ..

# Android: chỉ cần rebuild, không cần thêm bước
yarn android
```

Không cần chỉnh `MainApplication.kt` hay `AppDelegate.mm` — `SuperAppBridgePackage` (Android) và `SuperAppBridge` module (iOS) được autolink dựa trên `react-native.config.js` và `super-app-sdk.podspec` trong package.

## Sử dụng nhanh

```ts
import SuperAppSDK from 'super-app-sdk';

// Host: chuẩn bị data trước khi mở mini app
await SuperAppSDK.prepareMiniLaunch({
  user: {id: 'u1', name: 'Office Host', token: '...'},
});

// Mini app: đọc dữ liệu host đã ghi
const role = await SuperAppSDK.getRole();          // 'host' | 'mini' | null
const user = await SuperAppSDK.get<{id: string}>('user');

// Lắng nghe data thay đổi
const sub = SuperAppSDK.onDataChanged(({key, value}) => {
  console.log(key, value);
});
// ...
sub.remove();

// Phát event tới side còn lại
await SuperAppSDK.emitEvent('payment.done', {orderId: 'o1'});

// Bên kia lắng nghe
SuperAppSDK.onEvent(({eventName, payload}) => {
  console.log(eventName, payload);
});
```

## API

| Method | Mô tả |
| --- | --- |
| `SuperAppSDK.isAvailable()` | `true` nếu native bridge đã link (đang chạy trong host shell). |
| `set(key, value)` | Ghi (object → JSON). |
| `get<T>(key)` | Đọc và parse JSON (fallback raw string). |
| `remove(key)` | Xoá 1 key. |
| `getAll()` | Lấy toàn bộ map dạng `Record<string, string>`. |
| `clear()` | Xoá tất cả data. |
| `setRole(role)` | Đặt role hiện tại (`host` / `mini`). |
| `getRole()` | Đọc role. |
| `isHost()` / `isMini()` | Helper boolean. |
| `prepareMiniLaunch(data)` | Host: setRole('mini') + bulk set. |
| `onMiniClosed()` | Host: trở lại role 'host'. |
| `onDataChanged(cb)` | Subscribe khi data thay đổi. |
| `onEvent(cb)` | Subscribe event từ side còn lại. |
| `emitEvent(name, payload?)` | Phát event cross-runtime. |

## Native module

SDK đã bundle sẵn native code, autolink tự chạy:

- **Android**: `android/src/main/java/vn/tng/superappsdk/SuperAppBridgePackage.kt` (+ `SuperAppBridgeModule`, `SuperAppDataStore`).
- **iOS**: `ios/SuperAppBridge.mm` + `ios/SuperAppDataStore.{h,m}` — đăng ký qua `super-app-sdk.podspec`.

Host shell **không cần** sửa `MainApplication`, `AppDelegate`, hay khai báo `ReactPackage`. Nếu trước đây bạn đã copy thủ công các file `SuperAppBridge*` / `SuperAppDataStore*` vào project (vd: trong `com.officeapp.superapp` hay `ios/OfficeApp/`), **xoá hết** để tránh trùng native module — React Native sẽ throw `Native module SuperAppBridge tried to override...` nếu còn cả hai.

Mini app bundle chỉ cần import `super-app-sdk` là dùng được — không cần link native riêng vì host đã có.

## Build (tuỳ chọn)

Mặc định package export TS source trực tiếp (`src/index.ts`) — Metro / `babel-plugin-module-resolver` xử lý ngon.

Nếu muốn build ra JS thuần:

```bash
npm install
npm run build      # output: lib/
```

## Cấu trúc

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
