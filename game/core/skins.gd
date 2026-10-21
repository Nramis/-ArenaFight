class_name Skins
extends RefCounted

const IDS := {
    "rafael": ["default", "neon_champion"],
    "nikita": ["default", "water_shinobi"],
    "vladislav": ["default", "paquito", "luchador"],
    "mavrin": ["default", "disco_coach"],
    "ramis": ["default", "solar_knight"],
    "ilgiz": ["default", "forest_ranger"],
    "bigboss": ["default", "cheese_baron"],
    "azat": ["default", "catboy"],
    "polina": ["default", "storm_witch"],
    "yusup": ["default", "polar_penguin"],
    "rinat": ["default", "scorpion", "ice_ninja"]
}
const NAMES := {
    "default": "Обычный", "scorpion": "Скорпион", "paquito": "Пакито",
    "neon_champion": "Неоновый чемпион", "water_shinobi": "Водный шиноби",
    "luchador": "Лучадор на массе", "disco_coach": "Диско-тренер",
    "solar_knight": "Солнечный рыцарь", "forest_ranger": "Лесной рейнджер",
    "cheese_baron": "Сырный барон", "catboy": "Котик-нытик",
    "storm_witch": "Ведьма грозы", "polar_penguin": "Полярный пингвин",
    "ice_ninja": "Ледяной ниндзя"
}

static func options(fighter_id: String) -> Array:
    return IDS.get(fighter_id, ["default"])

static func valid(fighter_id: String, skin: String) -> String:
    return skin if skin in options(fighter_id) else "default"
