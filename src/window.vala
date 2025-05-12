/* window.vala
 *
 * Copyright 2025 Jose Hunter
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

[GtkTemplate (ui = "/io/github/halfmexican/kagi/gtk/window.ui")]
public class KagiApp.Window : Adw.ApplicationWindow {
    [GtkChild] private unowned Gtk.ListBox file_list;
    [GtkChild] private unowned Gtk.Button open_dir_btn;
    [GtkChild] private unowned Gtk.Box main_box;

    private WebKit.WebView web_view;
    private File ? current_dir = null;
    private FileMonitor ? dir_monitor = null;

    public Window (Gtk.Application app) {
        Object (application : app);
        web_view = new WebKit.WebView () {
            hexpand = true,
            vexpand = true,
        };
        var settings = new WebKit.Settings () {
            allow_file_access_from_file_urls = true,
        };
        web_view.set_settings (settings);
        main_box.append (web_view);

        // Connect signals
        open_dir_btn.clicked.connect (on_open_directory_clicked);
        file_list.row_activated.connect (on_file_activated);
    }

    private async void on_open_directory_clicked () {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title ("Select a directory");
        dialog.set_modal (true);

        try {
            var file = yield dialog.select_folder (this, null);

            print ("User selected folder: %s\n", file != null ? file.get_uri () : "NULL");
            if (file != null) {
                set_directory (file);
            }
        } catch (Error e) {
            print ("Error selecting folder: %s\n", e.message);
        }
    }

    private void set_directory (File ? dir) {
        print ("Setting directory: %s\n", dir != null ? dir.get_uri () : "NULL");
        if (dir_monitor != null) {
            dir_monitor.cancel ();
            dir_monitor = null;
        }
        current_dir = dir;
        refresh_file_list ();

        if (dir != null) {
            try {
                // Not sure if this works with sandboxing
                dir_monitor = dir.monitor (FileMonitorFlags.WATCH_MOVES, null);
                dir_monitor.changed.connect ((child, other_file, event) => {
                    print ("Directory event: %s\n", event.to_string ());
                    refresh_file_list ();
                });
            } catch (Error e) {
                print ("Error : %s\n", e.message);
            }
        }
    }

    private void refresh_file_list () {
        print ("Refreshing list for: %s\n", current_dir != null ? current_dir.get_uri () : "NULL");
        while (file_list.get_first_child () != null) {
            file_list.remove (file_list.get_first_child ());
        }

        if (current_dir == null)
            return;

        try {
            var enumerator = current_dir.enumerate_children (FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE, null);
            FileInfo ? info;
            while ((info = enumerator.next_file (null)) != null) {
                var name = info.get_name ();
                print ("Found file: %s\n", name);
                var row = new Gtk.ListBoxRow ();
                var label = new Gtk.Label (name) {
                    ellipsize = Pango.EllipsizeMode.END,
                };
                // label.set_xalign (0);
                row.set_child (label);
                var file = current_dir.get_child (name);
                row.set_data<File>("file", file);
                file_list.append (row);
            }
        } catch (Error e) {
            print ("Error enumerating files: %s\n", e.message);
        }
    }

    private void on_file_activated (Gtk.ListBoxRow row) {
        if (current_dir == null)
            return;

        var file = row.get_data<File> ("file");
        if (file == null)
            return;

        print ("Activating file: %s\n", file.get_uri ());
        web_view.load_uri (file.get_uri ());
    }
}
