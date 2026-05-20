package vn.tng.superappsdk

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.modules.core.DeviceEventManagerModule
import java.lang.ref.WeakReference
import java.util.concurrent.ConcurrentHashMap

/**
 * In-memory store shared between host ReactHost and mini app ReactHost (same process).
 */
object SuperAppDataStore {
  const val ROLE_KEY = "__super_app_role__"
  const val EVENT_DATA_CHANGED = "SuperAppDataChanged"
  const val EVENT_BRIDGE = "SuperAppEvent"

  /** Tên event mà SDK phát khi mini app đóng — JS lắng nghe qua `SuperAppSDK.onMiniAppClosed`. */
  const val EVENT_NAME_MINI_APP_CLOSED = "miniapp.closed"

  private val data = ConcurrentHashMap<String, String>()
  private val contexts = ConcurrentHashMap.newKeySet<WeakReference<ReactApplicationContext>>()

  fun register(context: ReactApplicationContext) {
    contexts.add(WeakReference(context))
  }

  fun unregister(context: ReactApplicationContext) {
    contexts.removeIf { it.get() == null || it.get() == context }
  }

  fun set(key: String, value: String) {
    data[key] = value
    emitDataChanged(key, value)
  }

  fun get(key: String): String? = data[key]

  fun remove(key: String): Boolean {
    val removed = data.remove(key) != null
    if (removed) {
      emitDataChanged(key, null)
    }
    return removed
  }

  fun getAll(): Map<String, String> = HashMap(data)

  fun clear() {
    data.clear()
    emitDataChanged(null, null)
  }

  fun setRole(role: String) {
    set(ROLE_KEY, role)
  }

  fun getRole(): String? = get(ROLE_KEY)

  fun mergeJsonMap(jsonMap: Map<String, String>) {
    jsonMap.forEach { (k, v) -> data[k] = v }
    emitDataChanged(null, null)
  }

  fun emitBridgeEvent(eventName: String, payloadJson: String?) {
    val params =
        Arguments.createMap().apply {
          putString("eventName", eventName)
          if (payloadJson != null) {
            putString("payload", payloadJson)
          }
        }
    emitToAll(EVENT_BRIDGE, params)
  }

  /**
   * Host shell gọi khi mini app đóng. Phát [EVENT_NAME_MINI_APP_CLOSED] tới mọi React context
   * còn sống (thường là host JS), payload `{"moduleName":"..."}`.
   */
  @JvmStatic
  @JvmOverloads
  fun notifyMiniAppClosed(moduleName: String? = null) {
    val payload = moduleName?.let { "{\"moduleName\":${jsonString(it)}}" }
    emitBridgeEvent(EVENT_NAME_MINI_APP_CLOSED, payload)
  }

  private fun jsonString(value: String): String {
    val escaped =
        value
            .replace("\\", "\\\\")
            .replace("\"", "\\\"")
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
    return "\"$escaped\""
  }

  private fun emitDataChanged(key: String?, value: String?) {
    val params =
        Arguments.createMap().apply {
          if (key != null) {
            putString("key", key)
          }
          if (value != null) {
            putString("value", value)
          }
        }
    emitToAll(EVENT_DATA_CHANGED, params)
  }

  private fun emitToAll(eventName: String, params: WritableMap?) {
    val dead = mutableListOf<WeakReference<ReactApplicationContext>>()
    for (ref in contexts) {
      val ctx = ref.get()
      if (ctx == null) {
        dead.add(ref)
        continue
      }
      if (!ctx.hasActiveReactInstance()) {
        continue
      }
      try {
        ctx.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            ?.emit(eventName, params)
      } catch (_: Exception) {
        // Instance destroyed
      }
    }
    contexts.removeAll(dead.toSet())
  }
}
