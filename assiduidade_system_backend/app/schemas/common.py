from enum import Enum


class UserRole(str, Enum):
    COLABORADOR = "COLABORADOR"
    GESTOR_RH = "GESTOR_RH"
    ADMIN_SISTEMA = "ADMIN_SISTEMA"
    AUDITOR = "AUDITOR"


class UserStatus(str, Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    TERMINATED = "TERMINATED"


class DeviceType(str, Enum):
    WEB = "WEB"
    MOBILE = "MOBILE"
    TOTEM = "TOTEM"
    KIOSK = "KIOSK"
    API = "API"


class DeviceStatus(str, Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
    BLOCKED = "BLOCKED"


class EventType(str, Enum):
    ENTRY = "ENTRY"
    BREAK_START = "BREAK_START"
    BREAK_END = "BREAK_END"
    EXIT = "EXIT"


class SourceType(str, Enum):
    ONLINE = "ONLINE"
    OFFLINE_SYNC = "OFFLINE_SYNC"
    MANUAL = "MANUAL"
    PIN = "PIN"
    INTEGRATION = "INTEGRATION"
    FINGERPRINT = "FINGERPRINT"
    FACIAL = "FACIAL"
    SELFIE_GPS = "SELFIE_GPS"
    QR_CODE = "QR_CODE"
    NFC = "NFC"
    GEOLOCATION = "GEOLOCATION"


class SyncStatus(str, Enum):
    SYNCED = "SYNCED"
    PENDING = "PENDING"
    FAILED = "FAILED"


class AdjustmentStatus(str, Enum):
    PENDING = "PENDING"
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"


class TemplateStatus(str, Enum):
    ACTIVE = "ACTIVE"
    REVOKED = "REVOKED"
    DELETED = "DELETED"


class LegalBasisType(str, Enum):
    CONSENT = "CONSENT"
    LEGAL_OBLIGATION = "LEGAL_OBLIGATION"
    LEGITIMATE_INTEREST = "LEGITIMATE_INTEREST"
