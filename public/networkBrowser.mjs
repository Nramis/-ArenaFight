export async function copyInvitation(text) {
    if (globalThis.navigator?.clipboard?.writeText) {
        try {
            await navigator.clipboard.writeText(text);
            return true;
        } catch {
            // Some browsers deny clipboard permission; try copying the selection.
        }
    }

    const previousFocus = document.activeElement;
    const input = document.createElement('textarea');
    input.value = text;
    input.readOnly = true;
    input.style.position = 'fixed';
    input.style.top = '0';
    input.style.left = '0';
    input.style.opacity = '0';
    document.body.append(input);
    try {
        input.focus();
        input.select();
        input.setSelectionRange(0, text.length);
        return document.execCommand('copy');
    } catch {
        return false;
    } finally {
        input.remove();
        previousFocus?.focus();
    }
}
