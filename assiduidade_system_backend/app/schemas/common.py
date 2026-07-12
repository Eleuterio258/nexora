from enum import Enum


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


class TemplateStatus(str, Enum):
    ACTIVE = "ACTIVE"
    REVOKED = "REVOKED"
    DELETED = "DELETED"
