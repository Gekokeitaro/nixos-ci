{lib}: let
  # Helper para acortar la asignación de keymaps
  keymap = mode: key: action: desc: {
    inherit mode key action desc;
    silent = true;
  };
in {
  keymaps = [
    (keymap "n" "<left>" "<cmd> echo 'Use h to move!!'<CR>" "")
    (keymap "n" "<right>" "<cmd> echo 'Use l to move!!'<CR>" "")
    (keymap "n" "<up>" "<cmd> echo 'Use k to move!!'<CR>" "")
    (keymap "n" "<down>" "<cmd> echo 'Use j to move!!'<CR>" "")
    (keymap "n" "<C-h>" "<C-w><C-h>" "Move focus to the left window")
    (keymap "n" "<C-l>" "<C-w><C-l>" "Move focus to the right window")
    (keymap "n" "<C-k>" "<C-w><C-k>" "Move focus to the up window")
    (keymap "n" "<C-j>" "<C-w><C-j>" "Move focus to the down window")
  ];
}
