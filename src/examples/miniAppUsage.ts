/**
 * Ví dụ mini app bundle đọc dữ liệu từ host và lắng nghe event.
 *
 * Yêu cầu: bundle này phải chạy bên trong shell host đã đăng ký
 * SuperAppBridge native module (vd: OfficeApp).
 */
import SuperAppSDK from '../index';

export async function readHostUser() {
  const role = await SuperAppSDK.getRole();
  const user = await SuperAppSDK.get<{id: string; name: string; token: string}>(
    'user',
  );
  return {role, user};
}

export function watchHostEvents() {
  return SuperAppSDK.onEvent(({eventName, payload}) => {
    console.log('[SuperAppSDK]', eventName, payload);
  });
}
