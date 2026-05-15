show_install_menu() {
  case $(menu "Install" "󰣇  Any\n󰣇  Package\n󰣇  AUR\n  Web App\n  TUI\n  Service\n  Style\n󰵮  Development\n  Editor\n  Terminal\n󱚤  AI\n󰍲  Windows\n  Gaming") in
  *Any*) terminal "$HOME/.local/bin/omarchy-pkg-any-install" ;;
  *Package*) terminal omarchy-pkg-install ;;
  *AUR*) terminal omarchy-pkg-aur-install ;;
  *Web*) present_terminal omarchy-webapp-install ;;
  *TUI*) present_terminal omarchy-tui-install ;;
  *Service*) show_install_service_menu ;;
  *Style*) show_install_style_menu ;;
  *Development*) show_install_development_menu ;;
  *Editor*) show_install_editor_menu ;;
  *Terminal*) show_install_terminal_menu ;;
  *AI*) show_install_ai_menu ;;
  *Windows*) present_terminal "omarchy-windows-vm install" ;;
  *Gaming*) show_install_gaming_menu ;;
  *) show_main_menu ;;
  esac
}
