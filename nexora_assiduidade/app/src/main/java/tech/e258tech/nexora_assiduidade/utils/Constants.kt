package tech.e258tech.nexora_assiduidade.utils

object Constants {

    const val PREFS_NAME = "assiduidade_prefs"
    const val PREFS_NAME_ENCRYPTED = "assiduidade_prefs_encrypted"
    const val KEY_USER_TOKEN = "user_token"
    const val KEY_REFRESH_TOKEN = "refresh_token"
    const val KEY_USER_ID = "user_id"
    const val KEY_USER_NAME = "user_name"
    const val KEY_USER_EMAIL = "user_email"
    const val KEY_USER_ROLE = "user_role"
    const val KEY_IS_LOGGED_IN = "is_logged_in"
    const val KEY_DEVICE_ID = "device_id"
    const val KEY_MIGRATED_FROM_LEGACY = "migrated_from_legacy"
    const val KEY_EMPLOYEE_CODE = "employee_code"
    const val KEY_MODULOS_JSON = "modulos_json"

    const val ROLE_FUNCIONARIO = "COLABORADOR"
    const val ROLE_GESTOR = "GESTOR_RH"

    const val EVENT_ENTRY = "ENTRY"
    const val EVENT_EXIT = "EXIT"
    /** O ERP decide entrada/saída sozinho, comparando com o que já existe em
     * rh.presencas para o dia (ver processor.go, registarPresenca — INSERT
     * define hora_entrada, ON CONFLICT preenche hora_saida). Usado quando não
     * faz sentido a app escolher, ex.: registo manual do gestor. */
    const val EVENT_AUTO = "AUTO"
    const val SOURCE_MANUAL = "MANUAL"
    const val SOURCE_PIN = "PIN"
    const val SOURCE_FINGERPRINT = "FINGERPRINT"
    const val SOURCE_FACIAL = "FACIAL"
    const val SOURCE_SELFIE_GPS = "SELFIE_GPS"
    const val SOURCE_QR_CODE = "QR_CODE"
    const val SOURCE_NFC = "NFC"
    const val SOURCE_GEOLOCATION = "GEOLOCATION"

    const val REQUEST_CAMERA = 100
    const val REQUEST_LOCATION = 101
    const val REQUEST_GALLERY = 102
    const val REQUEST_NFC = 103

    const val CONNECT_TIMEOUT = 30L
    const val READ_TIMEOUT = 30L
    const val LOCATION_TIMEOUT = 10000L
    const val LOCATION_MIN_DISTANCE = 10f

    const val DEMO_FUNCIONARIO_EMAIL = "olimpia.chitlhango@e258tech.tech"
    const val DEMO_FUNCIONARIO_PASSWORD = "1234567890"
    const val DEMO_GESTOR_EMAIL = "penina.tembe@e258tech.tech"
    const val DEMO_GESTOR_PASSWORD = "1234567890"


    // WebSocket chat events (backend ERP /ws/chat)
    const val WS_CHAT_PATH = "/ws/chat"
    const val WS_EVENT_MESSAGE = "message"
    const val WS_EVENT_MESSAGE_ACK = "message_ack"
    const val WS_EVENT_TYPING = "typing"
    const val WS_EVENT_STOP_TYPING = "stop_typing"
    const val WS_EVENT_JOINED = "joined"
    const val WS_EVENT_USER_ONLINE = "user_online"
    const val WS_EVENT_USER_OFFLINE = "user_offline"
    const val WS_EVENT_ERROR = "error"
    const val WS_EVENT_NOTIFICATION_COUNT = "notification_count"

    const val WS_ACTION_JOIN = "join"
    const val WS_ACTION_LEAVE = "leave"
    const val WS_ACTION_MESSAGE = "message"
    const val WS_ACTION_TYPING = "typing"
    const val WS_ACTION_STOP_TYPING = "stop_typing"
    const val WS_ACTION_MARK_READ = "mark_read"
    const val WS_ACTION_MARK_ALL_READ = "mark_all_read"

    const val CHAT_TYPE_PRIVATE = "individual"
    const val CHAT_TYPE_GROUP = "grupo"
}
