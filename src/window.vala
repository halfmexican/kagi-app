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
    private Gtk.Box main_box;
    private Gtk.ListBox file_list;
    private WebKit.WebView web_view;
    private string? current_dir = null;
    private FileMonitor? dir_monitor = null;

    public Window (Gtk.Application app) {
        Object (application: app);

        // Main horizontal box
        main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        set_content (main_box);

        // Sidebar: vertical box with "Open Directory" button and file list
        var sidebar = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        sidebar.set_margin_top (12);
        sidebar.set_margin_bottom (12);
        sidebar.set_margin_start (12);
        sidebar.set_margin_end (6);
        sidebar.set_valign (Gtk.Align.FILL);
        sidebar.set_hexpand (false);
        main_box.append (sidebar);

        var open_dir_btn = new Gtk.Button.with_label ("Open Directory");
        open_dir_btn.clicked.connect (on_open_directory_clicked);
        sidebar.append (open_dir_btn);

        file_list = new Gtk.ListBox ();
        file_list.set_selection_mode (Gtk.SelectionMode.BROWSE);
        file_list.row_activated.connect (on_file_activated);
        sidebar.append (file_list);

        // Main area: WebView
        web_view = new WebKit.WebView ();
        web_view.set_hexpand (true);
        web_view.set_vexpand (true);
        main_box.append (web_view);
    }

    private async void on_open_directory_clicked () {
        var dialog = new Gtk.FileDialog ();
        dialog.set_title ("Select a directory");
        dialog.set_modal (true);

        try {
            var file = yield dialog.select_folder (this, null);
            if (file != null) {
                set_directory (file.get_path ());
            }
        } catch (Error e) {
            // User cancelled or error
        }
    }

    private void set_directory (string? dir) {
        if (dir_monitor != null) {
            dir_monitor.cancel ();
            dir_monitor = null;
        }
        current_dir = dir;
        refresh_file_list ();

        if (dir != null) {
            var gfile = File.new_for_path (dir);
            try {
                dir_monitor = gfile.monitor (FileMonitorFlags.NONE, null);
                dir_monitor.changed.connect ((child, other_file, event) => {
                    refresh_file_list ();
                });
            } catch (Error e) {
                // ignore
            }
        }
    }

    private void refresh_file_list () {
        // Remove all rows from the list
        while (file_list.get_first_child () != null) {
            file_list.remove (file_list.get_first_child ());
        }

        if (current_dir == null)
            return;

        var dir = File.new_for_path (current_dir);
        try {
            var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, FileQueryInfoFlags.NONE, null);
            FileInfo? info;
            while ((info = enumerator.next_file (null)) != null) {
                var name = info.get_name ();
                var row = new Gtk.ListBoxRow ();
                var label = new Gtk.Label (name);
                label.set_xalign (0);
                row.set_child (label);
                row.set_data<string> ("filename", name);
                file_list.append (row);
            }
        } catch (Error e) {
            // ignore
        }
    }

    private void on_file_activated (Gtk.ListBoxRow row) {
        if (current_dir == null)
            return;

        var filename = row.get_data<string> ("filename");
        if (filename == null)
            return;

        var path = Path.build_filename (current_dir, filename);

        // Only open .html/.htm files
        if (filename.has_suffix (".html") || filename.has_suffix (".htm")) {
            web_view.load_uri (File.new_for_path (path).get_uri ());
        }
    }
}
