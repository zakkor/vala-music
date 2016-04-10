using Gtk;
using Gst;

void toggle_playing_button(bool is_playing, Button butt, Image playing, Image paused) {
    if (is_playing) {
        butt.set_image(paused);
    }
    else
        butt.set_image(playing);
}

int main (string[] args) {
    Gst.init (ref args);
    Gtk.init (ref args);
    Gtk.Settings.get_default().gtk_enable_animations = true;

    var hints = Gdk.Geometry();


    var builder = new Builder ();
    /* Getting the glade file */
    builder.add_from_file ("src/ui/hello.ui");
    builder.connect_signals (null);

    /* Get and connect window signals */
    var window = builder.get_object ("window1") as Window;
    window.destroy.connect(Gtk.main_quit);

    /* search */
    var search_bar = builder.get_object("search_bar") as SearchEntry;

    /* play button */
    var pause_image = builder.get_object("pause_image") as Image;
    var play_image = builder.get_object("play_image") as Image;

    var play_button = builder.get_object("play_button") as Button;
    var previous_button = builder.get_object("previous_button") as Button;
    var next_button = builder.get_object("next_button") as Button;
    var volume_button = builder.get_object("volume_button") as VolumeButton;

    /* Init image */
    var album_art_frame = builder.get_object("album_art_frame") as AspectFrame;
    var lossless_album_art = new Image.from_file("res/queen.jpg");

    lossless_album_art.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(400, 400, Gdk.InterpType.BILINEAR);


    var album_art_image = builder.get_object("album_art_image") as Image;
    album_art_image.set_from_pixbuf(lossless_album_art.pixbuf);


    var listbox = builder.get_object("listbox1") as ListBox;


    /* Paned */
    var paned =  builder.get_object("paned1") as Paned;
    int oldW;
    int oldH;
    int oldP;
    oldP = paned.get_position();
    window.get_size(out oldW, out oldH);

    var max_paned_size = 180;


    /* Window resize */
    window.check_resize.connect( () => {
        int new_width;
        int new_height;
        window.get_size(out new_width, out new_height);

        //if (new_width + paned.get_position() >= 700)
        {
           // window.resize(1280, 720);
        }

        if ( (new_width != oldW ||
            new_height != oldH) ) {


                if (new_width != oldW)
                {

                /*
                    album_art_image.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(new_width * 400 / 1280, new_width * 400 / 1280, Gdk.InterpType.BILINEAR);
                        */
                    oldW = new_width;
                    oldH = new_height;
                }
                else if (new_height != oldH)
                {
                /*
                    album_art_image.pixbuf =
                    lossless_album_art.pixbuf.
                        scale_simple(new_height * 400 / 720, new_height * 400 / 720, Gdk.InterpType.BILINEAR);
                        */
                    oldW = new_width;

                    oldH = new_height;
                }




        }


    });

    /* Pane resize */
    paned.notify.connect( (s, p) => {
/*        int maxWidth = 0;
        foreach(Gtk.Widget element in listbox.get_children()) {

        }
        */
        int new_width = paned.get_position();

        hints.min_width = new_width + 600;
        //hints.max_height = 720;
        window.set_geometry_hints(null, hints, Gdk.WindowHints.MIN_SIZE);
        //window.set_geometry_hints(null, hints, Gdk.WindowHints.MAX_SIZE);

        if (new_width < 12 || new_width > max_paned_size)
        {
            paned.set_position(oldP);
        }
        if (new_width > max_paned_size)
        {
            paned.set_position(max_paned_size);
        }
        if (new_width < 12)
        {
            paned.set_position(12);
        }

        else if (oldP != new_width) {
            listbox.foreach ( (row) => {
                var lr = (ListBoxRow) row;
                lr.foreach ( (box) => {
                    box.set_opacity((double) ((new_width + (oldP / 1.5)) * 1.0 / max_paned_size));
                });
            });
            oldP = new_width;
        }
    });

    //var volume = Gst.ElementFactory.make ("volume", "volume=0.1");
    /*
    volume_button.value_changed.connect( () => {
        string v = 0.1.to_string();
        pipeline.add("playbin volume=" + v);
        stderr.printf("VOL");
    });
*/
    var pipeline = Gst.parse_launch("playbin uri=\"file:///home/ed/Music/a.mp3");

    var current_row = -1;
    var current_song = "nope";



    /* dir */
    try {
        var directory = File.new_for_path ("/home/ed/Music");

        if (args.length > 1) {
            directory = File.new_for_commandline_arg (args[1]);
        }

        var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

        FileInfo file_info;
        var my_index = 0;
        while ((file_info = enumerator.next_file ()) != null) {
        //TODO
            var extension_pos = -1;
            for (var i = 0; i < file_info.get_name().length; i++) {
                if (file_info.get_name()[i] == '.')
                    extension_pos = i;
            }
            var extension = new StringBuilder();
            if (extension_pos != -1) {
                for (var i = extension_pos; i < file_info.get_name().length; i++) {
                    extension.append(file_info.get_name()[i].to_string());
                }
            }



            if (extension.str == ".mp3") {
                my_index++;
                var new_box = new Box(Gtk.Orientation.HORIZONTAL, 0);
                new_box.set_visible(true);

                //if (file_info.get_name().length * 9 > 700)
                //    max_paned_size = 700;
                //else
                if (file_info.get_name().length * 7 > max_paned_size)
                    max_paned_size = file_info.get_name().length * 7;

                var new_label = new Label(file_info.get_name());
                new_box.add(new_label);
                new_box.set_child_packing(new_label, false, false, 0, PackType.START);



                var new_play_button = new Button();
                var new_play_image = new Image.from_stock("gtk-media-play", IconSize.BUTTON);
                new_play_image.set_visible(true);


                new_play_button.set_label("");
                new_play_button.set_focus_on_click(false);
                new_play_button.set_image(new_play_image);
                new_play_button.set_relief(ReliefStyle.NONE);
                new_play_button.set_always_show_image(true);
                new_play_button.set_image_position (PositionType.RIGHT);
                new_play_button.set_alignment (1.0f, 0.5f);



                new_box.add(new_play_button);
                new_box.set_child_packing(new_play_button, false, false, 0, PackType.END);

                listbox.add(new_box);

                // add signal
                new_play_button.clicked.connect( () => {
                    current_song = new_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    pipeline.set_state (State.PAUSED);
                    pipeline = Gst.parse_launch(play_string.str);
                    pipeline.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row = my_index;
                    new_label.set_opacity(0.5);
                });

            }
        }

    } catch (Error e) {
        stderr.printf ("Error: %s\n", e.message);
        return 1;
    }

    search_bar.search_changed.connect( () => {
        listbox.set_filter_func( (row) => {
            var show_row = false;
            if (row.get_index() >= 0 &&
                row.get_index() <= 1) {
                    return true;
                }
            row.foreach( (box) => {
                var cont = (Container) box;
                cont.foreach( (child) => {
                    if (child is Gtk.Label) {
                        var my_label = (Label) child;
                        if (my_label.label.down().contains(search_bar.get_text().down()))
                            show_row = true;
                    }
                });
            });

            return show_row;
        });
        listbox.select_row(listbox.get_row_at_index(2));
    });

    /* set paned size to max */
    paned.set_position(max_paned_size);

    listbox.row_activated.connect( (row) => {
        current_row = row.get_index();
        row.foreach ( (box) => {
            Container con = (Container) box;

            var opaq = 0.5;

            con.foreach( (kid) => {
                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Button)
                    stdout.printf("Is a Button.\n");
                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    pipeline.set_state (State.PAUSED);

                    play_button.set_image(pause_image);
                    pipeline = Gst.parse_launch(play_string.str);

                    pipeline.set_state(State.PLAYING);
                }
            });
        });
    });

    /* placeholder pipeline */


    play_button.clicked.connect( () => {

        Gst.State state, pending;
        Gst.ClockTime timeout = 6000;
        pipeline.get_state(out state, out pending, timeout);
        if (state == State.PLAYING) {
            pipeline.set_state (State.PAUSED);
            //toggle_playing_button(true, play_button, play_image, pause_image);
            play_button.set_image(play_image);
        }
        else {
            pipeline.set_state (State.PLAYING);
            play_button.set_image(pause_image);
            //toggle_playing_button(false, play_button, play_image, pause_image);
        }
    });

    previous_button.clicked.connect( () => {
        pipeline.set_state (State.PAUSED);
        var row = listbox.get_row_at_index(current_row - 1);
        listbox.select_row(row);
        row.foreach ( (box) => {
            Container con = (Container) box;
            var opaq = 0.5;
            con.foreach( (kid) => {

                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Button)
                    stdout.printf("Is a Button.\n");
                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    pipeline.set_state (State.PAUSED);
                    pipeline = Gst.parse_launch(play_string.str);
                    pipeline.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row--;
                }
            });
        });
    });

    next_button.clicked.connect( () => {
        pipeline.set_state (State.PAUSED);
        pipeline.set_state (State.PAUSED);
        var row = listbox.get_row_at_index(current_row + 1);
        listbox.select_row(row);
        row.foreach ( (box) => {
            Container con = (Container) box;
            var opaq = 0.5;
            con.foreach( (kid) => {

                kid.set_opacity(opaq);
                opaq+= 0.5;

                if (kid is Gtk.Button)
                    stdout.printf("Is a Button.\n");
                if (kid is Gtk.Label) {
                    var this_label = (Label) kid;
                    current_song = this_label.label;
                    var play_string = new StringBuilder();
                    play_string.append("playbin uri=\"file:///home/ed/Music/");
                    play_string.append(current_song);
                    play_string.append("\"");
                    pipeline.set_state (State.PAUSED);
                    pipeline = Gst.parse_launch(play_string.str);
                    pipeline.set_state(State.PLAYING);
                    play_button.set_image(pause_image);
                    current_row++;
                }
            });
        });
    });

    search_bar.activate.connect( () => {
        listbox.row_activated(listbox.get_selected_row());
        search_bar.set_text("");
        search_bar.move_focus(Gtk.DirectionType.DOWN);
        paned.set_position(0);
    });

    window.key_press_event.connect ( (event) => {
        if (!search_bar.has_focus) {
            if (event.type == Gdk.EventType.KEY_PRESS) {
                if (event.keyval >= 'a' && event.keyval <= 'z')
                    paned.set_position(max_paned_size);
                    search_bar.grab_focus();
            }
        }
        return false;
    });


    window.show_all ();
    Gtk.main ();
    return 0;
}
