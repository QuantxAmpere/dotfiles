-- Matches the system XKB layout set in nixos-config modules/features/keyboard.nix.
hl.config({
    input = {
        kb_layout = 'us-umlauts',
        kb_options = 'caps:escape',
    },
})
