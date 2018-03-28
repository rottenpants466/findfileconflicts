/*-
 * Copyright (c) 2018-2018 Artem Anufrij <artem.anufrij@live.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * The Noise authors hereby grant permission for non-GPL compatible
 * GStreamer plugins to be used and distributed together with GStreamer
 * and Noise. This permission is above and beyond the permissions granted
 * by the GPL license by which Noise is covered. If you modify this code
 * you may extend this exception to your version of the code, but you are not
 * obligated to do so. If you do not wish to do so, delete this exception
 * statement from your version.
 *
 * Authored by: Artem Anufrij <artem.anufrij@live.de>
 */

namespace FindFileConflicts {
    public class MainWindow : Gtk.Window {
        Settings settings;
        Services.LibraryManager lb_manager;

        Gtk.HeaderBar headerbar;
        Gtk.Stack content;
        Gtk.Spinner spinner;
        Gtk.MenuButton app_menu;
        Gtk.Button open_dir;

        construct {
            settings = Settings.get_default ();
            settings.notify["use-dark-theme"].connect (
                () => {
                    Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
                    if (settings.use_dark_theme) {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
                    } else {
                        app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
                    }
                });

            lb_manager = Services.LibraryManager.instance;
            lb_manager.scan_started.connect (
                () => {
                    spinner.active = true;
                    open_dir.sensitive = false;
                });

            lb_manager.scan_finished.connect (
                () => {
                    spinner.active = false;
                    open_dir.sensitive = true;
                });
            lb_manager.check_for_conflicts_begin.connect (
                () => {
                    spinner.active = true;
                    open_dir.sensitive = false;
                });
            lb_manager.check_for_conflicts_finished.connect (
                () => {
                    spinner.active = false;
                    open_dir.sensitive = true;
                });
            lb_manager.conflict_found.connect (
                () => {
                    content.visible_child_name = "conflicts";
                });
        }

        public MainWindow () {
            load_settings ();
            build_ui ();
            this.configure_event.connect (
                (event) => {
                    settings.window_width = event.width;
                    settings.window_height = event.height;
                    return false;
                });

            this.delete_event.connect (
                () => {
                    save_settings ();
                    return false;
                });
            Utils.set_custom_css_style (this.get_screen ());
        }

        private void build_ui () {
            headerbar = new Gtk.HeaderBar ();
            headerbar.title = "Find File Conflicts";
            headerbar.show_close_button = true;
            headerbar.get_style_context ().add_class ("default-decoration");
            this.set_titlebar (headerbar);

            open_dir = new Gtk.Button.from_icon_name ("document-open", Gtk.IconSize.LARGE_TOOLBAR);
            open_dir.tooltip_text = _ ("Open Project");
            open_dir.clicked.connect (open_dir_action);
            headerbar.pack_start (open_dir);

            // SETTINGS MENU
            app_menu = new Gtk.MenuButton ();
            app_menu.valign = Gtk.Align.CENTER;
            if (settings.use_dark_theme) {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.LARGE_TOOLBAR));
            } else {
                app_menu.set_image (new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR));
            }

            var settings_menu = new Gtk.Menu ();

            var menu_item_preferences = new Gtk.MenuItem.with_label (_ ("Preferences"));
            menu_item_preferences.activate.connect (
                () => {
                    var preferences = new Dialogs.Preferences (this);
                    preferences.run ();
                });
            settings_menu.append (menu_item_preferences);
            settings_menu.show_all ();

            app_menu.popup = settings_menu;
            headerbar.pack_end (app_menu);

            // SPINNER
            spinner = new Gtk.Spinner ();
            headerbar.pack_end (spinner);

            var welcome = new Widgets.Views.Welcome ();
            welcome.open_dir_clicked.connect (open_dir_action);

            var conflicts = new Widgets.Views.Conflicts ();

            content = new Gtk.Stack ();
            content.add_named (welcome, "welcome");
            content.add_named (conflicts, "conflicts");
            this.add (content);
            this.show_all ();
        }

        private void open_dir_action () {
            var dir = Utils.choose_folder ();
            lb_manager.scan_folder.begin (dir);
        }


        private void load_settings () {
            this.set_default_size (settings.window_width, settings.window_height);

            if (settings.window_x < 0 || settings.window_y < 0 ) {
                this.window_position = Gtk.WindowPosition.CENTER;
            } else {
                this.move (settings.window_x, settings.window_y);
            }

            Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = settings.use_dark_theme;
        }

        private void save_settings () {
            int x, y;
            this.get_position (out x, out y);
            settings.window_x = x;
            settings.window_y = y;
        }
    }
}
