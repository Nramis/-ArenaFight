class_name Roster
extends RefCounted

const IDS = ["rafael", "nikita", "vladislav", "mavrin", "ramis", "ilgiz", "bigboss", "azat", "polina", "yusup"]
const NAMES = {"rafael":"РАФАЭЛЬ", "nikita":"НИКИТА", "vladislav":"ВЛАДИСЛАВ", "mavrin":"МАВРИН", "ramis":"РАМИС", "ilgiz":"ИЛЬГИЗ", "bigboss":"РАФАЭЛЬ БИГ БОСС", "azat":"АЗАТ", "polina":"ПОЛИНА", "yusup":"ЮСУП"}
const COOLDOWNS = {"rafael":[600,720,180], "nikita":[420,660,840], "vladislav":[300,660,600], "mavrin":[360,240,120], "ramis":[600,480,480], "ilgiz":[540,900,720], "bigboss":[180,480,720], "azat":[120,180,240], "polina":[540,720,840], "yusup":[600,720,660]}
static func valid(id: String) -> String:
    return id if id in IDS else "rafael"
