export const skinNames = Object.freeze({default:'Обычный',scorpion:'Скорпион',paquito:'Пакито'});
export function skinOptions(fighter) {
    return fighter === 'rinat' ? ['default','scorpion'] : fighter === 'vladislav' ? ['default','paquito'] : ['default'];
}
export function validSkin(fighter, skin) {
    return skinOptions(fighter).includes(skin) ? skin : 'default';
}
export function portraitUrl(fighter, skin = 'default') {
    return skin === 'scorpion' && fighter === 'rinat' ? 'portraits/rinat-scorpion.png'
        : skin === 'paquito' && fighter === 'vladislav' ? 'portraits/vlad-paquito.png'
        : 'portraits/' + fighter + '.png';
}
