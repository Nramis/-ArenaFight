export const skinNames = Object.freeze({
    default:'Обычный',scorpion:'Скорпион',paquito:'Пакито',
    neon_champion:'Неоновый чемпион',water_shinobi:'Водный шиноби',
    luchador:'Лучадор на массе',disco_coach:'Диско-тренер',
    solar_knight:'Солнечный рыцарь',forest_ranger:'Лесной рейнджер',
    cheese_baron:'Сырный барон',catboy:'Котик-нытик',
    storm_witch:'Ведьма грозы',polar_penguin:'Полярный пингвин',ice_ninja:'Ледяной ниндзя'
});
const extraSkins = Object.freeze({
    rafael:'neon_champion',nikita:'water_shinobi',vladislav:'luchador',mavrin:'disco_coach',
    ramis:'solar_knight',ilgiz:'forest_ranger',bigboss:'cheese_baron',azat:'catboy',
    polina:'storm_witch',yusup:'polar_penguin',rinat:'ice_ninja'
});
export function skinOptions(fighter) {
    const options = fighter === 'rinat' ? ['default','scorpion'] : fighter === 'vladislav' ? ['default','paquito'] : ['default'];
    return Object.hasOwn(extraSkins,fighter) ? [...options,extraSkins[fighter]] : options;
}
export function validSkin(fighter, skin) {
    return skinOptions(fighter).includes(skin) ? skin : 'default';
}
export function portraitUrl(fighter, skin = 'default') {
    return skin === 'scorpion' && fighter === 'rinat' ? 'portraits/rinat-scorpion.png'
        : skin === 'paquito' && fighter === 'vladislav' ? 'portraits/vlad-paquito.png'
        : 'portraits/' + fighter + '.png';
}
