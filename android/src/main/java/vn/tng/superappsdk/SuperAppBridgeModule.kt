package vn.tng.superappsdk

import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.module.annotations.ReactModule

@ReactModule(name = SuperAppBridgeModule.NAME)
class SuperAppBridgeModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

  init {
    SuperAppDataStore.register(reactContext)
  }

  override fun invalidate() {
    SuperAppDataStore.unregister(reactApplicationContext)
    super.invalidate()
  }

  override fun getName(): String = NAME

  override fun getConstants(): Map<String, Any> =
      mapOf("ROLE_KEY" to SuperAppDataStore.ROLE_KEY)

  @ReactMethod
  fun setItem(key: String, value: String, promise: Promise) {
    if (key.isBlank()) {
      promise.reject(ERROR_INVALID_KEY, "key must not be empty")
      return
    }
    SuperAppDataStore.set(key, value)
    promise.resolve(null)
  }

  @ReactMethod
  fun getItem(key: String, promise: Promise) {
    if (key.isBlank()) {
      promise.reject(ERROR_INVALID_KEY, "key must not be empty")
      return
    }
    promise.resolve(SuperAppDataStore.get(key))
  }

  @ReactMethod
  fun removeItem(key: String, promise: Promise) {
    promise.resolve(SuperAppDataStore.remove(key))
  }

  @ReactMethod
  fun getAllItems(promise: Promise) {
    val map = Arguments.createMap()
    SuperAppDataStore.getAll().forEach { (k, v) -> map.putString(k, v) }
    promise.resolve(map)
  }

  @ReactMethod
  fun clear(promise: Promise) {
    SuperAppDataStore.clear()
    promise.resolve(null)
  }

  @ReactMethod
  fun setRole(role: String, promise: Promise) {
    SuperAppDataStore.setRole(role)
    promise.resolve(null)
  }

  @ReactMethod
  fun getRole(promise: Promise) {
    promise.resolve(SuperAppDataStore.getRole())
  }

  @ReactMethod
  fun emitEvent(eventName: String, payloadJson: String?, promise: Promise) {
    if (eventName.isBlank()) {
      promise.reject(ERROR_INVALID_KEY, "eventName must not be empty")
      return
    }
    SuperAppDataStore.emitBridgeEvent(eventName, payloadJson)
    promise.resolve(null)
  }

  /** Required for NativeEventEmitter on older RN; events are pushed from [SuperAppDataStore]. */
  @ReactMethod
  fun addListener(eventName: String) {
    // Stub for RN EventEmitter contract
  }

  @ReactMethod
  fun removeListeners(count: Int) {
    // Stub for RN EventEmitter contract
  }

  companion object {
    const val NAME = "SuperAppBridge"
    private const val ERROR_INVALID_KEY = "INVALID_KEY"
  }
}
