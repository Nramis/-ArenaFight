class_name Skins
extends RefCounted

const IDS := {"rinat": ["default", "scorpion"], "vladislav": ["default", "paquito"]}
const NAMES := {"default": "Обычный", "scorpion": "Скорпион", "paquito": "Пакито"}

static func options(fighter_id: String) -> Array:
    return IDS.get(fighter_id, ["default"])

static func valid(fighter_id: String, skin: String) -> String:
    return skin if skin in options(fighter_id) else "default"
